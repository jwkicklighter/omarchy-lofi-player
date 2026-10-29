// Run: node tests/model.test.js
const fs = require("fs")
const path = require("path")
const assert = require("assert")

const source = fs.readFileSync(path.join(__dirname, "..", "LofiModel.js"), "utf8").replace(/^\.pragma library\s*/, "")
const Model = new Function(source + "\nreturn { parseStatus, parseList, parseFavorites, startArgs, lastLine, INSTALL_COMMAND }")()

// status
assert.deepStrictEqual(Model.parseStatus('{"text":"▶ 60%","class":"playing","tooltip":"synthwave radio","percentage":60}'),
  { state: "playing", volume: 60, title: "synthwave radio" })
assert.strictEqual(Model.parseStatus('{"text":"⏸ 40%","class":"paused","tooltip":"x","percentage":40}').state, "paused")
assert.deepStrictEqual(Model.parseStatus('{"text":"","class":"stopped","tooltip":"lofi: stopped"}'),
  { state: "stopped", volume: -1, title: "" })
assert.strictEqual(Model.parseStatus("garbage").state, "stopped")
assert.strictEqual(Model.parseStatus("").state, "stopped")
assert.strictEqual(Model.parseStatus('{"class":"playing","tooltip":"' + "a".repeat(1000) + '"}').title.length, 300)

// list
const list = [
  "Favorites",
  "  1  synthwave radio 🌌 beats to chill/game to  · Lofi Girl",
  "",
  "Lofi Girl",
  "  2  24/7 halloween ambience 🎃 spooky lofi",
  "  3  lofi hip hop radio 📚 beats to relax/study to",
  "",
  "Chillhop Music",
  " 10  1984",
  ""
].join("\n")
const rows = Model.parseList(list)
assert.strictEqual(rows.length, 4)
assert.deepStrictEqual(rows[0], { firstInSection: true, number: 1, title: "synthwave radio 🌌 beats to chill/game to",
  channel: "Lofi Girl", section: "Favorites", favorite: true })
assert.deepStrictEqual([rows[1].firstInSection, rows[1].channel, rows[1].favorite], [true, "Lofi Girl", false])
assert.strictEqual(rows[2].firstInSection, false)
assert.deepStrictEqual([rows[3].number, rows[3].section, rows[3].firstInSection], [10, "Chillhop Music", true])
assert.deepStrictEqual(Model.parseList(""), [])

// markup-shaped input stays plain data (the panel renders it with Text.PlainText)
const markup = Model.parseList('Evil\n  1  <img src="https://example.invalid/t">')
assert.strictEqual(markup[0].title, '<img src="https://example.invalid/t">')

// start args: titles pass as one argv element; all-digit titles fall back to the row number
assert.deepStrictEqual(Model.startArgs(rows[1]), ["start", rows[1].title])
assert.deepStrictEqual(Model.startArgs(rows[3]), ["start", "10"])
assert.deepStrictEqual(Model.startArgs(null), ["start"])

assert.deepStrictEqual(Model.parseFavorites("a\nb\n"), ["a", "b"])
assert.strictEqual(Model.lastLine("noise\nlofi: not running\n"), "not running")
assert.ok(Model.INSTALL_COMMAND.startsWith("curl -fsSL https://github.com/jwkicklighter/lofi-player/"))

console.log("ok")
