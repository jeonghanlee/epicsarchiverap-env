// How the System pages judge what the appliance reports. A judgement is one of ok, warn or bad, with a sentence
// that says what it means. The reasons for each rule are in the work register decision D51; the values below are
// starting values and are shown on the Operations page next to the measure they judge.
import { number, plain } from "./api.js";

export const THRESHOLDS = {
    // Storage: a store fills slowly, so the days left matter first; the free share is a backstop for space that
    // something other than the archiver uses.
    daysLeftAttention: 30,
    daysLeftProblem: 7,
    freeAttentionPercent: 5,
    freeProblemPercent: 3,
    // The share of the write period the engine needs for writing; 100 is the point where samples are lost.
    writeAttentionPercent: 50,
    writeProblemPercent: 100,
    // The lowest heap after a collection: its level and its rise over the day, in points of the maximum heap.
    heapFloorAttention: 70,
    heapFloorProblem: 90,
    heapFloorRiseAttention: 5,
    // A PV disconnected for longer than this is a finding; a shorter loss is often a restart.
    disconnectedSeconds: 3600,
    // PVs of one host that lost their connection within this many seconds of each other are one event.
    lossWindowSeconds: 30,
    // The ETL: a busy share of its interval at or above this is a pass that cannot keep up.
    etlBusyProblemPercent: 200,
};

// "unknown" is a measure the appliance did not report; it is never shown as normal and never outranks a finding.
export const WORDS = { ok: "Normal", warn: "Attention", bad: "Problem", unknown: "Not reported" };
export const MARKS = { ok: "●", warn: "▲", bad: "■", unknown: "○" };
const ORDER = { unknown: -1, ok: 0, warn: 1, bad: 2 };

export function worst(kinds) {
    return kinds.reduce((a, b) => (ORDER[b] > ORDER[a] ? b : a), "ok");
}

// ---- measures -----------------------------------------------------------------------------------

/** getApplianceMetricsForAppliance rows as a map from measure name to value. */
export function measureMap(rows) {
    return new Map((rows || []).map((row) => [plain(row.name), row.value]));
}

export const TIER_NAMES = { "0>1": "STS to MTS", "1>2": "MTS to LTS" };

/** The ETL measures, which repeat per tier, as {tier: {measure: value}}. */
export function etlTiers(map) {
    const tiers = {};
    for (const [name, value] of map) {
        const match = /^(.*?) in ETL\((\d>\d)\)(.*)$/.exec(name);
        if (match) {
            const key = `${match[1]}${match[3]}`.trim();
            (tiers[match[2]] = tiers[match[2]] || {})[key] = value;
        }
    }
    return tiers;
}

// ---- disconnected PVs ---------------------------------------------------------------------------

export function groupByHost(rows) {
    const byHost = new Map();
    for (const row of rows) {
        const host = row.hostName && row.hostName !== "N/A" ? row.hostName : "";
        if (!byHost.has(host)) {
            byHost.set(host, []);
        }
        byHost.get(host).push({
            pv: String(row.pvName),
            lost: Number(row.noConnectionAsOfEpochSecs) || 0,
            lostText: String(row.connectionLostAt || ""),
        });
    }
    const groups = [];
    for (const [host, items] of byHost) {
        items.sort((a, b) => a.lost - b.lost);
        let current = null;
        for (const item of items) {
            if (!current || item.lost - current.last > THRESHOLDS.lossWindowSeconds) {
                current = { host, items: [], first: item.lost, last: item.lost };
                groups.push(current);
            }
            current.items.push(item);
            current.last = item.lost;
        }
    }
    groups.sort((a, b) => b.items.length - a.items.length || a.first - b.first);
    return groups;
}

export function prefixOf(name) {
    const parts = name.split(":");
    return parts.length > 1 ? `${parts[0]}:${parts[1]}` : parts[0];
}

