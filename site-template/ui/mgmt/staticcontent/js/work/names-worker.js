// Holds the list of archived PV names off the main thread: it keeps a snapshot in IndexedDB, asks the
// server whether the number of PVs changed, merges new names, and answers search requests.
//
// Archived names do not leave the list when their IOC goes down, so a change of the list is almost always
// an addition. The count is checked every POLL_MS; additions come from getRecentlyAddedPVs; the whole list
// is read again when the count falls, when the snapshot is a day old, or when an addition may be incomplete.
// Above the index limit (set by the page) the list is not held here and a search is answered by the server.
const POLL_MS = 15000;
const RESYNC_MS = 24 * 60 * 60 * 1000;
let indexLimit = 500000;
const MARGIN = 20;
// The number can stay the same when names are removed and others are added within one poll, so every few
// polls without a change the latest additions are read as well.
const PROBE_EVERY = 4;
const BULK_INSERT = 200;
const FALLBACK_QUIET_MS = 3000;
const DATABASE = "aa-work-names";
const STORE = "snapshots";

let base = "";
let snapshotKey = "";
let names = [];
let known = new Set();
let serverCount = 0;
let fullAt = 0;
let syncedAt = 0;
let overflow = false;
let busy = false;
let quietPolls = 0;
let visible = true;
let timer = null;
let lastError = "";
let database = null;
// The last search the server was asked for a name the snapshot lacks: the text, the mode and the time.
let lastFallback = { query: "", mode: "", at: 0 };

// ---- the snapshot ---------------------------------------------------------------------------------

function openDatabase() {
    return new Promise((resolve) => {
        try {
            const request = self.indexedDB.open(DATABASE, 1);
            request.onupgradeneeded = () => request.result.createObjectStore(STORE);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => resolve(null);
            request.onblocked = () => resolve(null);
        } catch (error) {
            resolve(null);
        }
    });
}

function readSnapshot() {
    return new Promise((resolve) => {
        if (!database) {
            resolve(null);
            return;
        }
        try {
            const request = database.transaction(STORE, "readonly").objectStore(STORE).get(snapshotKey);
            request.onsuccess = () => resolve(request.result || null);
            request.onerror = () => resolve(null);
        } catch (error) {
            resolve(null);
        }
    });
}

function writeSnapshot() {
    if (!database || overflow) {
        return;
    }
    try {
        database
            .transaction(STORE, "readwrite")
            .objectStore(STORE)
            .put({ names, serverCount, fullAt, syncedAt }, snapshotKey);
    } catch (error) {
        // A snapshot is a convenience; without it the list is read from the server at each visit.
    }
}

// ---- the server -----------------------------------------------------------------------------------

