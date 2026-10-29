import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "LofiModel.js" as Model

BarWidget {
  id: root
  moduleName: "jwkicklighter.lofi-player"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property int pollMs: Math.max(1, Number(root.settings && root.settings.refreshIntervalSec) || 3) * 1000
  readonly property bool showVolume: !!(root.settings && root.settings.showVolume)

  // Where `lofi` lives: "" until detection finishes, then a path or "missing".
  property string lofiPath: ""
  readonly property bool checked: root.lofiPath !== ""
  readonly property bool installed: root.checked && root.lofiPath !== "missing"
  property bool installing: false
  property int installChecks: 0

  property string playState: "stopped"
  property int volume: -1
  property string title: ""
  property string lastTitle: ""
  readonly property bool playing: root.playState === "playing"
  readonly property bool active: root.playState !== "stopped"

  property var streams: []
  property bool streamsLoaded: false
  property string streamsError: ""
  property bool streamsStale: false
  readonly property bool streamsLoading: listProc.running
  property var favorites: []
  readonly property bool currentFavorite: root.title !== "" && root.favorites.indexOf(root.title) !== -1

  property string lastError: ""
  readonly property bool addingChannel: addProc.running
  signal channelAdded(bool ok, string message)
  property string pendingTitle: ""
  property var queue: []

  readonly property string statePath: {
    var override = Quickshell.env("LOFI_STATE")
    if (override) return override
    var base = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
    return base + "/lofi/last.json"
  }

  readonly property string glyph: root.installed ? "󰝚" : "󰝛"
  readonly property string barText: root.showVolume && root.active && root.volume >= 0
    ? root.glyph + " " + Commons.I18n.formatNumber(root.volume) + "%"
    : root.glyph

  function detect() {
    if (!detectProc.running) detectProc.running = true
  }

  function lofiCommand(args) {
    return [root.installed ? root.lofiPath : "lofi"].concat(args)
  }

  // Actions run one at a time, in order, so a quick toggle then stop can't race.
  function run(args) {
    if (!root.installed) return
    root.queue = root.queue.concat([args])
    root.drain()
  }

  function drain() {
    if (actionProc.running || root.queue.length === 0) return
    var next = root.queue[0]
    root.queue = root.queue.slice(1)
    root.lastError = ""
    actionProc.args = next
    actionProc.command = root.lofiCommand(next)
    actionProc.running = true
  }

  function refreshStatus() {
    if (root.installed && !statusProc.running) statusProc.running = true
  }

  function refreshStreams() {
    if (!root.installed || listProc.running) return
    root.streamsError = ""
    listProc.command = root.lofiCommand(["list"])
    listProc.running = true
  }

  function refreshFavorites() {
    if (!root.installed || favoritesProc.running) return
    favoritesProc.command = root.lofiCommand(["favorite", "list"])
    favoritesProc.running = true
  }

  // `lofi add` takes a channel URL, @handle, or a stream URL. It runs on its own
  // process, since the yt-dlp lookup can take a few seconds.
  function addChannel(what) {
    var query = String(what || "").trim()
    if (!root.installed || addProc.running || query === "") return
    addProc.command = root.lofiCommand(["add", query])
    addProc.running = true
  }

  function playPause() {
    if (root.active) run(["toggle"])
    else {
      root.pendingTitle = root.lastTitle
      run(["start"])
    }
  }

  function stop() { if (root.active) run(["stop"]) }

  function startStream(row) {
    root.pendingTitle = row ? row.title : ""
    run(Model.startArgs(row))
  }

  function nudgeVolume(delta) {
    if (!root.active) return
    run(["vol", (delta > 0 ? "+" : "-") + Math.abs(delta)])
  }

  function setVolume(value) {
    if (!root.active) return
    root.volume = Math.round(value)
    run(["vol", String(Math.round(value))])
  }

  function toggleFavorite() {
    if (!root.title) return
    run(["favorite", root.currentFavorite ? "remove" : "add"])
  }

  function copyInstallCommand() {
    Quickshell.execDetached(["wl-copy", "--", Model.INSTALL_COMMAND])
  }

  function installForMe() {
    Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", Model.INSTALL_COMMAND])
    root.installing = true
    root.installChecks = 0
  }

  function onInstalled() {
    root.installing = false
    root.refreshStatus()
    root.refreshFavorites()
    if (root.opened) root.refreshStreams()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = Qt.binding(function() { return root.bar })
    target.settings = Qt.binding(function() { return root.settings })
    target.anchorItem = button
    target.hostWidget = root
    target.strings = strings
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }

  onOpenedChanged: {
    if (!root.opened) return
    if (!root.installed) root.detect()
    else {
      root.refreshStatus()
      root.refreshFavorites()
      if (!root.streamsLoaded) root.refreshStreams()
    }
  }

  onInstalledChanged: if (root.installed) root.onInstalled()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Component.onCompleted: root.detect()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    horizontalMargin: 6
    dimmed: !root.playing
    tooltipText: !root.checked ? strings.t("bar.checking")
      : !root.installed ? strings.t("bar.missing")
      : root.active ? strings.t(root.playing ? "bar.playing" : "bar.paused").arg(root.title)
      : strings.t("bar.stopped")
    onPressed: function(pressedButton) {
      if (pressedButton === Qt.LeftButton || !root.installed) root.togglePanel()
      else if (pressedButton === Qt.MiddleButton) root.stop()
      else root.playPause()
    }
    onWheelMoved: function(delta) {
      root.nudgeVolume(delta > 0 ? 5 : -5)
    }
  }

  Process {
    id: detectProc
    // The shell's PATH comes from login; also look where the installer puts lofi,
    // so a fresh install is picked up without logging out.
    command: ["sh", "-c", "command -v lofi || { p=\"$HOME/.local/bin/lofi\"; [ -x \"$p\" ] && echo \"$p\"; }"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var found = String(text || "").trim().split("\n")[0]
        root.lofiPath = found && found.charAt(0) === "/" ? found : "missing"
      }
    }
  }

  // After "Install for me", watch for the script to land (up to ten minutes).
  Timer {
    interval: 2000
    repeat: true
    running: root.installing && !root.installed
    onTriggered: {
      root.installChecks += 1
      if (root.installChecks > 300) root.installing = false
      root.detect()
    }
  }

  Timer {
    interval: root.opened ? 1000 : root.pollMs
    repeat: true
    running: root.installed
    triggeredOnStart: true
    onTriggered: root.refreshStatus()
  }

  Process {
    id: statusProc
    command: root.lofiCommand(["status"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var status = Model.parseStatus(text)
        root.playState = status.state
        root.title = status.title
        if (status.volume >= 0 || status.state === "stopped") root.volume = status.volume
      }
    }
    onExited: function(exitCode) {
      // A missing script (removed since detection) sends us back to setup.
      if (exitCode === 127) root.lofiPath = "missing"
    }
  }

  Process {
    id: actionProc
    property var args: []
    command: []
    stderr: StdioCollector { id: actionErr; waitForEnd: true }
    onExited: function(exitCode) {
      var verb = actionProc.args[0]
      if (exitCode !== 0) {
        root.lastError = Model.lastLine(actionErr.text) || strings.t("error.generic").arg(verb)
        root.pendingTitle = ""
      } else if (verb === "start") {
        root.pendingTitle = ""
      }
      if (verb === "favorite") root.refreshFavorites()
      root.refreshStatus()
      root.drain()
    }
  }

  Process {
    id: addProc
    command: []
    stdout: StdioCollector { id: addOut; waitForEnd: true }
    stderr: StdioCollector { id: addErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.channelAdded(true, Model.lastLine(addOut.text))
        if (listProc.running) root.streamsStale = true
        else root.refreshStreams()
      } else {
        root.channelAdded(false, Model.lastLine(addErr.text) || strings.t("error.generic").arg("add"))
      }
    }
  }

  Process {
    id: listProc
    command: []
    stdout: StdioCollector { id: listOut; waitForEnd: true }
    stderr: StdioCollector { id: listErr; waitForEnd: true }
    onExited: function(exitCode) {
      root.streams = exitCode === 0 ? Model.parseList(listOut.text) : []
      root.streamsError = exitCode === 0 ? "" : Model.lastLine(listErr.text)
      root.streamsLoaded = true
      if (root.streamsStale) {
        root.streamsStale = false
        root.refreshStreams()
      }
    }
  }

  Process {
    id: favoritesProc
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.favorites = Model.parseFavorites(text)
    }
  }

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var last = JSON.parse(text())
        root.lastTitle = last && typeof last.title === "string" ? last.title.slice(0, 300) : ""
      } catch (error) {
        root.lastTitle = ""
      }
    }
  }
}
