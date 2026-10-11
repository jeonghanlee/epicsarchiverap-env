// Server access for the Work page. Every call is a plain request to an endpoint that already exists.
let infoPromise = null;

async function request(url, init) {
    const response = await fetch(url, init);
    if (!response.ok) {
        throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    return response.json();
}

export function applianceInfo() {
    if (!infoPromise) {
        infoPromise = request("../bpl/getApplianceInfo");
    }
    return infoPromise;
}

/** The rows of one of the report endpoints, for example getCurrentlyDisconnectedPVs, in the order of the server. */
export function reportRows(endpoint, params) {
    const query = params ? `?${new URLSearchParams(params)}` : "";
    return request(`${endpoint}${query}`);
}

export function pvStatus(names) {
    return request("../bpl/getPVStatus?reporttype=short", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(names.map((pv) => ({ pv }))),
    });
}

/** pauseArchivingPV, resumeArchivingPV or deletePV for one PV; kind is the call path, for example "../bpl/deletePV". */
export async function pvAction(kind, pv, params = {}) {
    const query = new URLSearchParams({ pv, ...params });
    const result = await request(`${kind}?${query}`);
    if (result.status !== "ok") {
        const reason = [result.validation, result.engine_validation, result.etl_validation].filter(Boolean).join("; ");
        throw new Error(reason || `${kind.split("/").pop()} did not answer ok`);
    }
}

/** items: [{pv, samplingperiod?, samplingmethod?}] */
export function archivePVs(items) {
    return request("../bpl/archivePV", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(items),
    });
}

/** True when the archiver recorded a lost connection or an engine start before this sample (also in a reduced bin). */
function connectionLost(sample) {
    const fields = sample.fields;
    return Boolean(fields && (Number(fields.cnxlostepsecs) > 0 || fields.startup === "true" || fields.connectionChange === "true"));
}

/**
 * Samples of one PV between two dates, reduced by the server to about one value per binSeconds. An interval
 * without a sample gives no value (meanSample, not mean, which fills it with the previous value).
 * Returns {name, egu, waveform, points: [{t, v, s, g}]} with t in milliseconds; g marks a connection loss before the sample.
 */
export async function series(pv, from, to, binSeconds, signal) {
    const info = await applianceInfo();
    const operator = binSeconds > 1 ? `meanSample_${binSeconds}(${pv})` : pv;
    const query = new URLSearchParams({ pv: operator, from: from.toISOString(), to: to.toISOString() });
    const body = await request(`${info.dataRetrievalURL}/data/getData.json?${query}`, { signal });
    const first = body[0];
    if (!first) {
        return { name: pv, egu: "", waveform: false, points: [] };
    }
    const points = [];
    for (const sample of first.data) {
        if (typeof sample.val === "number") {
            points.push({
                t: sample.secs * 1000 + Math.floor((sample.nanos || 0) / 1e6),
                v: sample.val,
                s: sample.severity || 0,
                g: connectionLost(sample),
            });
        }
    }
    return {
        name: first.meta?.name ?? pv,
        egu: first.meta?.EGU ?? "",
        waveform: Boolean(first.meta?.waveform),
        points,
    };
}

/** The reason a result gives for a refusal, or null when the result carries none. */
function refusal(result) {
    if (!result || typeof result !== "object") {
        return null;
    }
    const reasons = Object.entries(result)
        .filter(([key, value]) => /validation/i.test(key) && typeof value === "string" && value)
        .map(([, value]) => value);
    if (reasons.length) {
        return reasons.join("; ");
    }
    if ("status" in result && result.status !== "ok") {
        return String(result.status);
    }
    return null;
}

/**
 * One operation on one PV. A call may answer with an empty body when the PV is paused and only its settings changed;
 * that is a success. A refusal is thrown with the reason the server gave.
 */
export async function operate(kind, params) {
    const response = await fetch(`${kind}?${new URLSearchParams(params)}`);
    if (!response.ok) {
        throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    const text = (await response.text()).trim();
    if (!text) {
        return {};
    }
    const result = JSON.parse(text);
    const reason = refusal(result);
    if (reason) {
        throw new Error(reason);
    }
    return result;
}

/** pauseArchivingPV, resumeArchivingPV or deletePV for several PVs in one call. Returns one entry per PV. */
export async function bulk(kind, names, params = {}) {
    const query = Object.keys(params).length ? `?${new URLSearchParams(params)}` : "";
    const response = await fetch(`${kind}${query}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(names),
    });
    if (!response.ok) {
        throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    const result = await response.json();
    return Array.isArray(result) ? result : [result];
}

/** The properties of the appliance, among them minimum_sampling_period. */
export function applianceProperties() {
    return request("../bpl/getApplianceProperties");
}

/** The settings of a PV: sampling, stores, type, whether it is paused. */
export function typeInfo(pv) {
    return request(`../bpl/getPVTypeInfo?${new URLSearchParams({ pv })}`);
}

/** The full list of what the archiver knows about a PV: [{name, value, source}]. */
export function details(pv) {
    return request(`../bpl/getPVDetails?${new URLSearchParams({ pv })}`);
}
