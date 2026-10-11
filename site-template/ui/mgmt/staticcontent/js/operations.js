// The Operations page: for the person who looks after the appliance. Each section answers one question; the
// judgements are made in system/judge.js and the thresholds are listed at the end of the page.
import { drawTimeSeries } from "../comm/js/aa/chart.js";
import { appliances, get, node, number, pauseResume, settled } from "./system/api.js";
import {
    DROPPED_REPORTS,
    THRESHOLDS,
    TIER_NAMES,
    daysText,
    etlTiers,
    heapFloor,
    judgeEtl,
    judgeStorage,
    judgeWrite,
    measureMap,
    prefixOf,
    groupByHost,
} from "./system/judge.js";
import { chooseAppliance, statusNode, timeText } from "./system/view.js";

const $ = (id) => document.getElementById(id);
const REFRESH_MS = 30000;
const LIST_LIMIT = 200;
const openGroups = new Set();
let list = [];
let current = null;
let latest = null;
let timer = 0;

function fill(tableId, rows) {
    const body = $(tableId).querySelector("tbody");
    body.textContent = "";
    for (const cells of rows) {
        body.append(node("tr", null, ...cells.map((cell, index) => (cell instanceof Node ? node("td", { class: index ? "r num" : null }, cell) : node("td", { class: index ? "r num" : null }, String(cell))))));
    }
    return body;
}

function emptyRow(tableId, columns, text) {
    $(tableId).querySelector("tbody").replaceChildren(node("tr", null, node("td", { colspan: String(columns), class: "empty" }, text)));
}

// ---- samples ---------------------------------------------------------------------------------------

function renderSamples(data) {
    const m = data.measures;
    const show = (name) => (m.has(name) ? String(m.get(name)) : "not reported");
    fill("counts", [
        ["Total PVs", show("Total PV count")],
        ["Connected", show("Connected PV count")],
        ["Disconnected now", show("Disconnected PV count")],
        ["Paused", show("Paused PV count")],
        ["Never connected", data.never ? String(data.never.length) : "not read"],
        ["Channels with pending search requests", show("Channels with pending search requests")],
        ["PVs waiting for their first meta data", show("PVs pending computation of meta info")],
        ["Events per second", show("Event Rate (in events/sec)")],
        ["Data rate in bytes per second", show("Data Rate (in bytes/sec)")],
    ]);
    if (!data.lost) {
        emptyRow("lostConnections", 3, "The report could not be read.");
    } else if (!data.lost.length) {
        emptyRow("lostConnections", 3, "No PV lost its connection.");
    } else {
        fill("lostConnections", data.lost.map((row) => [row.pvName, String(row.lostConnections), String(row.currentlyConnected)]));
    }
    renderHosts(data.disconnected);
}

