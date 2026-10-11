// The Work page: find PVs, scan the selected ones, inspect a few in detail, and act on them.
import * as api from "./work/api.js";
import { drawTimeSeries } from "../comm/js/aa/chart.js";
import { sparkline } from "../comm/js/aa/spark.js";
import { drawHistogram, drawScatter } from "../comm/js/aa/plots.js";

// Initial limits (D47). They are configuration; measurement and use adjust them.
const LIMITS = { scan: 100, chart: 5, concurrentRequests: 6, indexed: 500000 };
// A row of the result list is as high as a touch target on a narrow screen.
function rowHeight() {
    return window.matchMedia("(max-width: 600px)").matches ? 44 : 30;
}
// A name as the server reads it: the base name, then an optional field (X:Y.RBV).
const PV_NAME = /^[a-zA-Z0-9:_\-+[\];/,#{}^<>]+(\.[a-zA-Z_][a-zA-Z0-9_]*)?$/;
// Up to this span the server answer is not reduced (bin = ceil(seconds / 600)).
const BIN_FREE_MINUTES = 10;

const STATES = {
    "Being archived": "The engine is sampling this PV and its samples are being stored.",
    Paused: "The archiver knows this PV but is not sampling it. Resume to continue storing samples.",
    Disconnected: "The archiver cannot reach this PV on the control system network. No samples are stored until it returns.",
    "Not being archived": "The archiver has no request for this PV. Archive it to start storing samples.",
    "Initial sampling": "The archiver is looking up the type and settings of this PV before it stores samples.",
    "Appliance assigned": "The request was accepted and the PV is assigned to an appliance. Sampling has not started yet.",
    "Appliance Down": "The appliance that holds this PV does not answer, so its state cannot be read.",
};

// States of a PV whose archive request has not finished; the request can still be aborted.
const PENDING = new Set(["Initial sampling", "Appliance assigned"]);

// Reports of the server shown as a selection of the list. value is the field that is shown beside each PV.
// A ranked report keeps the order of the server; the others are in alphabetical order.
const TOP = { limit: "1000" };
const REPORTS = {
    disconnected: { endpoint: "../bpl/getCurrentlyDisconnectedPVs", value: "lastKnownEvent", note: "Beside each PV: the time of its last event." },
    paused: { endpoint: "../bpl/getPausedPVsReport", value: "modificationTime", note: "Beside each PV: when its settings last changed." },
    never: { endpoint: "../bpl/getNeverConnectedPVs", value: "requestTime", note: "Beside each PV: when its archive request was made." },
    metagets: { endpoint: "../bpl/getMetaGets", value: "internalState", note: "Beside each PV: the state of its first connection." },
    recent: { endpoint: "../bpl/getRecentlyAddedPVs", params: TOP, value: "creationTime", ranked: true, note: "Newest first. Beside each PV: when it was added." },
    modified: { endpoint: "../bpl/getRecentlyModifiedPVs", params: TOP, value: "modificationTime", ranked: true, note: "Newest first. Beside each PV: when it changed." },
    eventrate: { endpoint: "../bpl/getEventRateReport", params: TOP, value: "eventRate", ranked: true, note: "Highest first. Beside each PV: events per second." },
    storagerate: { endpoint: "../bpl/getStorageRateReport", params: TOP, value: "storageRate_MBperDay", ranked: true, note: "Highest first. Beside each PV: MB of storage per day." },
    consumed: { endpoint: "../bpl/getPVsByStorageConsumed", params: TOP, value: "storageConsumedInMB", ranked: true, note: "Highest first. Beside each PV: MB of storage used." },
    lost: { endpoint: "../bpl/getLostConnectionsReport", params: TOP, value: "lostConnections", ranked: true, note: "Highest first. Beside each PV: connection drops." },
    silent: { endpoint: "../bpl/getSilentPVsReport", params: TOP, value: "lastKnownEvent", ranked: true, note: "Silent longest first. Beside each PV: the time of its last event." },
    droppedtime: { endpoint: "../bpl/getPVsByDroppedEventsTimestamp", params: TOP, value: "eventsDropped", ranked: true, note: "Highest first. Beside each PV: events dropped for a wrong time stamp." },
    droppedbuffer: { endpoint: "../bpl/getPVsByDroppedEventsBuffer", params: TOP, value: "eventsDropped", ranked: true, note: "Highest first. Beside each PV: events dropped by buffer overflow." },
    droppedtype: { endpoint: "../bpl/getPVsByDroppedEventsTypeChange", params: TOP, value: "eventsDropped", ranked: true, note: "Highest first. Beside each PV: events dropped by a type change." },
};

/** A number is shown with four significant digits; a text stays as the server gave it. */
function reportValue(raw) {
    if (raw === undefined || raw === null || raw === "") {
        return "";
    }
    const number = Number(raw);
    return Number.isFinite(number) && /^-?[\d.]+(e[+-]?\d+)?$/i.test(String(raw)) ? String(Number(number.toPrecision(4))) : String(raw);
}

const state = {
    count: 0,
    asOf: 0,
    overflow: false,
    partial: false,
    query: "",
    mode: "contains",
    prefix: null,
    report: null,
    allowed: null,
    reportValues: new Map(),
    reportRanked: false,
    results: [],
    total: 0,
    groups: {},
    selected: [],
    active: 0,
    focus: null,
    status: new Map(),
    data: new Map(),
    rangeMinutes: 60,
    // The address of the data retrieval application, known after the first answer of the appliance information.
    retrievalBase: "",
    // A window the person dragged out of the chart, or null while the range button decides.
    window: null,
    minimumSamplingPeriod: 0.1,
};

const $ = (id) => document.getElementById(id);
let pendingReport = null;
let addressNote = "";

function node(tag, attributes, ...children) {
    const element = document.createElement(tag);
    for (const [key, value] of Object.entries(attributes || {})) {
        if (value !== undefined && value !== null) {
            element.setAttribute(key, value);
        }
    }
    element.append(...children.filter((child) => child !== null && child !== undefined));
    return element;
}

function stateOf(name) {
    const row = state.status.get(name);
    if (!row) {
        return null;
    }
    if (row.status === "Being archived" && String(row.connectionState) === "false") {
        return "Disconnected";
    }
    return row.status;
}

function formatValue(value, egu) {
    if (value === undefined) {
        return "";
    }
    const digits = Math.abs(value) >= 100 ? 1 : Math.abs(value) >= 1 ? 3 : 4;
    return `${value.toFixed(digits)}${egu ? ` ${egu}` : ""}`;
}

// ---- names and search ---------------------------------------------------------------------

const worker = new Worker("js/work/names-worker.js");
let searchId = 0;
let latestSearch = 0;

// The worker keeps the list of names current by itself; the page is told when it changed.
let namesReady;
const namesLoaded = new Promise((resolve) => {
    namesReady = resolve;
});

function describeIndex(message) {
    if (message.error) {
        return `The PV list could not be refreshed: ${message.error}`;
    }
    if (!message.asOf) {
        return "Loading PV names…";
    }
    const time = new Date(message.asOf).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
    if (message.overflow) {
        return `${message.count.toLocaleString()} PVs: the server searches the list. As of ${time}.`;
    }
    return `As of ${time}${message.syncing ? ", checking" : ""}.`;
}

worker.onmessage = (event) => {
    const message = event.data;
    if (message.type === "status") {
        state.count = message.count;
        state.asOf = message.asOf;
        state.overflow = message.overflow;
        $("indexCount").textContent = describeIndex(message);
        if (message.asOf || message.error) {
            namesReady();
        }
        if (message.changed) {
            runSearch();
        }
    } else if (message.type === "result" && message.id === latestSearch) {
        $("searchError").textContent = message.error || "";
        state.results = message.names;
        state.total = message.total;
        state.groups = message.groups || {};
        state.partial = Boolean(message.partial);
        renderFinder();
    }
};

function startNames() {
    worker.postMessage({ type: "init", base: document.baseURI, key: window.location.pathname, indexLimit: LIMITS.indexed });
    document.addEventListener("visibilitychange", () => {
        worker.postMessage({ type: "visibility", visible: !document.hidden });
        if (!document.hidden) {
            refreshStatus(0);
        }
    });
}

// A name was added or removed from this page: do not wait for the next check.
function refreshNames(full) {
    worker.postMessage({ type: "refresh", full: Boolean(full) });
}

function runSearch() {
    searchId += 1;
    latestSearch = searchId;
    worker.postMessage({
        type: "search",
        id: searchId,
        query: state.query,
        mode: state.mode,
        prefix: state.prefix,
        allowed: state.allowed,
        keepOrder: state.reportRanked,
        limit: 50000,
    });
    writeAddress();
}

function renderFinder() {
    const groups = $("groups");
    groups.textContent = "";
    Object.keys(state.groups)
        .sort()
        .slice(0, 24)
        .forEach((key) => {
            const button = node("button", { type: "button", "aria-pressed": String(state.prefix === key) }, key);
            button.append(node("span", { class: "n" }, String(state.groups[key])));
            button.addEventListener("click", () => {
                state.prefix = state.prefix === key ? null : key;
                runSearch();
            });
            groups.append(button);
        });

    $("count").textContent = state.overflow
        ? `${state.total.toLocaleString()}${state.partial ? " or more" : ""} PVs match`
        : `${state.total.toLocaleString()} of ${state.count.toLocaleString()} PVs match`;
    renderResults();
    renderArchiveOffer();
}

async function setReport(key) {
    $("searchError").textContent = "";
    if (!key) {
        state.report = null;
        state.allowed = null;
        state.reportValues = new Map();
        state.reportRanked = false;
        $("reportNote").textContent = "";
        runSearch();
        return;
    }
    const report = REPORTS[key];
    try {
        const rows = await api.reportRows(report.endpoint, report.params);
        state.allowed = rows.map((row) => row.pvName ?? row.name).filter(Boolean);
        state.reportValues = new Map(rows.map((row) => [row.pvName ?? row.name, reportValue(row[report.value])]));
        state.reportRanked = Boolean(report.ranked);
        state.report = key;
        $("reportNote").textContent = report.note;
    } catch (error) {
        $("searchError").textContent = `Could not load this selection: ${error.message}`;
        $("report").value = state.report || "";
        return;
    }
    runSearch();
}

// A windowed list: only the rows in view exist in the document.
function renderResults() {
    const list = $("results");
    const spacer = $("resultsSpacer");
    spacer.style.height = `${state.results.length * rowHeight()}px`;
    const top = list.scrollTop;
    const first = Math.max(0, Math.floor(top / rowHeight()) - 5);
    const last = Math.min(state.results.length, Math.ceil((top + list.clientHeight) / rowHeight()) + 5);
    const rows = $("resultRows");
    rows.textContent = "";
    for (let i = first; i < last; i += 1) {
        const name = state.results[i];
        const selected = state.selected.includes(name);
        const row = node("li", { role: "option", id: `row-${i}`, class: i === state.active ? "active" : null, "aria-selected": String(selected) });
        row.style.transform = `translateY(${i * rowHeight()}px)`;
        row.append(node("span", { class: "tick" }), node("span", { class: "pv" }, name));
        const word = stateOf(name);
        if (state.report && state.reportValues.has(name)) {
            row.append(node("span", { class: "num report-value" }, state.reportValues.get(name)));
        } else if (word && word !== "Being archived") {
            row.append(node("span", { class: `state-word ${word === "Disconnected" ? "warn" : ""}` }, word));
        }
        row.addEventListener("click", () => toggle(name));
        rows.append(row);
    }
    readVisibleStatus(first, last);
}

// The state of the rows in view, read in one call for the rows that have none or an old one. A name that is not
// archived answers "Not being archived", so the list tells which of the names it shows can be plotted.
const rowStatusAt = new Map();
let visibleTimer = 0;
function readVisibleStatus(first, last) {
    window.clearTimeout(visibleTimer);
    visibleTimer = window.setTimeout(async () => {
        if (document.hidden) {
            return;
        }
        const selected = new Set(state.selected);
        const names = state.results
            .slice(first, last)
            .filter((name) => !selected.has(name) && Date.now() - (rowStatusAt.get(name) || 0) > 30000)
            .slice(0, 60);
        if (!names.length) {
            return;
        }
        for (const name of names) {
            rowStatusAt.set(name, Date.now());
        }
        try {
            const rows = await api.pvStatus(names);
            for (const row of rows) {
                state.status.set(row.pvName, row);
            }
            if (state.status.size > 5000) {
                for (const key of Array.from(state.status.keys())) {
                    if (!selected.has(key) && !names.includes(key)) {
                        state.status.delete(key);
                    }
                }
            }
            renderResults();
        } catch (error) {
            // The rows stay without a state; the next scroll asks again.
            for (const name of names) {
                rowStatusAt.delete(name);
            }
        }
    }, 250);
}

function renderArchiveOffer() {
    const offer = $("archiveOffer");
    offer.textContent = "";
    const text = state.query.trim();
    if (state.mode === "contains" && state.total === 0 && PV_NAME.test(text)) {
        const button = node("button", { type: "button" }, `Archive ${text}…`);
        button.addEventListener("click", () => openArchiveDialog([text]));
        offer.append(node("span", { class: "muted" }, "No archived PV has this name. "), button);
    }
}

// Keyboard use of the list: the arrow keys move, Space or Enter selects or clears the active row.
function moveInResults(event) {
    const count = state.results.length;
    if (!count) {
        return;
    }
    const list = $("results");
    const page = Math.max(1, Math.floor(list.clientHeight / rowHeight()) - 1);
    const moves = { ArrowDown: 1, ArrowUp: -1, PageDown: page, PageUp: -page };
    if (event.key in moves) {
        state.active = Math.min(count - 1, Math.max(0, state.active + moves[event.key]));
    } else if (event.key === "Home") {
        state.active = 0;
    } else if (event.key === "End") {
        state.active = count - 1;
    } else if (event.key === " " || event.key === "Enter") {
        event.preventDefault();
        toggle(state.results[state.active]);
        return;
    } else {
        return;
    }
    event.preventDefault();
    if (state.active * rowHeight() < list.scrollTop) {
        list.scrollTop = state.active * rowHeight();
    } else if ((state.active + 1) * rowHeight() > list.scrollTop + list.clientHeight) {
        list.scrollTop = (state.active + 1) * rowHeight() - list.clientHeight;
    }
    list.setAttribute("aria-activedescendant", `row-${state.active}`);
    renderResults();
}

// ---- selection, status, data ---------------------------------------------------------------

function toggle(name) {
    const index = state.selected.indexOf(name);
    if (index >= 0) {
        state.selected.splice(index, 1);
        if (state.focus === name) {
            state.focus = state.selected[0] || null;
        }
    } else if (state.selected.length < LIMITS.scan) {
        state.selected.push(name);
        state.focus = name;
    } else {
        $("limitNote").textContent = `The scan list holds at most ${LIMITS.scan} PVs.`;
    }
    afterSelection();
}

function afterSelection() {
    renderResults();
    renderScan();
    renderDetail();
    refreshStatus();
    refreshData();
    writeAddress();
}

// The status is read again while the page is visible: soon after an action and while a request is
// unfinished, and at a slow pace otherwise, so a change made elsewhere shows up too.
const STATUS_FAST_MS = 3000;
const STATUS_SLOW_MS = 20000;
const AFTER_ACTION_MS = 30000;
let statusTimer = 0;
let fastUntil = 0;

function refreshStatus(delay = 150) {
    window.clearTimeout(statusTimer);
    statusTimer = window.setTimeout(readStatus, delay);
}

async function readStatus() {
    if (!state.selected.length || document.hidden) {
        return;
    }
    try {
        const rows = await api.pvStatus(state.selected);
        for (const row of rows) {
            state.status.set(row.pvName, row);
        }
        renderScan();
        renderDetail();
        renderResults();
    } catch (error) {
        $("limitNote").textContent = `Could not read the status: ${error.message}`;
    }
    const unfinished = state.selected.some((name) => {
        const word = stateOf(name);
        return !word || PENDING.has(word);
    });
    refreshStatus(unfinished || Date.now() < fastUntil ? STATUS_FAST_MS : STATUS_SLOW_MS);
}

// Many PVs answer within a few milliseconds of each other; the list and the chart are drawn once per short interval
// instead of once per answer, which keeps the cost of a selection linear in the number of PVs.
let renderTimer = 0;
function scheduleRender() {
    if (renderTimer) {
        return;
    }
    renderTimer = window.setTimeout(() => {
        renderTimer = 0;
        renderScan();
        renderChart();
    }, 60);
}

let dataController = null;
async function refreshData() {
    if (dataController) {
        dataController.abort();
    }
    dataController = new AbortController();
    const { signal } = dataController;
    // One value per ten pixels or so: the bin follows the span of the window, and a short window is read unreduced.
    const to = state.window ? state.window.to : new Date();
    const from = state.window ? state.window.from : new Date(to.getTime() - state.rangeMinutes * 60000);
    const bin = Math.max(1, Math.ceil((to.getTime() - from.getTime()) / 1000 / 600));
    const key = state.window ? `${from.getTime()}-${to.getTime()}` : `last-${state.rangeMinutes}`;
    const wanted = state.selected.filter((name) => {
        const cached = state.data.get(name);
        // A fixed window does not age; a window that ends now is read again after half a minute.
        return !cached || cached.key !== key || (!state.window && Date.now() - cached.loaded > 30000);
    });
    let next = 0;
    const pump = async () => {
        while (next < wanted.length && !signal.aborted) {
            const name = wanted[next];
            next += 1;
            // One retry covers a request that fails once in transit; the reason of a second failure stays visible.
            for (let attempt = 1; attempt <= 2 && !signal.aborted; attempt += 1) {
                try {
                    const result = await api.series(name, from, to, bin, signal);
                    state.data.set(name, { ...result, key, minutes: state.rangeMinutes, loaded: Date.now(), from, to, bin });
                    break;
                } catch (error) {
                    if (error.name === "AbortError") {
                        break;
                    }
                    if (attempt === 2) {
                        state.data.set(name, { name, egu: "", points: [], key, minutes: state.rangeMinutes, loaded: Date.now(), from, to, bin, failed: true, error: String(error.message || error) });
                    }
                }
            }
            if (!signal.aborted) {
                scheduleRender();
            }
        }
    };
    await Promise.all(Array.from({ length: LIMITS.concurrentRequests }, pump));
}

// ---- rendering of scan, chart, detail ------------------------------------------------------

/** The address of the data viewer for some PVs, over the window of the chart; empty until the retrieval address is known. */
function viewerHref(names) {
    if (!/^https?:\/\//i.test(state.retrievalBase) || !names.length) {
        return "";
    }
    const to = state.window ? state.window.to : new Date();
    const from = state.window ? state.window.from : new Date(to.getTime() - state.rangeMinutes * 60000);
    const query = new URLSearchParams();
    for (const name of names) {
        query.append("pv", name);
    }
    query.set("from", from.toISOString());
    query.set("to", to.toISOString());
    return `${state.retrievalBase}/ui/viewer/archViewer.html?${query}`;
}

function renderScan() {
    $("bulk").hidden = !state.selected.length;
    const all = viewerHref(state.selected);
    $("viewerAll").hidden = !all;
    if (all) {
        $("viewerAll").setAttribute("href", all);
    }
    $("selN").textContent = String(state.selected.length);
    $("limScan").textContent = String(state.selected.length);
    $("limScanMax").textContent = String(LIMITS.scan);
    const body = $("scan").querySelector("tbody");
    body.textContent = "";
    if (!state.selected.length) {
        const row = node("tr", null, node("td", { colspan: "5", class: "empty" }, "Pick PVs in the list to see their last hour here."));
        body.append(row);
    }
    for (const name of state.selected) {
        const word = stateOf(name);
        const data = state.data.get(name);
        const status = state.status.get(name);
        const row = node("tr", { "data-focus": String(state.focus === name), tabindex: "0" });
        row.append(node("td", { class: word && word !== "Being archived" ? "state state-word warn" : "state state-word" }, word && word !== "Being archived" ? word : ""));
        row.append(node("td", { class: "pv" }, name));
        const spark = node("td", { class: "spark-cell" });
        if (data && data.points.length) {
            spark.append(sparkline(data.points, data.points.some((p) => p.s > 0)));
        }
        row.append(spark);
        const last = data && data.points.length ? data.points[data.points.length - 1] : null;
        const now = node("td", { class: "r num now", title: data && data.error ? data.error : null }, last ? formatValue(last.v, data.egu) : data && data.failed ? "no data" : data && !data.points.length ? "no samples" : "");
        row.append(now);
        row.append(node("td", { class: "r num faint last" }, status ? status.lastEvent || "" : ""));
        const focusRow = () => {
            state.focus = name;
            renderScan();
            renderChart();
            renderDetail();
        };
        row.addEventListener("click", focusRow);
        row.addEventListener("keydown", (event) => {
            if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                focusRow();
            }
        });
        body.append(row);
    }
}