export function judgeConnections(appliance, disconnected, neverConnected) {
    const total = number(appliance.pvCount);
    const connected = number(appliance.connectedPVCount);
    const now = Date.now() / 1000;
    const groups = groupByHost(disconnected || []);
    const old = (disconnected || []).filter((row) => now - (Number(row.noConnectionAsOfEpochSecs) || now) > THRESHOLDS.disconnectedSeconds);
    const never = neverConnected ? neverConnected.length : 0;
    if (total && connected === 0) {
        return { kind: "bad", text: "No PV is connected. No samples are stored.", groups };
    }
    if (old.length) {
        const hosts = new Set(groups.filter((g) => g.items.some((i) => now - i.lost > THRESHOLDS.disconnectedSeconds)).map((g) => g.host || "unknown host"));
        return {
            kind: "warn",
            text: `${old.length} PV${old.length > 1 ? "s" : ""} on ${hosts.size} host${hosts.size > 1 ? "s" : ""} ${old.length > 1 ? "have" : "has"} been disconnected for more than an hour. No samples are stored for them.`,
            groups,
        };
    }
    const recent = (disconnected || []).length;
    return {
        kind: "ok",
        text: recent ? `${recent} PV${recent > 1 ? "s" : ""} lost the connection less than an hour ago.` : never ? `${never} PV${never > 1 ? "s were" : " was"} never connected.` : "",
        groups,
    };
}

// ---- dropped samples ----------------------------------------------------------------------------

export const DROPPED_REPORTS = [
    { endpoint: "../bpl/getPVsByDroppedEventsTimestamp", label: "Timestamp problems", action: "The IOC sends times that go backwards or far into the future: fix the clock of the IOC." },
    { endpoint: "../bpl/getPVsByDroppedEventsBuffer", label: "Buffer overflow", action: "Samples were lost before the engine could write them: slow the PV down or raise the seconds of write delay a buffer absorbs (PVTypeInfo.sampleBufferMarginSeconds in archappl.properties, at least 1.0)." },
    { endpoint: "../bpl/getPVsByDroppedEventsTypeChange", label: "Type change", action: "The IOC changed the type of the record: the PV needs a new archive request." },
    { endpoint: "../bpl/getSlowChangingPVsWithDroppedEvents", label: "Slow-changing PVs with dropped events", action: "A slow PV lost more events than it sent: look at its connection and at the write thread." },
];

export function judgeDropped(reports) {
    const names = new Set();
    let events = 0;
    let unread = 0;
    for (const rows of reports) {
        if (!rows) {
            unread += 1;
            continue;
        }
        for (const row of rows) {
            names.add(row.pvName);
            events += number(row.eventsDropped) || 0;
        }
    }
    if (names.size) {
        return { kind: "bad", pvs: names.size, events, text: `${events.toLocaleString()} sample${events > 1 ? "s were" : " was"} dropped from ${names.size} PV${names.size > 1 ? "s" : ""}. The stored data has holes.` };
    }
    return { kind: "ok", pvs: 0, events: 0, text: unread ? `${unread} of the 4 reports could not be read.` : "" };
}

// ---- write path and ETL -------------------------------------------------------------------------

export function judgeWrite(measures) {
    const usage = number(measures.get("Engine write thread usage"));
    const queue = number(measures.get("Approx pending jobs in engine queue"));
    if (usage === null) {
        return { kind: "unknown", usage, queue, text: "The appliance did not report the write time. It reports it after its first capacity plan." };
    }
    if (usage >= THRESHOLDS.writeProblemPercent) {
        return { kind: "bad", usage, queue, text: `The engine needs ${usage.toFixed(0)} % of its write period to write. It cannot keep up and samples are lost.` };
    }
    if (usage >= THRESHOLDS.writeAttentionPercent) {
        return { kind: "warn", usage, queue, text: `The engine needs ${usage.toFixed(0)} % of its write period to write. Above 100 % samples are lost.` };
    }
    return { kind: "ok", usage, queue, text: "" };
}

export function judgeEtl(tiers) {
    const kinds = [];
    const notes = [];
    let busiest = 0;
    for (const [key, values] of Object.entries(tiers)) {
        const label = TIER_NAMES[key] || key;
        const overran = String(values["Last pass overran the cadence"]).toLowerCase() === "yes";
        const failed = number(values["Last pass jobs failed"]) || 0;
        const late = number(values["Last pass late by (s)"]) || 0;
        const busy = number(values["Last pass busy time as % of cadence"]) || 0;
        busiest = Math.max(busiest, busy);
        if (busy >= THRESHOLDS.etlBusyProblemPercent) {
            kinds.push("bad");
            notes.push(`${label}: the last pass needed ${busy.toFixed(0)} % of its interval.`);
        } else if (overran || late > 0 || failed > 0) {
            kinds.push("warn");
            notes.push(`${label}: ${[overran ? "the last pass overran its interval" : "", late > 0 ? `${late.toFixed(0)} s late` : "", failed > 0 ? `${failed} job${failed > 1 ? "s" : ""} failed` : ""].filter(Boolean).join(", ")}.`);
        }
    }
    if (!Object.keys(tiers).length) {
        return { kind: "unknown", busiest, text: "The appliance reported no ETL measures." };
    }
    return { kind: worst(kinds), busiest, text: notes.join(" ") };
}