function renderHosts(rows) {
    const body = $("hosts").querySelector("tbody");
    body.textContent = "";
    if (!rows) {
        $("hostsNote").textContent = "The list could not be read.";
        return;
    }
    const groups = groupByHost(rows);
    $("hostsNote").textContent = rows.length
        ? `${rows.length} PV${rows.length > 1 ? "s are" : " is"} disconnected, in ${groups.length} group${groups.length > 1 ? "s" : ""} of host and time of loss.`
        : "No PV is disconnected.";
    for (const group of groups) {
        const key = `${group.host}|${group.first}`;
        const counts = new Map();
        for (const item of group.items) {
            counts.set(prefixOf(item.pv), (counts.get(prefixOf(item.pv)) || 0) + 1);
        }
        const prefixes = Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
        const top = prefixes[0] ? prefixes[0][0] : "";
        const when = group.first === group.last ? timeText(group.first) : `${timeText(group.first)} to ${timeText(group.last)}`;
        const toggle = node("button", { type: "button", class: "link", "aria-expanded": String(openGroups.has(key)) }, "PVs");
        const pauseThese = node("button", { type: "button", class: "link" }, "Pause these…");
        pauseThese.addEventListener("click", () => confirmPause(group));
        const open = new URLSearchParams({ q: top, report: "disconnected" });
        const row = node(
            "tr",
            null,
            node("td", { class: group.host ? "pv" : "pv warn" }, group.host || "unknown host"),
            node("td", { class: "r num warn" }, String(group.items.length)),
            node("td", { class: "num" }, when),
            node("td", { class: "pv" }, prefixes.slice(0, 3).map(([name, count]) => `${name} (${count})`).join(", ")),
            node("td", null, toggle, " ", node("a", { href: `index.html#${open}` }, "Open in Work"), " ", pauseThese),
        );
        body.append(row);
        const showList = () => {
            const names = group.items.slice().sort((a, b) => (a.pv < b.pv ? -1 : a.pv > b.pv ? 1 : 0));
            const items = node("ul", { class: "pvlist" });
            for (const item of names.slice(0, LIST_LIMIT)) {
                items.append(node("li", null, node("span", { class: "pv" }, item.pv), ` lost ${item.lostText}`));
            }
            if (names.length > LIST_LIMIT) {
                items.append(node("li", { class: "sub" }, `and ${names.length - LIST_LIMIT} more; open the group in the Work page for the whole list.`));
            }
            return node("tr", { class: "detail" }, node("td", { colspan: "5" }, items));
        };
        let detail = null;
        if (openGroups.has(key)) {
            detail = showList();
            row.after(detail);
        }
        toggle.addEventListener("click", () => {
            if (detail) {
                detail.remove();
                detail = null;
                openGroups.delete(key);
            } else {
                detail = showList();
                row.after(detail);
                openGroups.add(key);
            }
            toggle.setAttribute("aria-expanded", String(Boolean(detail)));
        });
    }
}

/** Asks once, then pauses the PVs of a group in one call and says what happened. */
function confirmPause(group) {
    const dialog = $("confirmDialog");
    const names = group.items.map((item) => item.pv);
    const host = group.host || "an unknown host";
    $("confirmTitle").textContent = `Pause ${names.length} PV${names.length === 1 ? "" : "s"}`;
    $("confirmText").textContent = `These PVs lost their connection to ${host}. The archiver stops asking for them and keeps their data. Resume them from the Work page when the IOC is back.`;
    $("confirmError").textContent = "";
    $("confirmForm").onsubmit = async (event) => {
        event.preventDefault();
        const submit = $("confirmSubmit");
        submit.disabled = true;
        try {
            const rows = await pauseResume("../bpl/pauseArchivingPV", names);
            const same = (row) => /already paused/i.test(String(row.validation || ""));
            const done = rows.filter((row) => row.status === "ok").length;
            const already = rows.filter(same).length;
            const failed = rows.filter((row) => row.status !== "ok" && !same(row));
            dialog.close();
            $("hostsResult").textContent = `${done} of ${names.length} PVs paused${already ? `, ${already} already paused` : ""}${failed.length ? `; ${failed.length} failed (first: ${failed[0].pvName}: ${failed[0].validation || failed[0].engine_validation || "no reason given"})` : ""}.`;
            refresh();
        } catch (error) {
            $("confirmError").textContent = error.message;
        } finally {
            submit.disabled = false;
        }
    };
    dialog.showModal();
}

// ---- samples lost ----------------------------------------------------------------------------------

function renderDropped(data) {
    const body = $("droppedTable").querySelector("tbody");
    body.textContent = "";
    DROPPED_REPORTS.forEach((report, index) => {
        const rows = data.dropped[index];
        if (!rows) {
            body.append(node("tr", null, node("td", null, report.label), node("td", { colspan: "4", class: "empty" }, "The report could not be read.")));
            return;
        }
        const worst = rows.slice().sort((a, b) => (number(b.eventsDropped) || 0) - (number(a.eventsDropped) || 0))[0];
        const total = rows.reduce((sum, row) => sum + (number(row.eventsDropped) || 0), 0);
        body.append(
            node(
                "tr",
                null,
                node("td", null, report.label),
                node("td", { class: rows.length ? "r num warn" : "r num" }, String(rows.length)),
                node("td", { class: "pv" }, worst ? worst.pvName : "-"),
                node("td", { class: "r num" }, rows.length ? total.toLocaleString() : "-"),
                node("td", { class: "why" }, rows.length ? report.action : "Nothing to do."),
            ),
        );
    });
}

// ---- write path ------------------------------------------------------------------------------------