function chartList() {
    const focus = state.focus && state.data.get(state.focus);
    if (!focus || !focus.points.length) {
        return { list: [], other: 0, over: 0 };
    }
    const same = state.selected
        .map((name) => state.data.get(name))
        .filter((d) => d && d.points.length && d.egu === focus.egu);
    const list = same.slice(0, LIMITS.chart);
    if (!list.includes(focus)) {
        list.splice(LIMITS.chart - 1, 1, focus);
    }
    const loaded = state.selected.filter((name) => state.data.get(name)?.points.length).length;
    return { list, other: loaded - same.length, over: same.length - list.length };
}

function zoomTo(from, to) {
    state.window = { from, to };
    state.data.clear();
    refreshData();
    writeAddress();
}

/** Moves the window by half of its span, earlier or later; it never reaches into the future. */
function panBy(direction) {
    if (!state.window) {
        return;
    }
    const span = state.window.to.getTime() - state.window.from.getTime();
    let to = state.window.to.getTime() + (direction * span) / 2;
    const now = Date.now();
    if (to > now) {
        to = now;
    }
    state.window = { from: new Date(to - span), to: new Date(to) };
    state.data.clear();
    refreshData();
    writeAddress();
}

function showZoomControls() {
    const zoomed = Boolean(state.window);
    for (const id of ["zoomReset", "panEarlier", "panLater"]) {
        $(id).hidden = !zoomed;
    }
    // A window that already ends now cannot move later.
    $("panLater").disabled = zoomed && Date.now() - state.window.to.getTime() < 2000;
}

