// The Retrieval performance page: what the server says about reading, and a request measured in this browser.
import { drawTimeSeries } from "../comm/js/aa/chart.js";
import { appliances, get, node, number, settled } from "./system/api.js";
import { etlTiers, heapFloor, measureMap } from "./system/judge.js";
import { chooseAppliance, statusNode } from "./system/view.js";

const $ = (id) => document.getElementById(id);
const REFRESH_MS = 30000;
let list = [];
let current = null;
let info = null;
const measurements = [];

function row(label, value) {
    return node("tr", null, node("td", null, label), node("td", { class: "r num" }, value instanceof Node ? value : String(value)));
}

function bytesText(count) {
    if (count >= 1e6) {
        return `${(count / 1e6).toFixed(1)} MB`;
    }
    return `${(count / 1e3).toFixed(1)} kB`;
}

// ---- the server side -------------------------------------------------------------------------------

async function renderServer() {
    const name = current.instance;
    const [load, series, processInfo, serving] = await settled([
        get("../bpl/getApplianceMetricsForAppliance", { appliance: name }),
        get("../bpl/getProcessMetricsDataForAppliance", { appliance: name }),
        get("../bpl/getProcessMetrics"),
        get("../bpl/getApplianceInfo"),
    ]);
    const m = measureMap(load);
    const stopped = String(current.status) !== "Working" && /retrieval/i.test(String(current.status));
    // The process report is that of the appliance that answered; for another appliance the series gives the value.
    const local = !serving || serving.identity === name;
    const retrievalMetrics = local && processInfo && processInfo.RETRIEVAL_metrics;
    const heap = (series || []).find((s) => s.label === "retrieval_heap (%)");
    const lastPoint = heap && heap.data.length ? number(heap.data[heap.data.length - 1][1]) : null;
    const heapNow = retrievalMetrics && retrievalMetrics.length ? number(retrievalMetrics[retrievalMetrics.length - 1].heapUsedPercent) : lastPoint;
    const floor = heap ? heapFloor(heap.data) : null;
    const loadSeries = (series || []).find((s) => s.label === "system_load (%)");
    const loads = loadSeries ? loadSeries.data.map((p) => Number(p[1])).filter(Number.isFinite) : [];
    const running = Object.values(etlTiers(m)).filter((tier) => tier["Current pass"] && String(tier["Current pass"]).toLowerCase() !== "none").length;
    const body = $("serverFacts").querySelector("tbody");
    body.replaceChildren(
        row("Retrieval process", statusNode(stopped ? "bad" : "ok", stopped ? "The retrieval process is not running." : "")),
        row("Requests served so far", m.get("Number of Retrieval Requests") ?? "not reported"),
        row("Unique users so far", m.get("Number of unique users") ?? "not reported"),
        row("Last request", m.get("Time of last Retrieval Request") ?? "not reported"),
        row("Retrieval heap now", heapNow === null ? "not reported" : `${heapNow.toFixed(0)} %`),
        row("Load average now / highest in 24 h", loads.length ? `${loads[loads.length - 1].toFixed(1)} / ${Math.max(...loads).toFixed(1)}` : "not reported"),
        row("ETL pass running now", running ? `${running} tier${running > 1 ? "s" : ""}` : "no"),
    );
    const host = $("heapChart");
    host.textContent = "";
    if (!floor) {
        $("heapNote").textContent = "The trend appears when the appliance has collected two hours of values.";
        return;
    }
    drawTimeSeries(host, {
        series: [
            { name: "heap", egu: "%", points: floor.data.map(([t, v]) => ({ t, v, s: 0 })), focus: false, quiet: true },
            { name: "floor", egu: "%", points: floor.floor.map(([t, v]) => ({ t, v, s: 0 })), focus: true },
        ],
        from: new Date(floor.data[0][0]),
        to: new Date(floor.data[floor.data.length - 1][0]),
        gapMs: 600000,
    });
    $("heapNote").textContent = `Lowest after a collection: ${floor.first.toFixed(0)} % at the start of the day, ${floor.last.toFixed(0)} % now. ${floor.text}`.trim();
}

// ---- the measurement made in this browser ----------------------------------------------------------

async function applianceInfo() {
    if (!info) {
        info = await get("../bpl/getApplianceInfo");
    }
    return info;
}

