// A sparkline: the shape of the recent values and the position of the last one, nothing else.
const NS = "http://www.w3.org/2000/svg";

export function sparkline(points, alarming) {
    const width = 150;
    const height = 22;
    const svg = document.createElementNS(NS, "svg");
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
    svg.setAttribute("width", String(width));
    svg.setAttribute("height", String(height));
    svg.setAttribute("aria-hidden", "true");
    if (points.length < 2) {
        return svg;
    }
    let low = Infinity;
    let high = -Infinity;
    for (const point of points) {
        low = Math.min(low, point.v);
        high = Math.max(high, point.v);
    }
    if (high === low) {
        high += 1;
        low -= 1;
    }
    const first = points[0].t;
    const span = points[points.length - 1].t - first || 1;
    const px = (t) => 2 + ((t - first) / span) * (width - 4);
    const py = (v) => height - 3 - ((v - low) / (high - low)) * (height - 6);
    const path = document.createElementNS(NS, "path");
    path.setAttribute("class", "spark");
    path.setAttribute("d", points.map((p, i) => `${i ? "L" : "M"}${px(p.t).toFixed(1)} ${py(p.v).toFixed(1)}`).join(""));
    svg.append(path);
    const last = points[points.length - 1];
    const dot = document.createElementNS(NS, "circle");
    dot.setAttribute("class", alarming ? "spark-end alarm" : "spark-end");
    dot.setAttribute("cx", px(last.t).toFixed(1));
    dot.setAttribute("cy", py(last.v).toFixed(1));
    dot.setAttribute("r", "2");
    svg.append(dot);
    return svg;
}