function renderChart() {
    const host = $("chart");
    const { list, other, over } = chartList();
    $("limChart").textContent = String(list.length);
    $("limChartMax").textContent = String(LIMITS.chart);
    if (!list.length) {
        const answered = state.selected.length > 0 && state.selected.every((name) => state.data.has(name));
        host.textContent = !state.selected.length
            ? "Select PVs to plot them here."
            : answered
              ? "No samples in this time range. A PV that did not change has none; try a wider range."
              : "Loading samples…";
        $("chartTitle").textContent = "Time series";
        $("chartNote").textContent = "";
        showZoomControls();
        renderStats([]);
        renderPlots([]);
        return;
    }
    const first = list[0];
    $("chartTitle").textContent = `${list.length} PV${list.length > 1 ? "s" : ""}${first.egu ? ` in ${first.egu}` : ""}`;
    const notes = [];
    if (other > 0) {
        notes.push(`${other} selected PV${other > 1 ? "s use" : " uses"} another unit and ${other > 1 ? "are" : "is"} not drawn here.`);
    }
    if (over > 0) {
        notes.push(`${over} more than the chart limit of ${LIMITS.chart} stay in the scan list only.`);
    }
    if (first.bin > 1) {
        notes.push(`Values are means over ${first.bin} s; an interval without a sample has no value. A window of ${BIN_FREE_MINUTES} minutes or less shows the stored samples.`);
    }
    const clock = (date) => date.toLocaleTimeString([], { hour12: false });
    notes.push(state.window ? `Showing ${clock(first.from)} to ${clock(first.to)}. Drag across the chart to zoom further.` : "Drag across the chart to look at a window.");
    $("chartNote").textContent = notes.join(" ");
    drawTimeSeries(host, {
        series: list.map((d) => ({ name: d.name, egu: d.egu, points: d.points, focus: d.name === state.focus })),
        from: first.from,
        to: first.to,
        gapMs: Infinity,
        onZoom: zoomTo,
    });
    showZoomControls();
    renderStats(list);
    renderPlots(list);
}