function renderWrite(data) {
    const m = data.measures;
    const write = judgeWrite(m);
    const rate = number(m.get("Event Rate (in events/sec)"));
    const benchmark = number(m.get("Benchmark - writing at (events/sec)"));
    const headroom = rate && benchmark ? benchmark / rate : null;
    const show = (name, suffix = "") => (m.has(name) ? `${m.get(name)}${suffix}` : "not reported");
    fill("writeTable", [
        ["Write time as share of the write period", node("span", null, statusNode(write.kind, write.text), write.usage === null ? "" : ` ${write.usage.toFixed(write.usage < 1 ? 2 : 0)} %`)],
        ["Time spent writing sample buffers to the short term store", show("Time consumed for writing samplebuffers to STS (in secs)", " s")],
        ["Jobs waiting in the engine queue", show("Approx pending jobs in engine queue")],
        ["Incoming rate", rate === null ? "not reported" : `${rate.toLocaleString(undefined, { maximumFractionDigits: 1 })} events per s`],
        ["Benchmark write rate", benchmark === null ? "not reported" : `${benchmark.toLocaleString()} events per s`],
        ["Headroom", headroom === null ? "unknown" : `${headroom.toLocaleString(undefined, { maximumFractionDigits: 0 })} times`],
        ["PVs in the archive workflow", show("PVs in archive workflow")],
    ]);
    if (!data.fastest) {
        emptyRow("fastest", 2, "The report could not be read.");
    } else {
        fill("fastest", data.fastest.map((row) => [row.pvName, String(Number(row.eventRate).toFixed(2))]));
    }
}

// ---- stores and ETL --------------------------------------------------------------------------------

function renderStorage(data) {
    const host = $("storage");
    host.textContent = "";
    const bytes = number(data.appliance.dataRate);
    const storage = judgeStorage(data.storage, bytes);
    const rate = storage.perDayGB ? `${(storage.perDayGB * 1000).toFixed(storage.perDayGB < 1 ? 1 : 0)} MB per day` : "an unknown rate";
    $("daysLeft").textContent = data.storage && data.storage.length
        ? storage.kind === "ok"
            ? storage.days === null
                ? "The archiver adds no data at the moment, so the days left cannot be computed."
                : `At ${rate} the space lasts ${daysText(storage.days)}.`
            : `${storage.text} The archiver adds ${rate}.`
        : "";
    if (!data.storage) {
        host.textContent = "The storage report could not be read.";
        return;
    }
    if (!data.storage.length) {
        host.textContent = "The appliance reported no storage devices.";
        return;
    }
    for (const device of data.storage) {
        const total = number(device.total_space);
        const free = number(device.available_space);
        const freePercent = number(device.available_space_percent);
        const used = total !== null && free !== null ? total - free : null;
        const usedPercent = freePercent !== null ? 100 - freePercent : null;
        const low = freePercent !== null && freePercent < THRESHOLDS.freeAttentionPercent;
        const track = node("div", { class: "track", role: "img", "aria-label": usedPercent === null ? "usage unknown" : `${usedPercent.toFixed(0)} percent used` });
        const fillBar = node("div", { class: low ? "fill low" : "fill" });
        fillBar.style.width = `${Math.max(0, Math.min(100, usedPercent === null ? 0 : usedPercent))}%`;
        track.append(fillBar);
        const copy = device.time_copy_data_into_store && device.time_copy_data_into_store !== "NaN" ? `, copy ${device.time_copy_data_into_store} s` : "";
        host.append(
            node(
                "div",
                { class: "bar-row" },
                node("span", { class: "pv" }, device.name),
                track,
                node("span", { class: low ? "num warn" : "num" }, used === null ? "" : `${used.toFixed(1)} of ${total.toFixed(1)} GB used${copy}`),
            ),
        );
    }
}

const ETL_ROWS = [
    "Passes so far",
    "Last pass started at",
    "Last pass duration (s)",
    "Last pass busy time (s)",
    "Last pass busy time as % of cadence",
    "Last pass overran the cadence",
    "Last pass late by (s)",
    "Last pass PVs",
    "Last pass partitions moved",
    "Last pass bytes moved",
    "Last pass jobs failed",
    "Last pass jobs aborted",
    "Last pass jobs skipped",
    "Last pass slowest PV",
    "Last pass slowest PV time (s)",
    "Average busy time per pass (s)",
    "Weekly usage (%)",
    "Current pass",
];

