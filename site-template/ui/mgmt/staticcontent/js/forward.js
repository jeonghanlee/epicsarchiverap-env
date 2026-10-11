// Old addresses of the management interface keep working: a page that moved forwards to its new place.
const parameters = new URLSearchParams(window.location.search);
const pv = parameters.get("pv");
const target = pv ? `index.html#pv=${encodeURIComponent(pv)}` : "index.html";
window.location.replace(target);