/** The distribution of the focused PV and the scatter of the first two PVs of the chart. */
function renderPlots(list) {
    const focus = list.find((d) => d.name === state.focus) || list[0];
    if (!focus) {
        $("hist").textContent = "";
        $("histNote").textContent = "";
        $("scatter").textContent = "";
        $("scatterNote").textContent = "";
        return;
    }
    const averaged = focus.bin > 1 ? `the ${focus.bin} s averages of the chart` : "the samples of the chart";
    const mean = drawHistogram($("hist"), { values: focus.points.map((p) => p.v), egu: focus.egu });
    $("histNote").textContent = mean === null ? "" : `${focus.name}: ${averaged}; the line is the mean, ${formatValue(mean, focus.egu)}.`;
    if (list.length < 2) {
        $("scatter").textContent = "Select a second PV of the same unit to compare two PVs.";
        $("scatterNote").textContent = "";
        return;
    }
    const other = list.find((d) => d !== focus);
    const correlation = drawScatter($("scatter"), { x: focus, y: other });
    $("scatterNote").textContent = correlation === null ? "" : `${focus.name} across, ${other.name} up. Correlation ${correlation.toFixed(2)}.`;
}

function renderStats(list) {
    const body = $("stats").querySelector("tbody");
    body.textContent = "";
    for (const d of list) {
        const values = d.points.map((p) => p.v);
        const mean = values.reduce((a, b) => a + b, 0) / values.length;
        const deviation = Math.sqrt(values.reduce((a, b) => a + (b - mean) ** 2, 0) / values.length);
        const cells = [d.name, String(values.length), formatValue(Math.min(...values), ""), formatValue(mean, ""), formatValue(Math.max(...values), ""), formatValue(deviation, ""), formatValue(values[values.length - 1], "")];
        body.append(node("tr", null, ...cells.map((text, i) => node("td", { class: i === 0 ? "pv" : "num" }, text))));
    }
}