function renderEtl(data) {
    const tiers = etlTiers(data.measures);
    const keys = Object.keys(tiers).sort();
    const table = $("etl");
    table.querySelector("thead").replaceChildren(node("tr", null, node("th", null, "Measure"), ...keys.map((key) => node("th", { class: "r" }, TIER_NAMES[key] || key))));
    const body = table.querySelector("tbody");
    body.textContent = "";
    if (!keys.length) {
        body.append(node("tr", null, node("td", { class: "empty" }, "The appliance reported no ETL measures.")));
    }
    const judged = judgeEtl(tiers);
    if (keys.length) {
        body.append(node("tr", null, node("td", null, "Judgement"), node("td", { colspan: String(keys.length) }, statusNode(judged.kind, judged.text))));
    }
    for (const name of ETL_ROWS) {
        body.append(node("tr", null, node("td", null, name), ...keys.map((key) => node("td", { class: "r num" }, tiers[key][name] === undefined ? "" : String(tiers[key][name])))));
    }
    const m = data.measures;
    const plan = (name, suffix = "") => (m.has(name) ? `${m.get(name)}${suffix}` : "not reported");
    fill("plan", [
        ["Plan last updated", plan("Capacity planning last update")],
        ["Storage rate, whole cluster", plan("Aggregated appliance storage rate (in GB/year)", " GB per year")],
        ["Storage rate, this appliance", plan("Incremental appliance storage rate (in GB/year)", " GB per year")],
        ["Event rate, whole cluster", plan("Aggregated appliance event rate (in events/sec)", " per s")],
        ["Event rate, this appliance", plan("Incremental appliance event rate (in events/sec)", " per s")],
        ["PV count, whole cluster", plan("Aggregated appliance PV count")],
        ["PV count, this appliance", plan("Incremental appliance PV count")],
    ]);
    if (!data.largest) {
        emptyRow("largest", 2, "The report could not be read.");
    } else {
        fill("largest", data.largest.map((row) => [row.pvName, `${row.storageConsumedInMB} MB`]));
    }
}

// ---- processes -------------------------------------------------------------------------------------

