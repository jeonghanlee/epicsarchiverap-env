// The System overview: three questions answered first, then one row per measure with what it means and where the
// detail is. The judgements are made in system/judge.js.
import { appliances, get, node, number, settled } from "./system/api.js";
import {
    DROPPED_REPORTS,
    daysText,
    etlTiers,
    judgeConnections,
    judgeDropped,
    judgeEtl,
    judgeStorage,
    judgeWrite,
    measureMap,
    worst,
} from "./system/judge.js";
import { chooseAppliance, clock, pageHref, statusNode } from "./system/view.js";

const $ = (id) => document.getElementById(id);
const REFRESH_MS = 20000;
let list = [];
let current = null;
let timer = 0;

async function gather(appliance) {
    const name = appliance.instance;
    const [load, storage, disconnected, never, versions, ...dropped] = await settled([
        get("../bpl/getApplianceMetricsForAppliance", { appliance: name }),
        get("../bpl/getStorageMetricsForAppliance", { appliance: name }),
        get("../bpl/getCurrentlyDisconnectedPVs"),
        get("../bpl/getNeverConnectedPVs"),
        get("../bpl/getVersions"),
        ...DROPPED_REPORTS.map((report) => get(report.endpoint, { limit: "1000" })),
    ]);
    const mine = (rows) => (rows ? rows.filter((row) => !row.instance || row.instance === name) : rows);
    return {
        measures: measureMap(load),
        storage,
        disconnected: mine(disconnected),
        never: mine(never),
        versions,
        dropped: dropped.map(mine),
    };
}

function rowsFor(appliance, data) {
    const measures = data.measures;
    const connection = judgeConnections(appliance, data.disconnected, data.never);
    const dropped = judgeDropped(data.dropped);
    const write = judgeWrite(measures);
    const etl = judgeEtl(etlTiers(measures));
    const bytesPerSecond = number(appliance.dataRate);
    const storage = judgeStorage(data.storage, bytesPerSecond);
    const total = number(appliance.pvCount);
    const connected = number(appliance.connectedPVCount);
    const paused = number(measures.get("Paused PV count"));
    const events = number(measures.get("Event Rate (in events/sec)"));
    const requests = measures.get("Number of Retrieval Requests");
    const users = measures.get("Number of unique users");
    const stopped = String(appliance.status) !== "Working";
    const retrievalDown = /retrieval/i.test(String(appliance.status)) && stopped;
    const differing = data.versions && "components_with_different_versions" in data.versions;
    const free = data.storage && data.storage.length ? Math.min(...data.storage.map((d) => number(d.available_space_percent) ?? 100)) : null;
    const components = stopped
        ? { kind: "bad", text: `The appliance reports: ${appliance.status}.` }
        : differing
          ? { kind: "warn", text: "The components run different versions." }
          : { kind: "ok", text: "" };
    const rows = [
        {
            item: "Archived PVs",
            now: total === null ? "?" : `${total.toLocaleString()}${paused ? ` (${paused} paused)` : ""}`,
            kind: "ok",
            text: "",
            meaning: "PVs the archiver stores samples for. A paused PV is known but is not sampled.",
            link: "Samples",
            href: "operations.html#samples",
        },
        {
            item: "Connected PVs",
            now: connected === null || total === null ? "?" : `${connected.toLocaleString()} of ${total.toLocaleString()}`,
            kind: connection.kind,
            text: connection.text,
            meaning: "PVs the engine can reach now. A PV that was never connected may not exist.",
            link: "Samples",
            href: "operations.html#samples",
        },
        {
            item: "Samples arriving",
            now: events === null ? `${appliance.eventRate} per second` : `${events.toLocaleString(undefined, { maximumFractionDigits: 1 })} per second`,
            kind: "ok",
            text: "",
            meaning: "How many samples the engine receives per second, summed over all PVs.",
            link: "Samples",
            href: "operations.html#samples",
        },
        {
            item: "Samples dropped",
            now: dropped.pvs ? `${dropped.events.toLocaleString()} from ${dropped.pvs} PV${dropped.pvs > 1 ? "s" : ""}` : "0",
            kind: dropped.kind,
            text: dropped.text,
            meaning: "Samples the engine discarded: a wrong timestamp, a full buffer or a type change. Any number above zero is lost data.",
            link: "Samples lost",
            href: "operations.html#dropped",
        },
        {
            item: "Writing to disk",
            now: write.usage === null ? "unknown" : `${write.usage.toFixed(write.usage < 1 ? 2 : 0)} % of the write period`,
            kind: write.kind,
            text: write.text,
            meaning: "The share of its write period the engine needs for writing. At 100 % it falls behind and drops samples.",
            link: "Write path",
            href: "operations.html#write",
        },
        {
            item: "Moving data between stores",
            now: etl.kind === "unknown" ? "unknown" : `busiest pass ${etl.busiest.toFixed(0)} % of its interval`,
            kind: etl.kind,
            text: etl.text,
            meaning: "The ETL moves data from the short term store to the medium and long term stores. When it cannot keep up, the short term store fills.",
            link: "Stores",
            href: "operations.html#stores",
        },
        {
            item: "Storage left",
            now: `${daysText(storage.days)}${free === null ? "" : `, ${free.toFixed(1)} % free`}`,
            kind: storage.kind,
            text: storage.text,
            meaning: "Free space divided by the data the archiver adds per day, and the free share of the fullest device.",
            link: "Stores",
            href: "operations.html#stores",
        },
        {
            item: "Retrieval",
            now: requests === undefined ? "?" : `${requests} request${requests === "1" ? "" : "s"}, ${users ?? "?"} user${users === "1" ? "" : "s"}`,
            kind: retrievalDown ? "bad" : "ok",
            text: retrievalDown ? "The retrieval process is not running, so no request is served." : "",
            meaning: "Data requests served so far. The server does not record how long they take; the Retrieval performance page measures one.",
            link: "Retrieval performance",
            href: "retrieval.html",
        },
        {
            item: "Components",
            now: stopped ? String(appliance.status) : "all running",
            kind: components.kind,
            text: components.text,
            meaning: "Management, engine, ETL and retrieval run as separate processes and must all run, at the same version.",
            link: "Processes",
            href: "operations.html#processes",
        },
    ];
    return { rows, connection, dropped, write, etl, storage, retrievalDown, stopped };
}

