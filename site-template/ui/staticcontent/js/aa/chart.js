// Time series drawing with D3 scales and shapes. Principles: ink goes to the data, the axes carry only the
// range, lines are labelled directly, missing data is a gap, and a monitored value is held until the next sample.
const d3 = globalThis.d3;

const DASHES = ["", "", "6 3", "2 3", "9 3 2 3"];

function format(value, egu) {
    const digits = Math.abs(value) >= 100 ? 1 : Math.abs(value) >= 1 ? 3 : 4;
    return `${value.toFixed(digits)}${egu ? ` ${egu}` : ""}`;
}

/** Names without the leading segments they all share; a single name stays whole. */
function shortNames(names) {
    if (names.length < 2) {
        return names;
    }
    const parts = names.map((name) => name.split(":"));
    let shared = 0;
    while (shared < Math.min(...parts.map((p) => p.length)) - 1 && parts.every((p) => p[shared] === parts[0][shared])) {
        shared += 1;
    }
    return parts.map((p) => p.slice(shared).join(":"));
}

// More samples than this in view are not marked one by one.
const MARKER_LIMIT = 200;

// A line breaks before a point flagged g (the connection was lost before it) and, when gapMs is finite,
// where two points are further apart than gapMs. A monitored PV may be silent for long and keeps its value.
function splitOnGaps(points, gapMs) {
    const parts = [];
    let current = [];
    for (const point of points) {
        const last = current[current.length - 1];
        if (last && (point.g || point.t - last.t > gapMs)) {
            parts.push(current);
            current = [];
        }
        current.push(point);
    }
    if (current.length) {
        parts.push(current);
    }
    return parts;
}

/**
 * input: {series: [{name, egu, points: [{t, v, s, g?}], focus, quiet?}], from: Date, to: Date, gapMs: number (Infinity: none), labelNames?: boolean}
 * onZoom(from, to) turns a horizontal drag over the plot into a request for that window. Exact samples are marked
 * when the window holds few enough of them to be told apart.
 * quiet draws a series thin and pale, as the background of a series that carries the point (a floor over raw values).
 * labelNames false labels the end of a line with its value only, for a chart whose title already names it.
 * Replaces the content of host and returns nothing.
 */