function duration(seconds) {
    const total = Math.floor(Number(seconds));
    if (!Number.isFinite(total)) {
        return "";
    }
    const days = Math.floor(total / 86400);
    const hours = Math.floor((total % 86400) / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    return days ? `${days} d ${hours} h` : `${hours} h ${minutes} m`;
}

const COMPONENTS = [
    ["MGMT", "Management", null],
    ["ENGINE", "Engine", "engine_heap (%)"],
    ["ETL", "ETL", "etl_heap (%)"],
    ["RETRIEVAL", "Retrieval", "retrieval_heap (%)"],
];

function seriesByLabel(series, label) {
    const found = (series || []).find((s) => s.label === label);
    return found ? found.data : null;
}

function floorChart(host, title, floor) {
    const points = floor.data.map(([t, v]) => ({ t, v, s: 0 }));
    const lowest = floor.floor.map(([t, v]) => ({ t, v, s: 0 }));
    const section = node("div", { class: "process-chart" }, node("h3", null, title), statusNode(floor.kind, floor.text));
    const chart = node("div", { class: "chart" });
    section.append(chart);
    host.append(section);
    drawTimeSeries(chart, {
        series: [
            { name: "heap", egu: "%", points, focus: false, quiet: true },
            { name: "floor", egu: "%", points: lowest, focus: true },
        ],
        from: new Date(points[0].t),
        to: new Date(points[points.length - 1].t),
        gapMs: 600000,
    });
    const rhythm = floor.rhythm === null ? "" : ` A collection runs about every ${floor.rhythm.toFixed(0)} minutes.`;
    section.append(node("p", { class: "sub" }, `Lowest after a collection: ${floor.first.toFixed(0)} % at the start of the day, ${floor.last.toFixed(0)} % now.${rhythm}`));
}

function renderProcesses(data) {
    const local = !data.servingIdentity || data.servingIdentity === data.appliance.instance;
    const info = (local && data.processInfo) || {};
    const body = $("processTable").querySelector("tbody");
    body.textContent = "";
    const host = $("process");
    host.textContent = "";
    $("processNote").textContent = "";
    const charts = [];
    for (const [key, label, seriesLabel] of COMPONENTS) {
        const metrics = info[`${key}_metrics`];
        const raw = seriesLabel ? seriesByLabel(data.series, seriesLabel) : null;
        // The latest value of the series belongs to the selected appliance, whichever one answered.
        const heapNow = metrics && metrics.length ? number(metrics[metrics.length - 1].heapUsedPercent) : raw && raw.length ? number(raw[raw.length - 1][1]) : null;
        const floor = seriesLabel ? heapFloor(raw) : null;
        body.append(
            node(
                "tr",
                null,
                node("td", null, label),
                node("td", { class: "num" }, info[`${key}_start`] || ""),
                node("td", { class: "r num" }, duration(info[`${key}_uptime`])),
                node("td", { class: "r num" }, heapNow === null ? "" : `${heapNow.toFixed(0)} %`),
                node("td", null, floor ? statusNode(floor.kind, floor.text || `${floor.last.toFixed(0)} %`) : node("span", { class: "why" }, seriesLabel ? "not enough data yet" : "not reported over time")),
            ),
        );
        if (floor) {
            charts.push([`${label} heap`, floor]);
        }
    }
    if (!data.series) {
        $("processNote").textContent = "The process metrics could not be read.";
        return;
    }
    if (!charts.length) {
        $("processNote").textContent = "A trend appears when the appliance has collected two hours of values.";
    }
    if (!local) {
        $("processNote").textContent = `${$("processNote").textContent} Start time and uptime are reported only by the appliance that serves this page (${data.servingIdentity}).`.trim();
    }
    for (const [title, floor] of charts) {
        floorChart(host, title, floor);
    }
    const load = seriesByLabel(data.series, "system_load (%)");
    if (load && load.length > 1) {
        const points = load.map(([t, v]) => ({ t, v: Number(v), s: 0 })).filter((p) => Number.isFinite(p.v));
        const section = node("div", { class: "process-chart" }, node("h3", null, "Load average of the host"));
        const chart = node("div", { class: "chart" });
        section.append(chart);
        host.append(section);
        drawTimeSeries(chart, { series: [{ name: "load", egu: "", points, focus: true }], from: new Date(points[0].t), to: new Date(points[points.length - 1].t), gapMs: 600000, labelNames: false });
        const high = Math.max(...points.map((p) => p.v));
        section.append(
            node("p", { class: "sub" }, `One-minute load average of the host: now ${points[points.length - 1].v.toFixed(1)}, highest ${high.toFixed(1)}. The appliance does not report the number of cores, so no judgement is made; a load above the number of cores means processes wait for a processor.`),
        );
    }
}

// ---- configuration and thresholds ------------------------------------------------------------------

const BASIS = [
    ["Days left, attention / problem", `${THRESHOLDS.daysLeftAttention} / ${THRESHOLDS.daysLeftProblem} days`, "A choice: a store fills slowly, so published alert horizons of hours do not fit."],
    ["Device free share, attention / problem", `${THRESHOLDS.freeAttentionPercent} / ${THRESHOLDS.freeProblemPercent} %`, "Prometheus node_exporter mixin, almost out of space."],
    ["Write time, attention / problem", `${THRESHOLDS.writeAttentionPercent} / ${THRESHOLDS.writeProblemPercent} % of the write period`, "Samples are lost when the writer needs more than its period; the half is a choice."],
    ["Heap floor level, attention / problem", `${THRESHOLDS.heapFloorAttention} / ${THRESHOLDS.heapFloorProblem} % of the maximum heap`, "A live data set above 70 % of the heap (Netflix Spectator example); 90 % from the node_exporter memory alert."],
    ["Heap floor rise in a day, attention", `${THRESHOLDS.heapFloorRiseAttention} points`, "A rising live set under stable load is a leak sign (Oracle troubleshooting guide); the number is a choice."],
    ["Disconnected PV, attention", `${THRESHOLDS.disconnectedSeconds / 3600} h`, "A choice: shorter losses are often restarts."],
    ["ETL busy share, problem", `${THRESHOLDS.etlBusyProblemPercent} % of its interval`, "A choice; an overran pass or a failed job is attention."],
];

function renderConfiguration(data) {
    const policies = data.policies ? Object.keys(data.policies).sort() : [];
    const rows = [
        ["Minimum sampling period", data.properties && data.properties.minimum_sampling_period ? `${data.properties.minimum_sampling_period} s` : "not reported"],
        ["Appliances in the cluster", data.cluster ? `${data.cluster.length}: ${data.cluster.map((a) => a.identity).join(", ")}` : "not read"],
        ["Policies", policies.length ? `${policies.length}: ${policies.join(", ")}` : "not read"],
    ];
    const body = $("config").querySelector("tbody");
    body.textContent = "";
    for (const [label, value] of rows) {
        body.append(node("tr", null, node("td", null, label), node("td", { class: "wrap" }, value)));
    }
    body.append(node("tr", null, node("th", { colspan: "2" }, "Thresholds the judgements use and their basis")));
    for (const [label, value, basis] of BASIS) {
        body.append(node("tr", null, node("td", null, label), node("td", { class: "wrap" }, node("span", { class: "num" }, value), node("br"), node("span", { class: "why" }, basis))));
    }
}

// ---- loading ---------------------------------------------------------------------------------------

async function gather(appliance) {
    const name = appliance.instance;
    const mine = (rows) => (rows ? rows.filter((row) => !row.instance || row.instance === name) : rows);
    const [load, storage, series, processInfo, disconnected, never, lost, fastest, largest, properties, policies, cluster, serving, ...dropped] = await settled([
        get("../bpl/getApplianceMetricsForAppliance", { appliance: name }),
        get("../bpl/getStorageMetricsForAppliance", { appliance: name }),
        get("../bpl/getProcessMetricsDataForAppliance", { appliance: name }),
        get("../bpl/getProcessMetrics"),
        get("../bpl/getCurrentlyDisconnectedPVs"),
        get("../bpl/getNeverConnectedPVs"),
        get("../bpl/getLostConnectionsReport", { limit: "5" }),
        get("../bpl/getEventRateReport", { limit: "5" }),
        get("../bpl/getPVsByStorageConsumed", { limit: "5" }),
        get("../bpl/getApplianceProperties"),
        get("../bpl/getPolicyList"),
        get("../bpl/getAppliancesInCluster"),
        get("../bpl/getApplianceInfo"),
        ...DROPPED_REPORTS.map((report) => get(report.endpoint, { limit: "1000" })),
    ]);
    return {
        appliance,
        measures: measureMap(load),
        storage,
        series,
        processInfo,
        disconnected: mine(disconnected),
        never: mine(never),
        lost: mine(lost),
        fastest: mine(fastest),
        largest: mine(largest),
        properties,
        policies,
        cluster,
        // The process report of the appliance that answered; another appliance of the cluster is not in it.
        servingIdentity: serving ? serving.identity : null,
        dropped: dropped.map(mine),
    };
}

function renderAll(data) {
    renderSamples(data);
    renderDropped(data);
    renderWrite(data);
    renderStorage(data);
    renderEtl(data);
    renderProcesses(data);
    renderConfiguration(data);
}

async function refresh() {
    try {
        list = await appliances();
        $("problem").textContent = "";
    } catch (error) {
        $("problem").textContent = `The appliance metrics could not be read: ${error.message}`;
        return;
    }
    current = chooseAppliance(list, $("applianceChoice"), refresh);
    if (!current) {
        $("problem").textContent = "No appliance reported metrics.";
        return;
    }
    try {
        latest = await gather(current);
        renderAll(latest);
    } catch (error) {
        $("problem").textContent = `The page could not be drawn: ${error.message}`;
    }
}

$("confirmCancel").addEventListener("click", () => $("confirmDialog").close());
refresh();
timer = window.setInterval(() => {
    if (!document.hidden) {
        refresh();
    }
}, REFRESH_MS);
window.addEventListener("resize", () => {
    window.clearTimeout(window.resizeTimer);
    window.resizeTimer = window.setTimeout(() => latest && renderProcesses(latest), 200);
});