function renderDetail() {
    const host = $("detail");
    host.textContent = "";
    const name = state.focus;
    if (!name) {
        host.append(node("p", { class: "muted" }, "Select a PV to see its state and the actions that apply."));
        return;
    }
    const row = state.status.get(name);
    const word = stateOf(name) || "Reading state…";
    const left = node("div");
    left.append(node("p", { class: `status-big ${word === "Disconnected" ? "warn" : ""}` }, word));
    left.append(node("p", { class: "pv" }, name));
    left.append(node("p", { class: "muted explain" }, STATES[word] || "State reported by the archiver."));
    if (row) {
        const facts = node("dl", { class: "facts" });
        const add = (label, value) => {
            if (value !== undefined && value !== null && value !== "") {
                facts.append(node("dt", null, label), node("dd", { class: "num" }, String(value)));
            }
        };
        add("Appliance", row.appliance);
        add("Connected", row.connectionState);
        add("Sampling", row.isMonitored === "true" || row.isMonitored === true ? `monitored, period ${row.samplingPeriod}` : row.samplingPeriod);
        add("Last event", row.lastEvent);
        left.append(facts);
    }
    const actions = node("div", { class: "actions" });
    const paused = word === "Paused";
    const archived = word !== "Not being archived";
    const add = (label, handler, className) => {
        const button = node("button", { type: "button", class: className }, label);
        button.addEventListener("click", handler);
        actions.append(button);
    };
    if (!row) {
        // No action is offered before the archiver has told the state.
    } else if (PENDING.has(word)) {
        add("Abort the request", () => doAction("../bpl/abortArchivingPV", name), "danger");
    } else if (archived) {
        add(paused ? "Resume" : "Pause", () => doAction(paused ? "../bpl/resumeArchivingPV" : "../bpl/pauseArchivingPV", name));
        add("Change sampling…", () => openChangeSampling(name));
        add("Stop archiving…", () => openStopDialog(name), "danger");
    } else {
        add("Archive…", () => openArchiveDialog([name]));
    }
    left.append(actions);
    const viewer = viewerHref([name]);
    if (viewer && archived) {
        left.append(node("a", { class: "plain-link", href: viewer }, "Open in the viewer"));
    }
    if (row && archived && !PENDING.has(word)) {
        left.append(maintenanceSection(name), detailsSection(name));
    }

    const right = node("div");
    right.append(node("h2", null, "What the states mean"));
    const glossary = node("dl", { class: "glossary" });
    for (const [key, text] of Object.entries(STATES)) {
        glossary.append(node("dt", null, key), node("dd", null, text));
    }
    right.append(glossary);
    host.append(left, right);
}

async function doAction(kind, name, params) {
    fastUntil = Date.now() + AFTER_ACTION_MS;
    try {
        await api.pvAction(kind, name, params);
        state.status.delete(name);
        refreshStatus();
        renderDetail();
        return true;
    } catch (error) {
        $("limitNote").textContent = `${kind.split("/").pop()} failed for ${name}: ${error.message}`;
        // An action can change part of the state before it fails; show what the archiver holds now.
        state.status.delete(name);
        refreshStatus();
        renderDetail();
        return false;
    }
}

// ---- dialogs -------------------------------------------------------------------------------