export function drawTimeSeries(host, input) {
    host.textContent = "";
    const { series, from, to, gapMs } = input;
    const drawn = series.filter((s) => s.points.length);
    if (!drawn.length) {
        host.textContent = "No samples in this time range.";
        return;
    }
    const width = Math.max(320, host.clientWidth || 640);
    const narrow = width < 560;
    const height = 250;
    const labelNames = input.labelNames !== false;
    const margin = { top: 8, right: labelNames ? (narrow ? 76 : 170) : 70, bottom: 34, left: 56 };
    const x = d3.scaleTime().domain([from, to]).range([margin.left, width - margin.right]);
    const values = drawn.flatMap((s) => s.points.map((p) => p.v));
    let [low, high] = d3.extent(values);
    const pad = (high - low) * 0.1 || Math.abs(high) * 0.05 || 1;
    // A series that never goes below zero keeps zero as its floor instead of a padded negative value.
    low = values.every((v) => v >= 0) ? Math.max(0, low - pad) : low - pad;
    high += pad;
    const y = d3.scaleLinear().domain([low, high]).nice(4).range([height - margin.bottom, margin.top]);

    const svg = d3
        .create("svg")
        .attr("viewBox", `0 0 ${width} ${height}`)
        .attr("width", "100%")
        .attr("height", height)
        .attr("role", "img")
        .attr("aria-label", `Time series of ${drawn.length} PV${drawn.length > 1 ? "s" : ""}`);

    const egu = drawn[0].egu;
    for (const tick of y.ticks(4)) {
        svg.append("line").attr("class", "grid").attr("x1", margin.left).attr("x2", width - margin.right).attr("y1", y(tick)).attr("y2", y(tick));
        svg.append("text").attr("class", "axis").attr("x", margin.left - 6).attr("y", y(tick) + 4).attr("text-anchor", "end").text(d3.format(".4~g")(tick));
    }
    const spanHours = (to - from) / 3600000;
    const timeFormat = d3.timeFormat(spanHours > 36 ? "%m-%d %H:%M" : "%H:%M");
    [0, 1 / 3, 2 / 3, 1].forEach((fraction, index, all) => {
        const when = new Date(from.getTime() + fraction * (to - from));
        svg.append("text")
            .attr("class", "axis")
            .attr("x", x(when))
            .attr("y", height - 8)
            .attr("text-anchor", index === 0 ? "start" : index === all.length - 1 ? "end" : "middle")
            .text(timeFormat(when));
    });

    // Alarm lane: the only mark besides a line that uses the alert color.
    const laneY = height - margin.bottom + 8;
    for (const s of drawn) {
        for (const point of s.points) {
            if (point.s > 0) {
                svg.append("rect").attr("class", "alarm").attr("x", x(point.t) - 1).attr("y", laneY).attr("width", 3).attr("height", 4);
            }
        }
    }

    const line = d3.line().x((p) => x(p.t)).y((p) => y(p.v)).curve(d3.curveStepAfter);
    const ordered = drawn.slice().sort((a, b) => Number(a.focus) - Number(b.focus));
    const labels = [];
    const shortOf = new Map(drawn.map((s, i) => [s, shortNames(drawn.map((d) => d.name))[i]]));
    ordered.forEach((s) => {
        const slot = drawn.indexOf(s);
        for (const part of splitOnGaps(s.points, gapMs)) {
            svg.append("path")
                .attr("class", s.focus ? "line focus" : s.quiet ? "line quiet" : "line")
                .attr("stroke-dasharray", s.focus ? null : DASHES[slot % DASHES.length] || null)
                .attr("d", line(part));
        }
        const last = s.points[s.points.length - 1];
        labels.push({ y: y(last.v), series: s, last });
    });

    // The samples themselves, once few enough are in view to be told apart one from another.
    const inView = (s) => s.points.filter((p) => p.t >= from.getTime() && p.t <= to.getTime());
    if (drawn.every((s) => inView(s).length <= MARKER_LIMIT)) {
        for (const s of ordered) {
            for (const point of inView(s)) {
                svg.append("circle")
                    .attr("class", s.focus ? "dot focus" : "dot")
                    .attr("cx", x(point.t))
                    .attr("cy", y(point.v))
                    .attr("r", 2.4);
            }
        }
    }

    // Direct labels at the end of each line, pushed apart so they do not overlap.
    labels.sort((a, b) => a.y - b.y);
    for (let i = 1; i < labels.length; i += 1) {
        if (labels[i].y - labels[i - 1].y < 13) {
            labels[i].y = labels[i - 1].y + 13;
        }
    }
    for (const label of labels) {
        const short = shortOf.get(label.series);
        svg.append("text")
            .attr("class", label.series.focus ? "label focus" : "label")
            .attr("x", width - margin.right + 6)
            .attr("y", label.y + 4)
            .text(!labelNames ? format(label.last.v, "") : narrow ? short : `${short}  ${format(label.last.v, "")}`.trim());
    }

    const cross = svg.append("line").attr("class", "cross").attr("y1", margin.top).attr("y2", height - margin.bottom).attr("visibility", "hidden");
    const tip = document.createElement("div");
    tip.className = "tip";
    tip.hidden = true;
    const bisect = d3.bisector((p) => p.t).center;

    svg.on("pointermove", (event) => {
        const box = svg.node().getBoundingClientRect();
        const px = ((event.clientX - box.left) / box.width) * width;
        if (px < margin.left || px > width - margin.right) {
            cross.attr("visibility", "hidden");
            tip.hidden = true;
            return;
        }
        const when = x.invert(px);
        tip.textContent = "";
        const heading = document.createElement("b");
        heading.textContent = d3.timeFormat("%Y-%m-%d %H:%M:%S")(when);
        tip.append(heading);
        let nearest = null;
        for (const s of drawn) {
            const point = s.points[bisect(s.points, when.getTime())];
            const row = document.createElement("div");
            row.textContent = `${shortOf.get(s)}  ${point ? format(point.v, s.egu) : "no sample"}${point && point.s ? "  ALARM" : ""}`;
            if (point && point.s) {
                row.className = "alarm-text";
            }
            tip.append(row);
            if (point && (!nearest || Math.abs(point.t - when) < Math.abs(nearest.t - when))) {
                nearest = point;
            }
        }
        cross.attr("visibility", "visible").attr("x1", x(nearest ? nearest.t : when)).attr("x2", x(nearest ? nearest.t : when));
        tip.hidden = false;
        const left = (px / width) * box.width + 12;
        tip.style.left = `${left > box.width - 240 ? left - 252 : left}px`;
        tip.style.top = "8px";
    });
    svg.on("pointerleave", () => {
        cross.attr("visibility", "hidden");
        tip.hidden = true;
    });

    // Drag across the plot to look at that window; a short click does nothing.
    if (typeof input.onZoom === "function") {
        const band = svg.append("rect").attr("class", "brush").attr("y", margin.top).attr("height", height - margin.top - margin.bottom).attr("visibility", "hidden");
        let startX = null;
        const toUser = (event) => {
            const box = svg.node().getBoundingClientRect();
            return Math.max(margin.left, Math.min(width - margin.right, ((event.clientX - box.left) / box.width) * width));
        };
        svg.style("touch-action", "pan-y");
        svg.on("pointerdown", (event) => {
            const px = toUser(event);
            if (event.button !== 0 || px <= margin.left - 1 || px >= width - margin.right + 1) {
                return;
            }
            startX = px;
            try {
                svg.node().setPointerCapture(event.pointerId);
            } catch (error) {
                // A synthetic pointer has nothing to capture; the drag still works.
            }
        });
        svg.on("pointermove.brush", (event) => {
            if (startX === null) {
                return;
            }
            const px = toUser(event);
            band.attr("visibility", "visible").attr("x", Math.min(startX, px)).attr("width", Math.abs(px - startX));
        });
        svg.on("pointerup", (event) => {
            if (startX === null) {
                return;
            }
            const px = toUser(event);
            const a = Math.min(startX, px);
            const b = Math.max(startX, px);
            startX = null;
            band.attr("visibility", "hidden");
            if (b - a >= 8) {
                input.onZoom(x.invert(a), x.invert(b));
            }
        });
        svg.on("pointercancel", () => {
            startX = null;
            band.attr("visibility", "hidden");
        });
    }

    host.append(svg.node(), tip);
    host.dataset.egu = egu;
}
