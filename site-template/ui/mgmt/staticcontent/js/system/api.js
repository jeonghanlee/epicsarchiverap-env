// Server access for the System pages. Every call is a plain GET of a status or report that already exists.

export async function get(path, parameters) {
    const query = parameters ? `?${new URLSearchParams(parameters)}` : "";
    const response = await fetch(`${path}${query}`);
    if (!response.ok) {
        throw new Error(`${path}: ${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    return response.json();
}

/** A number the server wrote as text, possibly with thousands separators. */
export function number(text) {
    const value = Number(String(text).replace(/,/g, ""));
    return Number.isFinite(value) ? value : null;
}

/** The names of some measures carry HTML entities. */
export function plain(text) {
    return String(text).replace(/&raquo;/g, ">").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
}

export function node(tag, attributes, ...children) {
    const element = document.createElement(tag);
    for (const [key, value] of Object.entries(attributes || {})) {
        if (value !== undefined && value !== null) {
            element.setAttribute(key, value);
        }
    }
    element.append(...children.filter((child) => child !== null && child !== undefined));
    return element;
}

/** The appliances of the cluster with their headline metrics and the management uptime. */
export async function appliances() {
    const [load, instances] = await Promise.all([get("../bpl/getApplianceMetrics"), get("../bpl/getInstanceMetrics")]);
    const uptime = new Map(instances.map((row) => [row.instance, row.MGMT_uptime]));
    return load.map((row) => ({ ...row, uptime: uptime.get(row.instance) || "" }));
}

/** pauseArchivingPV or resumeArchivingPV for several PVs in one call: one answer per PV. */
export async function pauseResume(kind, names) {
    const response = await fetch(kind, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(names),
    });
    if (!response.ok) {
        throw new Error(`${kind}: ${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    const result = await response.json();
    return Array.isArray(result) ? result : [result];
}

/** Reports that may fail on their own are read together; a failed one is null. */
export async function settled(calls) {
    const results = await Promise.allSettled(calls);
    return results.map((result) => (result.status === "fulfilled" ? result.value : null));
}