function openArchiveDialog(names) {
    const dialog = $("archiveDialog");
    $("archiveNames").textContent = names.join(", ");
    $("archivePeriod").min = String(state.minimumSamplingPeriod);
    $("archivePeriod").value = "1";
    $("archiveError").textContent = "";
    $("archiveForm").onsubmit = async (event) => {
        event.preventDefault();
        const items = names.map((pv) => ({
            pv,
            samplingperiod: $("archivePeriod").value,
            samplingmethod: $("archiveMethod").value,
        }));
        try {
            await api.archivePVs(items);
            dialog.close();
            let refused = 0;
            for (const name of names) {
                if (state.selected.includes(name)) {
                    continue;
                }
                if (state.selected.length < LIMITS.scan) {
                    state.selected.push(name);
                } else {
                    refused += 1;
                }
            }
            state.focus = state.selected.includes(names[0]) ? names[0] : state.focus;
            if (refused) {
                $("limitNote").textContent = `The scan list holds at most ${LIMITS.scan} PVs; ${refused} archived PV${refused > 1 ? "s were" : " was"} not added to it.`;
            }
            afterSelection();
        } catch (error) {
            $("archiveError").textContent = `The archive request failed: ${error.message}`;
        }
    };
    dialog.showModal();
}

function openStopDialog(name) {
    const dialog = $("stopDialog");
    $("stopName").textContent = name;
    $("stopDeleteData").checked = false;
    $("stopForm").onsubmit = async (event) => {
        event.preventDefault();
        dialog.close();
        // The archiver removes only a paused PV, so a running one is paused first.
        const paused = stateOf(name) === "Paused" || (await doAction("../bpl/pauseArchivingPV", name));
        if (!paused || !(await doAction("../bpl/deletePV", name, { deleteData: String($("stopDeleteData").checked) }))) {
            return;
        }
        state.selected = state.selected.filter((n) => n !== name);
        state.focus = state.selected[0] || null;
        afterSelection();
        refreshNames(true);
    };
    dialog.showModal();
}

// ---- maintenance of one PV and actions on several --------------------------------------------

const TYPES = [
    ["DBR_SCALAR_STRING", "string"],
    ["DBR_SCALAR_SHORT", "short"],
    ["DBR_SCALAR_FLOAT", "float"],
    ["DBR_SCALAR_ENUM", "enum"],
    ["DBR_SCALAR_BYTE", "byte"],
    ["DBR_SCALAR_INT", "int"],
    ["DBR_SCALAR_DOUBLE", "double"],
    ["DBR_WAVEFORM_STRING", "waveform of string"],
    ["DBR_WAVEFORM_SHORT", "waveform of short"],
    ["DBR_WAVEFORM_FLOAT", "waveform of float"],
    ["DBR_WAVEFORM_ENUM", "waveform of enum"],
    ["DBR_WAVEFORM_BYTE", "waveform of byte"],
    ["DBR_WAVEFORM_INT", "waveform of int"],
    ["DBR_WAVEFORM_DOUBLE", "waveform of double"],
];

function say(text) {
    $("actionNote").textContent = text;
}

/**
 * One dialog serves every maintenance operation. config: {title, name, text, fields: [{id, label, options | type,
 * value, min, step}], ack, submit, danger, run(values) -> message}. run throws to refuse; its message is shown
 * under the list on success.
 */
function openMaintain(config) {
    const dialog = $("maintainDialog");
    $("maintainTitle").textContent = config.title;
    $("maintainName").textContent = config.name || "";
    $("maintainText").textContent = config.text || "";
    $("maintainError").textContent = "";
    const fields = $("maintainFields");
    fields.textContent = "";
    for (const field of config.fields || []) {
        const id = `maintain-${field.id}`;
        let control;
        if (field.options) {
            control = node("select", { id });
            for (const [value, text] of field.options) {
                control.append(node("option", { value }, text));
            }
            control.value = field.value ?? field.options[0][0];
        } else {
            control = node("input", {
                id,
                type: field.type || "text",
                value: field.value ?? "",
                min: field.min,
                step: field.step,
                required: "required",
                autocomplete: "off",
                spellcheck: "false",
            });
        }
        fields.append(node("label", { for: id }, field.label), control);
    }
    $("maintainAckRow").hidden = !config.ack;
    $("maintainAck").checked = false;
    $("maintainAck").required = Boolean(config.ack);
    $("maintainAckText").textContent = config.ack || "";
    const submit = $("maintainSubmit");
    submit.textContent = config.submit || "Apply";
    submit.className = config.danger ? "danger" : "";
    $("maintainForm").onsubmit = async (event) => {
        event.preventDefault();
        $("maintainError").textContent = "";
        const values = {};
        for (const field of config.fields || []) {
            values[field.id] = document.getElementById(`maintain-${field.id}`).value.trim();
        }
        submit.disabled = true;
        try {
            const message = await config.run(values);
            dialog.close();
            say(message || "");
        } catch (error) {
            $("maintainError").textContent = error.message;
        } finally {
            submit.disabled = false;
        }
    };
    dialog.showModal();
}

/** Pauses a running PV before an operation that needs it; says whether it did. */
async function pauseFor(name) {
    if (stateOf(name) === "Paused") {
        return false;
    }
    await api.pvAction("../bpl/pauseArchivingPV", name);
    return true;
}

/** Runs an operation that needs a paused PV. When it fails after the pause, the message says the PV stays paused. */
async function whilePaused(name, operation) {
    const didPause = await pauseFor(name);
    try {
        return await operation();
    } catch (error) {
        afterOperation(name);
        throw new Error(didPause ? `${error.message} The PV was paused for this and is still paused: resume it if you stop here.` : error.message);
    }
}

function afterOperation(name) {
    fastUntil = Date.now() + AFTER_ACTION_MS;
    state.status.delete(name);
    refreshStatus();
    renderDetail();
}

async function openChangeSampling(name) {
    let info;
    try {
        info = await api.typeInfo(name);
    } catch (error) {
        say(`The settings of ${name} could not be read: ${error.message}`);
        return;
    }
    openMaintain({
        title: "Change sampling",
        name,
        text: "The new method and period apply at once to a running PV. The stored data does not change.",
        fields: [
            { id: "method", label: "Sampling method", options: [["MONITOR", "Monitor: store each change"], ["SCAN", "Scan: store at a fixed period"]], value: info.samplingMethod },
            { id: "period", label: "Sampling period in seconds", type: "number", min: String(state.minimumSamplingPeriod), step: "any", value: info.samplingPeriod },
        ],
        submit: "Change",
        run: async (values) => {
            if (Number(values.period) < state.minimumSamplingPeriod) {
                throw new Error(`The period must be at least ${state.minimumSamplingPeriod} s.`);
            }
            await api.operate("../bpl/changeArchivalParameters", { pv: name, samplingperiod: values.period, samplingmethod: values.method });
            afterOperation(name);
            return `${name} is sampled by ${values.method} with a period of ${values.period} s.`;
        },
    });
}