async function getJSON(path) {
    const response = await fetch(new URL(path, base));
    if (!response.ok) {
        throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    return response.json();
}

async function currentCount() {
    const rows = await getJSON("../bpl/getApplianceMetrics");
    return rows.reduce((sum, row) => sum + (Number(row.pvCount) || 0), 0);
}

// ---- keeping the list current ---------------------------------------------------------------------

function setNames(list) {
    names = list.slice().sort();
    known = new Set(names);
}

function insertNames(added) {
    const fresh = added.filter((name) => !known.has(name));
    if (!fresh.length) {
        return 0;
    }
    if (fresh.length > BULK_INSERT) {
        names = names.concat(fresh).sort();
    } else {
        for (const name of fresh) {
            let low = 0;
            let high = names.length;
            while (low < high) {
                const middle = (low + high) >>> 1;
                if (names[middle] < name) {
                    low = middle + 1;
                } else {
                    high = middle;
                }
            }
            names.splice(low, 0, name);
        }
    }
    for (const name of fresh) {
        known.add(name);
    }
    return fresh.length;
}

function announce(changed) {
    self.postMessage({
        type: "status",
        changed,
        count: overflow ? serverCount : names.length,
        asOf: syncedAt,
        overflow,
        syncing: busy,
        error: lastError,
    });
}

async function fullResync(count) {
    setNames(await getJSON("../bpl/getAllPVs?limit=-1"));
    serverCount = count;
    fullAt = Date.now();
    syncedAt = fullAt;
    writeSnapshot();
    return true;
}

async function increment(count) {
    const delta = count - serverCount;
    const limit = delta + MARGIN;
    const rows = await getJSON(`../bpl/getRecentlyAddedPVs?limit=${limit}`);
    const added = rows.map((row) => row.pvName ?? row.name).filter(Boolean);
    const inserted = insertNames(added);
    // Every row was new and the report was full: names may lie beyond it, so read the whole list.
    if (added.length >= limit && inserted === added.length) {
        return fullResync(count);
    }
    serverCount = count;
    syncedAt = Date.now();
    writeSnapshot();
    return inserted > 0;
}

/** Reads the latest additions although the count did not change. */
async function probeAdditions() {
    const rows = await getJSON(`../bpl/getRecentlyAddedPVs?limit=${MARGIN}`);
    const added = rows.map((row) => row.pvName ?? row.name).filter(Boolean);
    const inserted = insertNames(added);
    if (added.length >= MARGIN && inserted === added.length) {
        return fullResync(serverCount);
    }
    if (inserted > 0) {
        writeSnapshot();
    }
    syncedAt = Date.now();
    return inserted > 0;
}

async function cycle(force) {
    if (busy) {
        return;
    }
    busy = true;
    announce(false);
    let changed = false;
    try {
        const count = await currentCount();
        if (count > indexLimit) {
            changed = !overflow;
            overflow = true;
            names = [];
            known = new Set();
            serverCount = count;
            syncedAt = Date.now();
        } else {
            changed = overflow;
            overflow = false;
            const stale = Date.now() - fullAt > RESYNC_MS;
            if (fullAt === 0 || count < serverCount || stale || (names.length === 0 && count > 0) || force === "full") {
                changed = (await fullResync(count)) || changed;
            } else if (count > serverCount) {
                changed = (await increment(count)) || changed;
            } else {
                serverCount = count;
                quietPolls += 1;
                if (quietPolls >= PROBE_EVERY || force) {
                    quietPolls = 0;
                    changed = (await probeAdditions()) || changed;
                } else {
                    syncedAt = Date.now();
                }
            }
        }
        lastError = "";
    } catch (error) {
        lastError = error.message;
    } finally {
        busy = false;
        announce(changed);
    }
}

function schedule() {
    clearInterval(timer);
    timer = visible ? setInterval(() => cycle(), POLL_MS) : null;
}

// ---- search ---------------------------------------------------------------------------------------

function matcher(query, mode) {
    const text = query.trim();
    if (!text) {
        return () => true;
    }
    if (mode === "regex") {
        const pattern = new RegExp(text, "i");
        return (name) => pattern.test(name);
    }
    if (mode === "glob") {
        const escaped = text.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".");
        const pattern = new RegExp(`^${escaped}$`, "i");
        return (name) => pattern.test(name);
    }
    const words = text.toLowerCase().split(/\s+/);
    return (name) => {
        const lower = name.toLowerCase();
        return words.every((word) => lower.includes(word));
    };
}

/**
 * The server matches a pattern; the page filters the answer with the same test as it uses for its own list.
 * Every mode is sent as a case-insensitive regular expression, because a server glob is case sensitive.
 */
async function serverMatches(message) {
    const text = message.query.trim();
    const escape = (word) => word.replace(/[.+^${}()|[\]\\]/g, "\\$&");
    const query = new URLSearchParams({ limit: String(message.limit) });
    if (text && message.mode === "regex") {
        query.set("regex", `(?i).*(?:${text}).*`);
    } else if (text && message.mode === "glob") {
        query.set("regex", `(?i)${escape(text).replace(/\*/g, ".*").replace(/\?/g, ".")}`);
    } else if (text) {
        query.set("regex", `(?i).*${escape(text.split(/\s+/)[0])}.*`);
    }
    return getJSON(`../bpl/getAllPVs?${query}`);
}

