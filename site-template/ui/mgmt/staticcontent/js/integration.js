// The Integration page: Channel Archiver configuration, external archiver data servers, and a comparison.
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

async function getJSON(path, parameters) {
    const query = parameters ? `?${new URLSearchParams(parameters)}` : "";
    const response = await fetch(`${path}${query}`);
    if (!response.ok) {
        throw new Error(`${response.statusText || "the server could not complete the request"} (HTTP ${response.status})`);
    }
    return response.json();
}

function say(text, isError) {
    const message = $("message");
    message.textContent = text;
    message.classList.toggle("error", Boolean(isError));
}

// ---- the result of an upload comes back in the address -------------------------------------------

function showUploadResult() {
    const parameters = new URLSearchParams(window.location.search);
    const message = parameters.get("message");
    if (message) {
        say(message, message.startsWith("Error"));
        window.history.replaceState(null, "", window.location.pathname);
    }
}

function wireUpload() {
    $("uploadForm").addEventListener("submit", (event) => {
        if (!$("configFile").files || $("configFile").files.length < 1) {
            event.preventDefault();
            $("uploadError").textContent = "Choose at least one file first.";
        }
    });
}

// ---- external archiver servers --------------------------------------------------------------------

async function loadServers() {
    const body = $("servers").querySelector("tbody");
    body.textContent = "";
    let servers;
    try {
        servers = await getJSON("../bpl/getExternalArchiverServers");
    } catch (error) {
        body.append(node("tr", null, node("td", { colspan: "3", class: "empty" }, `The list could not be read: ${error.message}`)));
        return;
    }
    if (!servers.length) {
        body.append(node("tr", null, node("td", { colspan: "3", class: "empty" }, "No external server is configured.")));
        return;
    }
    for (const server of servers) {
        const remove = node("button", { type: "button", class: "plain danger" }, "Remove…");
        remove.addEventListener("click", () => openRemove(server));
        body.append(
            node(
                "tr",
                null,
                node("td", { class: "pv" }, String(server.CAUrl)),
                node("td", { class: "num" }, String(server.indexes)),
                node("td", { class: "r" }, remove),
            ),
        );
    }
}

const HINTS = {
    CA_XMLRPC: "Give the XMLRPC URL of the Channel Archiver data server.",
    ARCHAPPL_PBRAW: "Give the data_retrieval_url of the archiver cluster, as defined in its appliances.xml.",
};

function openAdd() {
    $("serverType").value = "CA_XMLRPC";
    $("serverHint").textContent = HINTS.CA_XMLRPC;
    $("serverUrl").value = "";
    $("serverUrl").readOnly = false;
    $("archivesStep").hidden = true;
    $("archives").textContent = "";
    $("addError").textContent = "";
    $("addSubmit").textContent = "Connect";
    $("addDialog").showModal();
}

let pendingServerUrl = null;
async function submitAdd(event) {
    event.preventDefault();
    $("addError").textContent = "";
    // Second step: the archives of a Channel Archiver server were chosen.
    if (pendingServerUrl) {
        const chosen = Array.from($("archives").selectedOptions).map((option) => option.value);
        if (!chosen.length) {
            $("addError").textContent = "Select the archives you want to serve.";
            return;
        }
        try {
            await getJSON("../bpl/addExternalArchiverServerArchives", { channelarchiverserverurl: pendingServerUrl, archives: chosen.join(",") });
            pendingServerUrl = null;
            $("addDialog").close();
            say("The server was added.");
            loadServers();
        } catch (error) {
            $("addError").textContent = `The server could not be added: ${error.message}`;
        }
        return;
    }
    const url = $("serverUrl").value.trim();
    const type = $("serverType").value;
    try {
        const answer = await getJSON("../bpl/addExternalArchiverServer", { externalarchiverserverurl: url, externalServerType: type });
        if (answer.validation) {
            $("addError").textContent = answer.validation;
            return;
        }
        if (type === "CA_XMLRPC") {
            pendingServerUrl = url;
            $("serverUrl").readOnly = true;
            $("archivesMessage").textContent = `A connection to ${url} was established. Select the archives to serve.`;
            for (const archive of answer.archives || []) {
                $("archives").append(node("option", { value: archive.key }, archive.name));
            }
            $("archivesStep").hidden = false;
            $("addSubmit").textContent = "Add the selected archives";
        } else {
            await getJSON("../bpl/addExternalArchiverServerArchives", { channelarchiverserverurl: url, archives: "pbraw" });
            $("addDialog").close();
            say("The server was added.");
            loadServers();
        }
    } catch (error) {
        $("addError").textContent = `The server could not be reached: ${error.message}`;
    }
}

let removing = null;
function openRemove(server) {
    removing = server;
    $("removeName").textContent = String(server.CAUrl);
    $("removeDialog").showModal();
}

async function submitRemove(event) {
    event.preventDefault();
    const server = removing;
    $("removeDialog").close();
    if (!server) {
        return;
    }
    try {
        const answer = await getJSON("../bpl/removeExternalArchiverServer", { channelarchiverserverurl: server.CAUrl, archives: server.indexes });
        if (answer.status === "ok") {
            say("The server was removed. The cluster may have to be restarted for this to take effect.");
        } else {
            say("The server could not be removed. The archiver logs say why.", true);
        }
    } catch (error) {
        say(`The server could not be removed: ${error.message}`, true);
    }
    loadServers();
}

// ---- comparison ------------------------------------------------------------------------------------

async function submitCompare(event) {
    event.preventDefault();
    $("compareError").textContent = "";
    const table = $("comparison");
    table.hidden = true;
    try {
        const rows = await getJSON("../bpl/test/compareWithChannelArchiver", {
            pv: $("comparePV").value.trim(),
            serverURL: $("compareURL").value.trim(),
            archiveKey: $("compareIndex").value.trim(),
        });
        const body = table.querySelector("tbody");
        body.textContent = "";
        for (const row of rows) {
            body.append(
                node(
                    "tr",
                    null,
                    node("td", null, String(row.src)),
                    node("td", { class: "num" }, String(row.ts)),
                    node("td", { class: "r num" }, String(row.nanos)),
                    node("td", null, String(row.sevr)),
                    node("td", null, String(row.stat)),
                ),
            );
        }
        table.hidden = false;
        if (!rows.length) {
            $("compareError").textContent = "Neither archiver returned samples for this PV.";
        }
    } catch (error) {
        $("compareError").textContent = `The comparison failed: ${error.message}`;
    }
}

function wire() {
    $("addServer").addEventListener("click", openAdd);
    $("serverType").addEventListener("change", (event) => {
        $("serverHint").textContent = HINTS[event.target.value];
    });
    $("addForm").addEventListener("submit", submitAdd);
    $("addCancel").addEventListener("click", () => {
        pendingServerUrl = null;
        $("addDialog").close();
    });
    $("addDialog").addEventListener("close", () => {
        pendingServerUrl = null;
    });
    $("removeForm").addEventListener("submit", submitRemove);
    $("removeCancel").addEventListener("click", () => $("removeDialog").close());
    $("compareForm").addEventListener("submit", submitCompare);
}

showUploadResult();
wireUpload();
wire();
loadServers();