function openRename(name) {
    openMaintain({
        title: "Rename",
        name,
        text: "The settings and the data are copied to the new name. The PV is paused, and both names stay paused. Check the data of the new name, resume it, and then stop the old one.",
        fields: [{ id: "newname", label: "New name", value: name }],
        submit: "Rename",
        run: async (values) => {
            if (!PV_NAME.test(values.newname) || values.newname === name) {
                throw new Error("Give a different name made of letters, digits and : _ - + [ ] ; / , # { } ^ < >, with an optional .FIELD.");
            }
            await whilePaused(name, () => api.operate("../bpl/renamePV", { pv: name, newname: values.newname }));
            state.selected = state.selected.map((pv) => (pv === name ? values.newname : pv));
            state.focus = values.newname;
            state.status.delete(name);
            afterSelection();
            refreshNames(true);
            return `${values.newname} holds the data of ${name}. Both are paused: check the new one, resume it, then stop ${name}.`;
        },
    });
}

function openChangeType(name) {
    openMaintain({
        title: "Change the type",
        name,
        text: "The stored data of every store is converted to the new type, so it is changed in place and cannot be undone. The PV is paused first and stays paused. Consolidate the data into one store first for the best result.",
        fields: [{ id: "newtype", label: "New type", options: TYPES }],
        ack: "I have a backup of the data of this PV.",
        submit: "Change the type",
        danger: true,
        run: async (values) => {
            await whilePaused(name, () => api.operate("../bpl/changeTypeForPV", { pv: name, newtype: values.newtype }));
            afterOperation(name);
            return `${name} is stored as ${values.newtype}. It is paused: resume it when the data is checked.`;
        },
    });
}

async function openConsolidate(name) {
    let stores;
    try {
        const info = await api.typeInfo(name);
        stores = (info.dataStores || []).map((url) => /name=([A-Za-z0-9_]+)/.exec(url)).filter(Boolean).map((match) => match[1]);
    } catch (error) {
        say(`The settings of ${name} could not be read: ${error.message}`);
        return;
    }
    if (!stores.length) {
        say(`${name} has no store to consolidate into.`);
        return;
    }
    openMaintain({
        title: "Consolidate the data",
        name,
        text: "The data of the earlier stores is moved up to the chosen store, so one store holds it. The PV is paused first and stays paused.",
        fields: [{ id: "storage", label: "Consolidate into", options: stores.map((store) => [store, store]), value: stores[stores.length - 1] }],
        submit: "Consolidate",
        run: async (values) => {
            await whilePaused(name, () => api.operate("../bpl/consolidateDataForPV", { pv: name, storage: values.storage }));
            afterOperation(name);
            return `The data of ${name} was consolidated into ${values.storage}. It is paused: resume it when you are ready.`;
        },
    });
}

function maintenanceSection(name) {
    const section = node("details", { class: "maintenance" }, node("summary", null, "Maintenance"));
    section.append(node("p", { class: "sub" }, "These change the PV or its data. Each says what it does before it asks."));
    const buttons = node("div", { class: "actions" });
    for (const [label, handler] of [
        ["Rename…", openRename],
        ["Change type…", openChangeType],
        ["Consolidate data…", openConsolidate],
    ]) {
        const button = node("button", { type: "button", class: "plain" }, label);
        button.addEventListener("click", () => handler(name));
        buttons.append(button);
    }
    section.append(buttons);
    return section;
}

/** Everything the archiver reports about one PV, read when the section is opened. */
function detailsSection(name) {
    const section = node("details", { class: "maintenance" }, node("summary", null, "All details"));
    const body = node("div");
    section.append(body);
    let loaded = false;
    section.addEventListener("toggle", async () => {
        if (!section.open || loaded) {
            return;
        }
        loaded = true;
        body.textContent = "Reading…";
        try {
            const rows = await api.details(name);
            const list = node("dl", { class: "facts all" });
            for (const row of rows) {
                list.append(node("dt", null, String(row.name)), node("dd", { class: "num" }, String(row.value)));
            }
            body.replaceChildren(list);
        } catch (error) {
            loaded = false;
            body.textContent = `The details could not be read: ${error.message}`;
        }
    });
    return section;
}

/** One sentence for the per-PV answers of a bulk call. A PV that was already in the wanted state is no failure. */
function summarizeBulk(rows, verb) {
    const unchanged = (row) => /already paused|is not paused/i.test(String(row.validation || ""));
    const done = rows.filter((row) => row.status === "ok").length;
    const same = rows.filter(unchanged).length;
    const failed = rows.filter((row) => row.status !== "ok" && !unchanged(row));
    const parts = [`${done} PV${done === 1 ? "" : "s"} ${verb}`];
    if (same) {
        parts.push(`${same} already in that state`);
    }
    if (failed.length) {
        const reason = failed[0].validation || failed[0].engine_validation || failed[0].etl_validation || "no reason given";
        parts.push(`${failed.length} failed (first: ${failed[0].pvName}: ${reason})`);
    }
    return `${parts.join(", ")}.`;
}

