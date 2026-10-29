.pragma library

var INSTALL_URL = "https://github.com/jwkicklighter/lofi-player/releases/latest/download/install"
var INSTALL_COMMAND = "curl -fsSL " + INSTALL_URL + " | bash"

var MAX_TITLE = 300
var MAX_ROWS = 200

function clip(value, limit) {
  var text = String(value === undefined || value === null ? "" : value)
  return text.length > limit ? text.slice(0, limit) : text
}

// `lofi status` prints one JSON line; anything unexpected reads as stopped.
function parseStatus(raw) {
  var stopped = { state: "stopped", volume: -1, title: "" }
  var payload
  try {
    payload = JSON.parse(String(raw || "").trim())
  } catch (error) {
    return stopped
  }
  if (!payload || typeof payload !== "object") return stopped
  var state = payload["class"] === "playing" || payload["class"] === "paused" ? payload["class"] : "stopped"
  if (state === "stopped") return stopped
  var volume = Number(payload.percentage)
  return {
    state: state,
    volume: isFinite(volume) ? Math.max(0, Math.min(150, Math.round(volume))) : -1,
    title: clip(payload.tooltip, MAX_TITLE)
  }
}

// `lofi list` prints section headings flush left, then "%3d  title[  · channel]"
// rows. Favorites carry their channel after "  · "; other rows take it from
// the heading above them.
function parseList(raw) {
  var lines = String(raw || "").split("\n")
  var rows = []
  var section = ""
  var inFavorites = false
  for (var i = 0; i < lines.length && rows.length < MAX_ROWS; i++) {
    var line = lines[i]
    if (line.trim() === "") continue
    var match = /^\s*(\d+)  (.*)$/.exec(line)
    if (!match) {
      section = clip(line.trim(), 120)
      inFavorites = section === "Favorites"
      continue
    }
    var title = match[2]
    var channel = section
    if (inFavorites) {
      var mark = title.lastIndexOf("  · ")
      if (mark >= 0) {
        channel = title.slice(mark + 4)
        title = title.slice(0, mark)
      }
    }
    var sectionName = inFavorites ? "Favorites" : clip(section, 120)
    rows.push({
      firstInSection: rows.length === 0 || rows[rows.length - 1].section !== sectionName,
      number: Number(match[1]),
      title: clip(title, MAX_TITLE),
      channel: clip(channel, 120),
      section: sectionName,
      favorite: inFavorites
    })
  }
  return rows
}

function parseFavorites(raw) {
  return String(raw || "").split("\n").filter(function (line) {
    return line.length > 0
  }).slice(0, MAX_ROWS).map(function (line) {
    return clip(line, MAX_TITLE)
  })
}

// Arguments for `lofi start`: the title selects the stream wherever it sits in
// the list; an all-digit title would be read as a list number, so use the row's.
function startArgs(row) {
  if (!row) return ["start"]
  return ["start", /^\d+$/.test(row.title) ? String(row.number) : row.title]
}

function lastLine(raw) {
  var lines = String(raw || "").trim().split("\n")
  return clip(lines[lines.length - 1].replace(/^lofi:\s*/, ""), 200)
}
