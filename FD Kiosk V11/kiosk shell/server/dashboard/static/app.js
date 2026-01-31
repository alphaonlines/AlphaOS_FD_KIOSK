const STATUS_THRESHOLDS_MS = {
  online: 5 * 60 * 1000,
  stale: 30 * 60 * 1000,
};

function parseIso(value) {
  if (!value) return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

function statusClass(lastSeen) {
  const d = parseIso(lastSeen);
  if (!d) return "status-unknown";
  const age = Date.now() - d.getTime();
  if (age <= STATUS_THRESHOLDS_MS.online) return "status-online";
  if (age <= STATUS_THRESHOLDS_MS.stale) return "status-stale";
  return "status-offline";
}

function formatRelative(lastSeen) {
  const d = parseIso(lastSeen);
  if (!d) return "—";
  const seconds = Math.floor((Date.now() - d.getTime()) / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

async function fetchJson(url, options) {
  const resp = await fetch(url, options);
  const contentType = resp.headers.get("content-type") || "";
  let data = null;
  if (contentType.includes("application/json")) {
    try {
      data = await resp.json();
    } catch (err) {
      data = null;
    }
  } else {
    try {
      data = { error: await resp.text() };
    } catch (err) {
      data = { error: "invalid_response" };
    }
  }
  if (!resp.ok) {
    const message = data && data.error ? data.error : "request_failed";
    throw new Error(message);
  }
  return data;
}

function setStatus(el, text, tone) {
  el.textContent = text;
  el.className = `status-line ${tone}`;
}

async function loadKioskList() {
  const tableBody = document.querySelector("#kiosk-table-body");
  const statusEl = document.querySelector("#kiosk-list-status");
  if (!tableBody || !statusEl) return;

  setStatus(statusEl, "Loading kiosks…", "muted");
  tableBody.innerHTML = "";

  try {
    const kiosks = await fetchJson("/api/kiosks");
    if (!kiosks.length) {
      setStatus(statusEl, "No kiosks reported yet.", "muted");
      return;
    }

    kiosks.forEach((kiosk) => {
      const tr = document.createElement("tr");

      const statusTd = document.createElement("td");
      statusTd.className = "status-cell";
      const statusDot = document.createElement("span");
      statusDot.className = `status-dot ${statusClass(kiosk.last_seen)}`;
      statusTd.appendChild(statusDot);

      const idTd = document.createElement("td");
      const idLink = document.createElement("a");
      idLink.className = "link";
      idLink.href = `/kiosk/${encodeURIComponent(kiosk.kiosk_id || "")}`;
      idLink.textContent = kiosk.kiosk_id || "—";
      idTd.appendChild(idLink);

      const locationTd = document.createElement("td");
      locationTd.textContent = kiosk.location || "—";

      const osTd = document.createElement("td");
      osTd.textContent = kiosk.os_version || "—";

      const gitTd = document.createElement("td");
      gitTd.className = "mono";
      gitTd.textContent = kiosk.git_sha || "—";

      const ipTd = document.createElement("td");
      ipTd.textContent = kiosk.ip || "—";

      const lastSeenTd = document.createElement("td");
      const lastSeenPrimary = document.createElement("div");
      lastSeenPrimary.textContent = kiosk.last_seen || "—";
      const lastSeenRelative = document.createElement("div");
      lastSeenRelative.className = "small muted";
      lastSeenRelative.textContent = formatRelative(kiosk.last_seen);
      lastSeenTd.appendChild(lastSeenPrimary);
      lastSeenTd.appendChild(lastSeenRelative);

      tr.appendChild(statusTd);
      tr.appendChild(idTd);
      tr.appendChild(locationTd);
      tr.appendChild(osTd);
      tr.appendChild(gitTd);
      tr.appendChild(ipTd);
      tr.appendChild(lastSeenTd);
      tableBody.appendChild(tr);
    });

    setStatus(statusEl, `Loaded ${kiosks.length} kiosks.`, "muted");
  } catch (err) {
    setStatus(statusEl, `Failed to load kiosks: ${err.message}`, "error");
  }
}

async function loadKioskDetail(kioskId) {
  const detailEl = document.querySelector("#kiosk-detail");
  const historyBody = document.querySelector("#history-table-body");
  const historyStatus = document.querySelector("#history-status");
  if (!detailEl || !historyBody || !historyStatus) return;

  setStatus(historyStatus, "Loading history…", "muted");
  historyBody.innerHTML = "";

  try {
    const kiosks = await fetchJson("/api/kiosks");
    const kiosk = kiosks.find((item) => item.kiosk_id === kioskId);
    if (kiosk) {
      detailEl.innerHTML = "";
      const addRow = (labelText, valueNode) => {
        const row = document.createElement("div");
        const label = document.createElement("span");
        label.className = "label";
        label.textContent = labelText;
        row.appendChild(label);
        row.appendChild(document.createTextNode(" "));
        row.appendChild(valueNode);
        detailEl.appendChild(row);
      };

      const statusValue = document.createElement("span");
      statusValue.className = `status-dot ${statusClass(kiosk.last_seen)}`;
      addRow("Status", statusValue);

      const locationValue = document.createElement("span");
      locationValue.textContent = kiosk.location || "—";
      addRow("Location", locationValue);

      const osValue = document.createElement("span");
      osValue.textContent = kiosk.os_version || "—";
      addRow("OS", osValue);

      const gitValue = document.createElement("span");
      gitValue.className = "mono";
      gitValue.textContent = kiosk.git_sha || "—";
      addRow("Git SHA", gitValue);

      const ipValue = document.createElement("span");
      ipValue.textContent = kiosk.ip || "—";
      addRow("IP", ipValue);

      const lastSeenValue = document.createElement("span");
      const lastSeenText = kiosk.last_seen || "—";
      lastSeenValue.textContent = `${lastSeenText} (${formatRelative(kiosk.last_seen)})`;
      addRow("Last Seen", lastSeenValue);
    } else {
      detailEl.innerHTML = "<div class=\"muted\">Kiosk not found in latest list.</div>";
    }
  } catch (err) {
    detailEl.innerHTML = `<div class="error">Failed to load kiosk info: ${err.message}</div>`;
  }

  try {
    const history = await fetchJson(`/api/kiosks/${encodeURIComponent(kioskId)}/history`);
    if (!history.length) {
      setStatus(historyStatus, "No command history yet.", "muted");
      return;
    }
    history.forEach((entry) => {
      const tr = document.createElement("tr");

      const cmdTd = document.createElement("td");
      cmdTd.className = "mono";
      cmdTd.textContent = entry.cmd_id || "—";

      const actionTd = document.createElement("td");
      actionTd.textContent = entry.action || "—";

      const whenTd = document.createElement("td");
      whenTd.textContent = entry.when || "—";

      const statusTd = document.createElement("td");
      const statusPill = document.createElement("span");
      const statusValue = entry.status || "queued";
      statusPill.className = `pill ${statusValue}`;
      statusPill.textContent = statusValue;
      statusTd.appendChild(statusPill);

      const startedTd = document.createElement("td");
      startedTd.textContent = entry.started_at || "—";

      const finishedTd = document.createElement("td");
      finishedTd.textContent = entry.finished_at || "—";

      const outputTd = document.createElement("td");
      outputTd.className = "mono";
      outputTd.textContent = entry.output || "—";

      tr.appendChild(cmdTd);
      tr.appendChild(actionTd);
      tr.appendChild(whenTd);
      tr.appendChild(statusTd);
      tr.appendChild(startedTd);
      tr.appendChild(finishedTd);
      tr.appendChild(outputTd);
      historyBody.appendChild(tr);
    });
    setStatus(historyStatus, `Loaded ${history.length} entries.`, "muted");
  } catch (err) {
    setStatus(historyStatus, `Failed to load history: ${err.message}`, "error");
  }
}

async function issueCommand(kioskId, action) {
  const actionStatus = document.querySelector("#action-status");
  if (actionStatus) {
    setStatus(actionStatus, `Sending ${action}…`, "muted");
  }

  try {
    const result = await fetchJson("/api/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ kiosk_id: kioskId, action, when: "immediate", args: {} }),
    });
    if (actionStatus) {
      setStatus(actionStatus, `Command queued: ${result.cmd_id}`, "success");
    }
    await loadKioskDetail(kioskId);
  } catch (err) {
    if (actionStatus) {
      setStatus(actionStatus, `Command failed: ${err.message}`, "error");
    }
  }
}

window.dashboard = {
  loadKioskList,
  loadKioskDetail,
  issueCommand,
};