function bulkAction(kind) {
    const names = state.selected.slice();
    const count = names.length;
    const plural = `${count} PV${count === 1 ? "" : "s"}`;
    if (kind === "pause" || kind === "resume") {
        openMaintain({
            title: `${kind === "pause" ? "Pause" : "Resume"} ${plural}`,
            name: count > 3 ? `${names.slice(0, 3).join(", ")} and ${count - 3} more` : names.join(", "),
            text: kind === "pause" ? "The archiver stops sampling these PVs and keeps their data." : "The archiver samples these PVs again.",
            submit: kind === "pause" ? "Pause" : "Resume",
            run: async () => {
                const rows = await api.bulk(kind === "pause" ? "../bpl/pauseArchivingPV" : "../bpl/resumeArchivingPV", names);
                state.status.clear();
                afterSelection();
                return summarizeBulk(rows, kind === "pause" ? "paused" : "resumed");
            },
        });
        return;
    }
    openMaintain({
        title: `Stop archiving ${plural}`,
        name: count > 3 ? `${names.slice(0, 3).join(", ")} and ${count - 3} more` : names.join(", "),
        text: "The PVs are paused and then removed from the archiver. The stored data stays unless you also delete it.",
        fields: [{ id: "data", label: "Stored data", options: [["false", "Keep the stored data"], ["true", "Delete the stored data"]] }],
        submit: "Stop archiving",
        danger: true,
        run: async (values) => {
            await api.bulk("../bpl/pauseArchivingPV", names);
            const rows = await api.bulk("../bpl/deletePV", names, { deleteData: values.data });
            const removed = new Set(rows.filter((row) => row.status === "ok").map((row) => row.pvName));
            state.selected = state.selected.filter((pv) => !removed.has(pv));
            state.focus = state.selected[0] || null;
            afterSelection();
            refreshNames(true);
            return summarizeBulk(rows, "removed");
        },
    });
}

// ---- address state -------------------------------------------------------------------------

function writeAddress() {
    const parameters = new URLSearchParams();
    if (state.query) {
        parameters.set("q", state.query);
    }
    if (state.mode !== "contains") {
        parameters.set("mode", state.mode);
    }
    if (state.rangeMinutes !== 60) {
        parameters.set("range", String(state.rangeMinutes));
    }
    if (state.report) {
        parameters.set("report", state.report);
    }
    if (state.window) {
        parameters.set("from", String(state.window.from.getTime()));
        parameters.set("to", String(state.window.to.getTime()));
    }
    for (const name of state.selected) {
        parameters.append("pv", name);
    }
    const text = parameters.toString();
    window.history.replaceState(null, "", text ? `#${text}` : window.location.pathname);
}

function readAddress() {
    const parameters = new URLSearchParams(window.location.hash.slice(1));
    state.query = parameters.get("q") || "";
    state.mode = parameters.get("mode") || "contains";
    state.rangeMinutes = Number(parameters.get("range")) || 60;
    const from = Number(parameters.get("from"));
    const to = Number(parameters.get("to"));
    state.window = from > 0 && to > from ? { from: new Date(from), to: new Date(to) } : null;
    const named = parameters.getAll("pv");
    state.selected = named.slice(0, LIMITS.scan);
    if (named.length > LIMITS.scan) {
        addressNote = `The address names ${named.length} PVs; the scan list holds at most ${LIMITS.scan}, so the first ${LIMITS.scan} are shown.`;
    }
    state.focus = state.selected[0] || null;
    $("q").value = state.query;
    pendingReport = REPORTS[parameters.get("report")] ? parameters.get("report") : null;
}

// ---- start ---------------------------------------------------------------------------------

function wire() {
    let debounce = 0;
    $("q").addEventListener("input", (event) => {
        state.query = event.target.value;
        window.clearTimeout(debounce);
        debounce = window.setTimeout(runSearch, 150);
    });
    document.querySelectorAll("#modes button").forEach((button) => {
        button.setAttribute("aria-pressed", String(button.dataset.mode === state.mode));
        button.addEventListener("click", () => {
            state.mode = button.dataset.mode;
            document.querySelectorAll("#modes button").forEach((other) => other.setAttribute("aria-pressed", String(other === button)));
            runSearch();
        });
    });
    document.querySelectorAll("#ranges button").forEach((button) => {
        button.setAttribute("aria-pressed", String(Number(button.dataset.minutes) === state.rangeMinutes));
        button.addEventListener("click", () => {
            state.rangeMinutes = Number(button.dataset.minutes);
            state.window = null;
            document.querySelectorAll("#ranges button").forEach((other) => other.setAttribute("aria-pressed", String(other === button)));
            state.data.clear();
            refreshData();
            writeAddress();
        });
    });
    $("report").addEventListener("change", (event) => setReport(event.target.value));
    $("results").addEventListener("scroll", renderResults);
    $("results").addEventListener("keydown", moveInResults);
    $("results").addEventListener("focus", () => {
        $("results").setAttribute("aria-activedescendant", `row-${state.active}`);
    });
    $("panEarlier").addEventListener("click", () => panBy(-1));
    $("panLater").addEventListener("click", () => panBy(1));
    $("zoomReset").addEventListener("click", () => {
        state.window = null;
        state.data.clear();
        refreshData();
        writeAddress();
        renderChart();
    });
    $("bulkPause").addEventListener("click", () => bulkAction("pause"));
    $("bulkResume").addEventListener("click", () => bulkAction("resume"));
    $("bulkStop").addEventListener("click", () => bulkAction("stop"));
    $("maintainCancel").addEventListener("click", () => $("maintainDialog").close());
    $("archiveCancel").addEventListener("click", () => $("archiveDialog").close());
    $("stopCancel").addEventListener("click", () => $("stopDialog").close());
    let resize = 0;
    window.addEventListener("resize", () => {
        window.clearTimeout(resize);
        resize = window.setTimeout(() => {
            renderChart();
            renderResults();
        }, 120);
    });
}

async function readMinimumSamplingPeriod() {
    try {
        const value = Number((await api.applianceProperties()).minimum_sampling_period);
        if (Number.isFinite(value) && value > 0) {
            state.minimumSamplingPeriod = value;
        }
    } catch (error) {
        // The default stays.
    }
}

readAddress();
$("limitNote").textContent = addressNote;
wire();
renderFinder();
renderScan();
renderChart();
renderDetail();
readMinimumSamplingPeriod();
startNames();
api.applianceInfo().then((info) => {
    state.retrievalBase = String(info.dataRetrievalURL || "");
    renderScan();
    renderDetail();
}).catch(() => {
    // Without the address the links to the viewer stay hidden.
});
namesLoaded.then(async () => {
    if (pendingReport) {
        $("report").value = pendingReport;
        await setReport(pendingReport);
    }
    if (state.selected.length) {
        afterSelection();
    }
});
