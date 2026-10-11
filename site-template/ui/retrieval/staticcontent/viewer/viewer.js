// The archived data viewer. The address keeps the parameters of the previous viewer:
// pv (repeatable), from and to (ISO 8601). Data comes from this retrieval server only.
import { drawTimeSeries } from "../comm/js/aa/chart.js";

const DATA = "../../data/getData.json";
const MATCHING = "../../bpl/getMatchingPVs";
const SERIES_PER_CHART = 8;
const CONCURRENT_REQUESTS = 6;
// A name as the server reads it: the base name, then an optional field (X:Y.RBV).
const PV_NAME = /^[a-zA-Z0-9:_\-+[\];/,#{}^<>]+(\.[a-zA-Z_][a-zA-Z0-9_]*)?$/;

const state = { pvs: [], from: null, to: null, data: new Map(), failures: new Map() };
const $ = (id) => document.getElementById(id);

function node(tag, attributes, ...children) {
    const element = document.createElement(tag);
    for (const [key, value] of Object.entries(attributes || {})) {
        if (value !== undefined && value !== null) {
            element.setAttribute(key, value);
        }
    }
    element.append(...children);
    return element;
}

function parseDate(text) {
    // new Date(null) is the year 1970, so a missing parameter must not reach the constructor.
    if (!text) {
        return null;
    }
    const date = new Date(text);
    return Number.isNaN(date.getTime()) ? null : date;
}

function localInput(date) {
    const pad = (n) => String(n).padStart(2, "0");
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

function readAddress() {
    const parameters = new URLSearchParams(window.location.search);
    state.pvs = [...new Set(parameters.getAll("pv").map((name) => name.trim()).filter((name) => PV_NAME.test(name)))];
    const to = parseDate(parameters.get("to")) || new Date();
    const from = parseDate(parameters.get("from")) || new Date(to.getTime() - 3600000);
    state.from = from;
    state.to = to;
}

function writeAddress() {
    const parameters = new URLSearchParams();
    for (const name of state.pvs) {
        parameters.append("pv", name);
    }
    parameters.set("from", state.from.toISOString());
    parameters.set("to", state.to.toISOString());
    window.history.replaceState(null, "", `${window.location.pathname}?${parameters}`);
}

async function fetchSeries(name, from, to, bin, signal) {
    // meanSample is the mean that does not fill an interval without samples with the previous value, so a period
    // without data (a lost connection) has no value and the line stops.
    const operator = bin > 1 ? `meanSample_${bin}(${name})` : name;
    const query = new URLSearchParams({ pv: operator, from: from.toISOString(), to: to.toISOString() });
    const response = await fetch(`${DATA}?${query}`, { signal });
    if (!response.ok) {
        throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    const body = await response.json();
    const first = body[0];
    if (!first) {
        return { name, egu: "", points: [] };
    }
    const points = [];
    for (const sample of first.data) {
        if (typeof sample.val === "number") {
            const fields = sample.fields;
            const lost = Boolean(fields && (Number(fields.cnxlostepsecs) > 0 || fields.startup === "true" || fields.connectionChange === "true"));
            points.push({ t: sample.secs * 1000 + Math.floor((sample.nanos || 0) / 1e6), v: sample.val, s: sample.severity || 0, g: lost });
        }
    }
    return { name: first.meta?.name ?? name, egu: first.meta?.EGU ?? "", waveform: Boolean(first.meta?.waveform), points };
}

let controller = null;
async function load() {
    if (controller) {
        controller.abort();
    }
    controller = new AbortController();
    const { signal } = controller;
    const { from, to } = state;
    const bin = Math.max(1, Math.ceil((to - from) / 1000 / 700));
    state.data.clear();
    state.failures.clear();
    render();
    let next = 0;
    const pump = async () => {
        while (next < state.pvs.length && !signal.aborted) {
            const name = state.pvs[next];
            next += 1;
            try {
                state.data.set(name, { ...(await fetchSeries(name, from, to, bin, signal)), bin });
            } catch (error) {
                if (error.name !== "AbortError") {
                    state.failures.set(name, String(error.message || error));
                }
            }
            if (!signal.aborted) {
                render();
            }
        }
    };
    await Promise.all(Array.from({ length: CONCURRENT_REQUESTS }, pump));
}

function render() {
    $("fromTime").value = localInput(state.from);
    $("toTime").value = localInput(state.to);
    document.querySelectorAll("#ranges button").forEach((button) => {
        const span = (state.to - state.from) / 60000;
        button.setAttribute("aria-pressed", String(Math.abs(span - Number(button.dataset.minutes)) < 0.5));
    });

    const chips = $("chips");
    chips.textContent = "";
    for (const name of state.pvs) {
        const remove = node("button", { type: "button", class: "plain", "aria-label": `Remove ${name}` }, "remove");
        remove.addEventListener("click", () => {
            state.pvs = state.pvs.filter((other) => other !== name);
            state.data.delete(name);
            writeAddress();
            render();
        });
        const failure = state.failures.get(name);
        const item = node("li", null, node("span", { class: "pv" }, name), " ", failure ? node("span", { class: "warn" }, `no data: ${failure}`) : "", remove);
        chips.append(item);
    }

    const message = $("message");
    const charts = $("charts");
    charts.textContent = "";
    if (!state.pvs.length) {
        message.textContent = "Add a PV name to see its archived data.";
        return;
    }
    const loaded = state.pvs.map((name) => state.data.get(name)).filter(Boolean);
    const failed = state.pvs.filter((name) => state.failures.has(name)).length;
    const waiting = state.pvs.length - loaded.length - failed;
    message.textContent = waiting > 0 ? `Loading ${waiting} of ${state.pvs.length}…` : failed ? `${failed} of ${state.pvs.length} could not be read.` : "";

    // One chart per unit, so values of different units never share an axis.
    const groups = new Map();
    for (const series of loaded) {
        const key = series.egu || "no unit";
        if (!groups.has(key)) {
            groups.set(key, []);
        }
        groups.get(key).push(series);
    }
    for (const [unit, list] of groups) {
        const drawn = list.slice(0, SERIES_PER_CHART);
        const section = node("section", { class: "unit" });
        section.append(node("h2", null, `${unit} · ${list.length} PV${list.length > 1 ? "s" : ""}`));
        if (list.length > drawn.length) {
            section.append(node("p", { class: "sub" }, `${list.length - drawn.length} more than the limit of ${SERIES_PER_CHART} are listed but not drawn.`));
        }
        const reduced = drawn[0].bin > 1 ? drawn[0].bin : 0;
        if (reduced) {
            section.append(node("p", { class: "sub" }, `Values are means over ${reduced} s; an interval without a sample has no value. A range of 11 minutes or less shows the stored samples.`));
        }
        const host = node("div", { class: "chart" });
        section.append(host);
        charts.append(section);
        drawTimeSeries(host, {
            series: drawn.map((series, index) => ({ name: series.name, egu: series.egu, points: series.points, focus: index === 0 })),
            from: state.from,
            to: state.to,
            gapMs: Infinity,
        });
    }
}

function csv() {
    // interval_seconds is 1 for a stored sample and N for the mean over N seconds.
    const rows = ["pv,time,value,severity,interval_seconds"];
    for (const name of state.pvs) {
        const series = state.data.get(name);
        for (const point of series ? series.points : []) {
            rows.push(`${JSON.stringify(name)},${new Date(point.t).toISOString()},${point.v},${point.s},${series.bin}`);
        }
    }
    return rows.join("\n");
}

async function suggest(text) {
    const term = text.trim();
    const list = $("suggestions");
    list.textContent = "";
    if (term.length < 2) {
        return;
    }
    try {
        const query = new URLSearchParams({ pv: `*${term}*`, limit: "20" });
        const response = await fetch(`${MATCHING}?${query}`);
        if (response.ok) {
            for (const name of await response.json()) {
                list.append(node("option", { value: name }));
            }
        }
    } catch (error) {
        // Suggestions are optional.
    }
}

function wire() {
    let timer = 0;
    $("pvName").addEventListener("input", (event) => {
        window.clearTimeout(timer);
        timer = window.setTimeout(() => suggest(event.target.value), 200);
    });
    $("addForm").addEventListener("submit", (event) => {
        event.preventDefault();
        const name = $("pvName").value.trim();
        if (PV_NAME.test(name) && !state.pvs.includes(name)) {
            state.pvs.push(name);
            $("pvName").value = "";
            writeAddress();
            load();
        } else if (name) {
            $("message").textContent = PV_NAME.test(name) ? "This PV is already shown." : "This is not a valid PV name.";
        }
    });
    document.querySelectorAll("#ranges button").forEach((button) => {
        button.addEventListener("click", () => {
            state.to = new Date();
            state.from = new Date(state.to.getTime() - Number(button.dataset.minutes) * 60000);
            writeAddress();
            load();
        });
    });
    $("spanForm").addEventListener("submit", (event) => {
        event.preventDefault();
        const from = parseDate($("fromTime").value);
        const to = parseDate($("toTime").value);
        if (from && to && from < to) {
            state.from = from;
            state.to = to;
            writeAddress();
            load();
        } else {
            $("message").textContent = "The start must be before the end.";
        }
    });
    $("copyLink").addEventListener("click", async () => {
        try {
            await navigator.clipboard.writeText(window.location.href);
            $("message").textContent = "Link copied.";
        } catch (error) {
            $("message").textContent = "The browser did not allow copying; the address bar holds the link.";
        }
    });
    $("downloadCsv").addEventListener("click", () => {
        const link = node("a", { href: URL.createObjectURL(new Blob([csv()], { type: "text/csv" })), download: "archived-data.csv" });
        document.body.append(link);
        link.click();
        link.remove();
    });
    let resize = 0;
    window.addEventListener("resize", () => {
        window.clearTimeout(resize);
        resize = window.setTimeout(render, 150);
    });
}

readAddress();
wire();
render();
if (state.pvs.length) {
    load();
}