// ---- storage ------------------------------------------------------------------------------------

export function daysText(days) {
    if (days === null) {
        return "unknown";
    }
    if (days > 365) {
        return "more than a year";
    }
    return `${days < 10 ? days.toFixed(1) : days.toFixed(0)} days`;
}

/** devices: getStorageMetricsForAppliance rows; bytesPerSecond: the data rate of the appliance. */
export function judgeStorage(devices, bytesPerSecond) {
    const perDay = bytesPerSecond ? bytesPerSecond * 86400 : 0;
    let leastDays = null;
    let leastFree = null;
    for (const device of devices || []) {
        const free = number(device.available_space);
        const percent = number(device.available_space_percent);
        if (free !== null && perDay > 0) {
            const days = (free * 1e9) / perDay;
            leastDays = leastDays === null ? days : Math.min(leastDays, days);
        }
        if (percent !== null) {
            leastFree = leastFree === null ? percent : Math.min(leastFree, percent);
        }
    }
    let kind = "ok";
    let text = "";
    if (leastFree === null && leastDays === null) {
        kind = "unknown";
        text = "The appliance reported no storage device.";
    } else if (leastFree !== null && leastFree < THRESHOLDS.freeProblemPercent) {
        kind = "bad";
        text = `Only ${leastFree.toFixed(1)} % of a device is free.`;
    } else if (leastDays !== null && leastDays < THRESHOLDS.daysLeftProblem) {
        kind = "bad";
        text = `At the current data rate the space is used up in ${daysText(leastDays)}.`;
    } else if (leastFree !== null && leastFree < THRESHOLDS.freeAttentionPercent) {
        kind = "warn";
        text = `Only ${leastFree.toFixed(1)} % of a device is free.`;
    } else if (leastDays !== null && leastDays < THRESHOLDS.daysLeftAttention) {
        kind = "warn";
        text = `At the current data rate the space is used up in ${daysText(leastDays)}.`;
    }
    return { kind, text, days: leastDays, free: leastFree, perDayGB: perDay / 1e9 };
}

// ---- heap ---------------------------------------------------------------------------------------

const WINDOW_MS = 3600000;

/** points: [[epoch milliseconds, percent], ...]. The floor is the lowest value in the last hour. */
export function heapFloor(points) {
    const data = (points || []).map(([t, v]) => [Number(t), Number(v)]).filter(([t, v]) => Number.isFinite(t) && Number.isFinite(v));
    if (data.length < 120) {
        return null;
    }
    const floor = [];
    let start = 0;
    for (let i = 0; i < data.length; i += 1) {
        while (data[i][0] - data[start][0] > WINDOW_MS) {
            start += 1;
        }
        let low = Infinity;
        for (let j = start; j <= i; j += 1) {
            low = Math.min(low, data[j][1]);
        }
        floor.push([data[i][0], low]);
    }
    const block = Math.max(30, Math.floor(data.length / 4));
    const mean = (rows) => rows.reduce((sum, row) => sum + row[1], 0) / rows.length;
    const settled = floor.slice(Math.min(60, data.length - block));
    const first = mean(settled.slice(0, block));
    const last = mean(floor.slice(-block));
    const drops = [];
    for (let i = 1; i < data.length; i += 1) {
        if (data[i - 1][1] - data[i][1] > 10) {
            drops.push(data[i][0]);
        }
    }
    const gaps = drops.slice(1).map((t, i) => (t - drops[i]) / 60000).sort((a, b) => a - b);
    const rhythm = gaps.length >= 2 ? gaps[Math.floor(gaps.length / 2)] : null;
    const now = floor[floor.length - 1][1];
    const rise = last - first;
    let kind = "ok";
    let text = "";
    if (now >= THRESHOLDS.heapFloorProblem) {
        kind = "bad";
        text = `The heap does not drop below ${now.toFixed(0)} % after a collection.`;
    } else if (now >= THRESHOLDS.heapFloorAttention) {
        kind = "warn";
        text = `The heap does not drop below ${now.toFixed(0)} % after a collection.`;
    } else if (rise >= THRESHOLDS.heapFloorRiseAttention) {
        kind = "warn";
        text = `The lowest heap after a collection rose by ${rise.toFixed(0)} points during the day.`;
    }
    return { kind, text, first, last, rise, now, rhythm, floor, data };
}