async function measure(event) {
    event.preventDefault();
    $("measureError").textContent = "";
    const pv = $("measurePV").value.trim();
    const hours = Number($("measureRange").value);
    const button = $("measureForm").querySelector("button");
    button.disabled = true;
    try {
        const where = await applianceInfo();
        const to = new Date();
        const from = new Date(to.getTime() - hours * 3600000);
        const query = new URLSearchParams({ pv, from: from.toISOString(), to: to.toISOString() });
        const started = performance.now();
        const response = await fetch(`${where.dataRetrievalURL}/data/getData.json?${query}`);
        const firstByte = performance.now() - started;
        if (!response.ok) {
            throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
        }
        const buffer = await response.arrayBuffer();
        const complete = performance.now() - started;
        const parsed = JSON.parse(new TextDecoder().decode(buffer));
        const samples = parsed.reduce((sum, series) => sum + (series.data ? series.data.length : 0), 0);
        measurements.unshift({
            when: new Date().toLocaleTimeString([], { hour12: false }),
            pv,
            range: $("measureRange").selectedOptions[0].textContent,
            samples,
            size: buffer.byteLength,
            firstByte,
            complete,
        });
        renderMeasurements();
    } catch (error) {
        $("measureError").textContent = `The request failed: ${error.message}`;
    } finally {
        button.disabled = false;
    }
}

function renderMeasurements() {
    const body = $("measurements").querySelector("tbody");
    body.textContent = "";
    for (const m of measurements.slice(0, 20)) {
        body.append(
            node(
                "tr",
                null,
                node("td", { class: "num" }, m.when),
                node("td", { class: "pv" }, m.pv),
                node("td", null, m.range),
                node("td", { class: "r num" }, m.samples.toLocaleString()),
                node("td", { class: "r num" }, bytesText(m.size)),
                node("td", { class: "r num" }, `${m.firstByte.toFixed(0)} ms`),
                node("td", { class: "r num" }, m.complete >= 1000 ? `${(m.complete / 1000).toFixed(2)} s` : `${m.complete.toFixed(0)} ms`),
            ),
        );
    }
}

// ---- data available for a PV -----------------------------------------------------------------------

async function lookUp(event) {
    event.preventDefault();
    $("dataError").textContent = "";
    const pv = $("dataPV").value.trim();
    const body = $("dataFacts").querySelector("tbody");
    body.textContent = "";
    try {
        const [typeInfo, status] = await Promise.all([get("../bpl/getPVTypeInfo", { pv }), get("../bpl/getPVStatus", { pv })]);
        if (!typeInfo || !typeInfo.pvName) {
            $("dataError").textContent = "The archiver has no settings for this PV.";
            return;
        }
        const state = Array.isArray(status) && status[0] ? status[0] : {};
        const stores = (typeInfo.dataStores || []).map((url) => {
            const found = /name=([A-Z]+)/.exec(url);
            return found ? found[1] : url;
        });
        const rows = [
            ["State", state.status || "unknown"],
            ["Archiving since", typeInfo.creationTime || "unknown"],
            ["Settings changed", typeInfo.modificationTime || "unknown"],
            ["Last event", state.lastEvent || "none yet"],
            ["Sampling", `${typeInfo.samplingMethod || "?"}, period ${typeInfo.samplingPeriod ?? "?"} s`],
            ["Paused", String(typeInfo.paused)],
            ["Stores", stores.join(" then ") || "unknown"],
            ["Data reduced in the long term store", typeInfo.hasReducedDataSet === "true" || typeInfo.hasReducedDataSet === true ? "yes" : "no"],
            ["Host the PV was first seen on", typeInfo.hostName || "unknown"],
        ];
        for (const [label, value] of rows) {
            body.append(row(label, value));
        }
    } catch (error) {
        $("dataError").textContent = `The PV could not be looked up: ${error.message}`;
    }
}

// ---- start -----------------------------------------------------------------------------------------

async function refresh() {
    try {
        list = await appliances();
        $("problem").textContent = "";
    } catch (error) {
        $("problem").textContent = `The appliance metrics could not be read: ${error.message}`;
        return;
    }
    current = chooseAppliance(list, $("applianceChoice"), refresh);
    if (current) {
        await renderServer();
    }
}

$("measureForm").addEventListener("submit", measure);
$("dataForm").addEventListener("submit", lookUp);
refresh();
window.setInterval(() => {
    if (!document.hidden) {
        refresh();
    }
}, REFRESH_MS);