function summarize(source, message, test, requireKnown) {
    const allowed = message.allowed ? new Set(message.allowed) : null;
    const prefix = message.prefix ? `${message.prefix}:` : null;
    const found = [];
    const groups = {};
    let total = 0;
    for (const name of source) {
        if ((prefix && !name.startsWith(prefix)) || (allowed && !allowed.has(name)) || !test(name)) {
            continue;
        }
        if (requireKnown && !known.has(name)) {
            continue;
        }
        total += 1;
        if (found.length < message.limit) {
            found.push(name);
        }
        // Name groups: the first two ':'-separated segments, counted over all matches.
        const parts = name.split(":");
        const key = parts.length > 1 ? `${parts[0]}:${parts[1]}` : parts[0];
        groups[key] = (groups[key] || 0) + 1;
    }
    return { found, groups, total };
}

async function search(message) {
    let test;
    try {
        test = matcher(message.query, message.mode);
    } catch (error) {
        self.postMessage({ type: "result", id: message.id, error: String(error.message), names: [], total: 0 });
        return;
    }
    let source;
    let partial = false;
    if (overflow) {
        try {
            // A ranked report already holds its names; no pattern search is needed for it.
            source = message.keepOrder && message.allowed ? message.allowed : await serverMatches(message);
            partial = source.length >= message.limit;
        } catch (error) {
            self.postMessage({ type: "result", id: message.id, error: error.message, names: [], total: 0 });
            return;
        }
    } else {
        // A ranked report keeps the order the server gave; otherwise the names are in alphabetical order.
        source = message.keepOrder && message.allowed ? message.allowed : names;
    }
    let result = summarize(source, message, test, !overflow && message.keepOrder && Boolean(message.allowed));
    // A name the snapshot lacks: ask the server once, and keep what it knows.
    // One request per few seconds, and none for a text that only extends one the server just answered empty.
    const query = message.query.trim();
    const quiet = Date.now() - lastFallback.at < FALLBACK_QUIET_MS;
    const extendsEmpty = lastFallback.mode === message.mode && lastFallback.query && query.startsWith(lastFallback.query) && message.mode === "contains" && Date.now() - lastFallback.at < POLL_MS;
    if (!overflow && !result.total && query && !message.allowed && !quiet && !extendsEmpty) {
        lastFallback = { query, mode: message.mode, at: Date.now() };
        try {
            const extra = (await serverMatches(message)).filter((name) => !known.has(name) && test(name));
            if (extra.length) {
                insertNames(extra);
                writeSnapshot();
                result = summarize(names, message, test, false);
                announce(true);
            }
        } catch (error) {
            // The local answer stands.
        }
    }
    self.postMessage({ type: "result", id: message.id, names: result.found, total: result.total, groups: result.groups, partial });
}

// ---- messages -------------------------------------------------------------------------------------

self.onmessage = async (event) => {
    const message = event.data;
    if (message.type === "init") {
        base = message.base;
        snapshotKey = message.key;
        indexLimit = message.indexLimit || indexLimit;
        database = await openDatabase();
        const snapshot = await readSnapshot();
        if (snapshot && Array.isArray(snapshot.names)) {
            names = snapshot.names;
            known = new Set(names);
            serverCount = snapshot.serverCount || names.length;
            fullAt = snapshot.fullAt || 0;
            syncedAt = snapshot.syncedAt || 0;
            announce(true);
        }
        schedule();
        cycle();
    } else if (message.type === "refresh") {
        cycle(message.full ? "full" : undefined);
    } else if (message.type === "visibility") {
        visible = message.visible;
        schedule();
        if (visible) {
            cycle();
        }
    } else if (message.type === "search") {
        search(message);
    }
};
