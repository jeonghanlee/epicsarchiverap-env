// Distribution and scatter plots with D3 scales. Axes carry only the range; the number that matters
// (the mean, the correlation) is written next to the data in text.
const d3 = globalThis.d3;

function text(value) {
    const digits = Math.abs(value) >= 100 ? 1 : Math.abs(value) >= 1 ? 3 : 4;
    return Number(value.toFixed(digits)).toString();
}

/** input: {values: number[], egu: string}. Returns the mean for the caption, or null when nothing is drawn. */
export function drawHistogram(host, input) {
    host.textContent = "";
    const values = input.values.filter((v) => Number.isFinite(v));
    if (values.length < 2) {
        host.textContent = "Too few samples for a distribution.";
        return null;
    }
    const width = Math.max(260, host.clientWidth || 360);
    const height = 150;
    const margin = { top: 14, right: 8, bottom: 22, left: 8 };
    const [low, high] = d3.extent(values);
    const mean = d3.mean(values);
    const x = d3.scaleLinear().domain(low === high ? [low - 1, high + 1] : [low, high]).range([margin.left, width - margin.right]);
    const count = Math.min(30, Math.max(8, Math.ceil(Math.log2(values.length) + 1)));
    const bins = d3.bin().domain(x.domain()).thresholds(count)(values);
    const y = d3.scaleLinear().domain([0, d3.max(bins, (b) => b.length)]).range([height - margin.bottom, margin.top]);

    const svg = d3.create("svg").attr("viewBox", `0 0 ${width} ${height}`).attr("width", "100%").attr("height", height)
        .attr("role", "img").attr("aria-label", `Distribution of ${values.length} values`);
    for (const bin of bins) {
        svg.append("rect")
            .attr("class", "bar")
            .attr("x", x(bin.x0) + 1)
            .attr("y", y(bin.length))
            .attr("width", Math.max(1, x(bin.x1) - x(bin.x0) - 1))
            .attr("height", y(0) - y(bin.length));
    }
    svg.append("line").attr("class", "mean").attr("x1", x(mean)).attr("x2", x(mean)).attr("y1", margin.top).attr("y2", height - margin.bottom);
    svg.append("text").attr("class", "axis").attr("x", margin.left).attr("y", height - 6).text(text(low));
    svg.append("text").attr("class", "axis").attr("x", width - margin.right).attr("y", height - 6).attr("text-anchor", "end").text(text(high));
    svg.append("text").attr("class", "axis").attr("x", margin.left).attr("y", 10).text(`most in one bin: ${d3.max(bins, (b) => b.length)}`);
    host.append(svg.node());
    return mean;
}

/** input: {x: {name, points}, y: {name, points}}. Points are paired by equal time. Returns the correlation or null. */
export function drawScatter(host, input) {
    host.textContent = "";
    const byTime = new Map(input.y.points.map((p) => [p.t, p.v]));
    const pairs = [];
    for (const p of input.x.points) {
        if (byTime.has(p.t)) {
            pairs.push([p.v, byTime.get(p.t)]);
        }
    }
    if (pairs.length < 3) {
        host.textContent = "The two PVs have too few samples at the same times.";
        return null;
    }
    const width = Math.max(260, host.clientWidth || 360);
    const height = 150;
    const margin = { top: 8, right: 8, bottom: 22, left: 8 };
    const xs = pairs.map((p) => p[0]);
    const ys = pairs.map((p) => p[1]);
    const [xLow, xHigh] = d3.extent(xs);
    const [yLow, yHigh] = d3.extent(ys);
    const x = d3.scaleLinear().domain(xLow === xHigh ? [xLow - 1, xHigh + 1] : [xLow, xHigh]).range([margin.left, width - margin.right]);
    const y = d3.scaleLinear().domain(yLow === yHigh ? [yLow - 1, yHigh + 1] : [yLow, yHigh]).range([height - margin.bottom, margin.top]);
    const meanX = d3.mean(xs);
    const meanY = d3.mean(ys);
    let covariance = 0;
    let varX = 0;
    let varY = 0;
    for (const [a, b] of pairs) {
        covariance += (a - meanX) * (b - meanY);
        varX += (a - meanX) ** 2;
        varY += (b - meanY) ** 2;
    }
    const correlation = varX > 0 && varY > 0 ? covariance / Math.sqrt(varX * varY) : null;

    const svg = d3.create("svg").attr("viewBox", `0 0 ${width} ${height}`).attr("width", "100%").attr("height", height)
        .attr("role", "img").attr("aria-label", `${pairs.length} paired values of two PVs`);
    for (const [a, b] of pairs) {
        svg.append("circle").attr("class", "dot").attr("cx", x(a)).attr("cy", y(b)).attr("r", 2);
    }
    svg.append("text").attr("class", "axis").attr("x", margin.left).attr("y", height - 6).text(text(xLow));
    svg.append("text").attr("class", "axis").attr("x", width - margin.right).attr("y", height - 6).attr("text-anchor", "end").text(text(xHigh));
    host.append(svg.node());
    return correlation;
}
