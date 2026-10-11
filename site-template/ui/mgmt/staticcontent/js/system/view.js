// Small pieces the System pages share.
import { node } from "./api.js";
import { MARKS, WORDS } from "./judge.js";

/** A judgement as a word with a mark, so the color is never the only carrier, and the sentence that explains it. */
export function statusNode(kind, text) {
    const box = node("div", { class: "status" }, node("span", { class: `st ${kind}` }, `${MARKS[kind]} ${WORDS[kind]}`));
    if (text) {
        box.append(node("span", { class: "why" }, text));
    }
    return box;
}

export function timeText(seconds) {
    return seconds ? new Date(seconds * 1000).toLocaleString([], { hour12: false }) : "";
}

export function clock() {
    return new Date().toLocaleTimeString([], { hour12: false });
}

/**
 * The appliance of the address (?appliance=name) or the first one. The choice is kept in the address and in the
 * links to the other System pages. A select is shown only when the cluster has more than one appliance.
 */
let carried = "";

/** The address of another System page for the chosen appliance; a #fragment stays at the end. */
export function pageHref(target) {
    const [page, fragment] = target.split("#");
    return `${page}${carried}${fragment ? `#${fragment}` : ""}`;
}

export function chooseAppliance(list, select, onChange) {
    const wanted = new URLSearchParams(window.location.search).get("appliance");
    let current = list.find((row) => row.instance === wanted) || list[0] || null;
    select.textContent = "";
    for (const row of list) {
        select.append(node("option", { value: row.instance }, row.instance));
    }
    select.hidden = list.length < 2;
    if (current) {
        select.value = current.instance;
    }
    const carry = () => {
        const suffix = current && list.length > 1 ? `?appliance=${encodeURIComponent(current.instance)}` : "";
        carried = suffix;
        document.querySelectorAll(".tabs a").forEach((link) => {
            const target = link.getAttribute("data-page");
            if (target) {
                link.setAttribute("href", `${target}${suffix}`);
            }
        });
    };
    carry();
    select.onchange = () => {
        current = list.find((row) => row.instance === select.value) || current;
        window.history.replaceState(null, "", `?appliance=${encodeURIComponent(current.instance)}${window.location.hash}`);
        carry();
        onChange(current);
    };
    return current;
}