function render(appliance, data) {
    const result = rowsFor(appliance, data);
    const { rows } = result;
    const storing = worst(rows.filter((row) => ["Connected PVs", "Samples dropped", "Writing to disk", "Moving data between stores"].includes(row.item)).map((row) => row.kind));
    const firstProblem = (items) => rows.filter((row) => items.includes(row.item) && row.kind !== "ok").sort((a, b) => (a.kind === "bad" ? -1 : 1) - (b.kind === "bad" ? -1 : 1))[0];
    const storingRow = firstProblem(["Connected PVs", "Samples dropped", "Writing to disk", "Moving data between stores"]);
    const connected = number(appliance.connectedPVCount);
    const total = number(appliance.pvCount);
    const verdicts = [
        {
            what: "Storing samples",
            kind: storing,
            text: storingRow
                ? `${storingRow.text} See ${storingRow.link}.`
                : `Samples are being stored: ${connected === null ? "?" : connected.toLocaleString()} of ${total === null ? "?" : total.toLocaleString()} PVs are connected and none were dropped.`,
        },
        {
            what: "Reading data",
            kind: result.retrievalDown ? "bad" : "ok",
            text: result.retrievalDown ? "Retrieval is not running. See Processes." : "Retrieval is running.",
        },
        {
            what: "Room left",
            kind: result.storage.kind,
            text:
                result.storage.kind === "ok"
                    ? result.storage.days === null
                        ? "The archiver adds no data at the moment, so the days left cannot be computed."
                        : `At the current growth the space lasts ${daysText(result.storage.days)}.`
                    : `${result.storage.text} See Stores.`,
        },
    ];
    const overall = worst([...verdicts.map((v) => v.kind), ...rows.map((r) => r.kind)]);
    const unreported = rows.filter((row) => row.kind === "unknown").length;
    const normal = unreported ? `no problem found, ${unreported} measure${unreported > 1 ? "s" : ""} not reported` : "archiving normally";
    $("headline").textContent = `${appliance.instance}: ${overall === "ok" ? normal : overall === "warn" ? "needs a look" : "needs action"}`;
    const verdictList = $("verdicts");
    verdictList.textContent = "";
    for (const verdict of verdicts) {
        verdictList.append(node("li", null, node("span", { class: "what" }, verdict.what), statusNode(verdict.kind, verdict.text)));
    }
    const body = $("summary").querySelector("tbody");
    body.textContent = "";
    for (const row of rows) {
        body.append(
            node(
                "tr",
                null,
                node("td", null, row.item),
                node("td", { class: "num" }, row.now),
                node("td", null, statusNode(row.kind, row.text)),
                node("td", { class: "why" }, row.meaning),
                node("td", null, node("a", { href: pageHref(row.href) }, row.link)),
            ),
        );
    }
    $("asOf").textContent = `As of ${clock()}, refreshed every ${REFRESH_MS / 1000} s while this page is open.`;
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
        $("headline").textContent = "No appliance reported metrics";
        return;
    }
    $("versionLine").textContent = "";
    try {
        const data = await gather(current);
        render(current, data);
        const versions = data.versions;
        if (versions) {
            $("versionLine").textContent = String(versions.mgmt_version || "");
        }
    } catch (error) {
        $("problem").textContent = `The status could not be judged: ${error.message}`;
    }
}

function start() {
    refresh();
    window.clearInterval(timer);
    timer = window.setInterval(() => {
        if (!document.hidden) {
            refresh();
        }
    }, REFRESH_MS);
}

start();
