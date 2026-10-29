import QtQuick
import qs.Commons
import qs.Ui
import "LofiModel.js" as Model

Panel {
  id: root
  moduleName: "jwkicklighter.lofi-player"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var strings: null
  property bool copied: false

  readonly property var host: hostWidget
  readonly property var barIdentity: hostWidget || root
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color foregroundColor: bar ? bar.barForeground : Color.foreground
  readonly property color mutedColor: Util.alpha(foregroundColor, 0.6)
  readonly property color faintColor: Util.alpha(foregroundColor, 0.38)
  readonly property color accentColor: Color.accent
  readonly property int rowHeight: Math.max(30, Style.spacing.controlHeight)
  readonly property int listCap: Style.space(300)

  readonly property bool installed: host ? host.installed : false
  readonly property bool checked: host ? host.checked : false

  function t(key) {
    return root.strings ? root.strings.t(key) : key
  }

  function open() { controller.show() }
  function close() { controller.hide() }

  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { popoutSwitchClosing = false })
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function copyCommand() {
    if (host) host.copyInstallCommand()
    root.copied = true
    copiedTimer.restart()
  }

  Timer {
    id: copiedTimer
    interval: 2000
    onTriggered: root.copied = false
  }

  component PlainText: Text {
    textFormat: Text.PlainText
    color: root.foregroundColor
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
          root.bar.switchPanelFrom(root.barIdentity, direction)
      }

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          height: Math.max(Style.font.title + Style.spacing.xxs, refreshButton.height)

          PlainText {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.t("panel.title")
            font.pixelSize: Style.font.title
            font.bold: true
          }

          PanelActionButton {
            id: refreshButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.installed
            enabled: root.host ? !root.host.streamsLoading : false
            iconText: "󰑐"
            tooltipText: root.t("panel.refresh")
            foreground: root.foregroundColor
            hoverColor: root.accentColor
            fontFamily: root.fontFamily
            fontSize: Style.font.subtitle
            size: Style.space(26)
            onClicked: if (root.host) root.host.refreshStreams()
          }
        }

        PanelSeparator {
          width: parent.width
          foreground: root.foregroundColor
        }

        // --- setup: lofi isn't installed --------------------------------------

        Column {
          width: parent.width
          spacing: Style.spacing.controlGap
          visible: root.checked && !root.installed

          PlainText {
            width: parent.width
            text: root.t("setup.heading")
            font.bold: true
            wrapMode: Text.WordWrap
          }

          PlainText {
            width: parent.width
            text: root.t("setup.verify")
            color: root.mutedColor
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Item { width: 1; height: Style.spacing.xxs }

          PanelSectionHeader {
            text: root.t("setup.commandHeader")
            foreground: root.foregroundColor
            fontFamily: root.fontFamily
          }

          Rectangle {
            width: parent.width
            height: commandRow.implicitHeight + Style.spacing.md * 2
            radius: Style.cornerRadius
            color: Util.alpha(root.foregroundColor, 0.07)
            border.width: 1
            border.color: Util.alpha(root.foregroundColor, 0.14)

            Row {
              id: commandRow
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.spacing.rowPaddingX
              anchors.rightMargin: Style.spacing.xxs
              spacing: Style.spacing.md

              PlainText {
                id: commandText
                width: parent.width - copyButton.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                text: Model.INSTALL_COMMAND
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WrapAnywhere
              }

              Button {
                id: copyButton
                anchors.verticalCenter: parent.verticalCenter
                iconText: root.copied ? "󰄬" : "󰆏"
                text: root.copied ? root.t("setup.copied") : root.t("setup.copy")
                tooltipText: root.t("setup.copyTooltip")
                foreground: root.copied ? root.accentColor : root.foregroundColor
                accent: root.accentColor
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                bordered: true
                onClicked: root.copyCommand()
              }
            }
          }

          PlainText {
            width: parent.width
            text: root.t("setup.terminalHint")
            color: root.faintColor
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Item { width: 1; height: Style.spacing.xxs }

          Row {
            width: parent.width
            spacing: Style.spacing.md

            Button {
              width: (parent.width - parent.spacing) / 2
              iconText: "󰇚"
              text: root.host && root.host.installing ? root.t("setup.installing") : root.t("setup.install")
              selected: true
              enabled: root.host ? !root.host.installing : false
              foreground: root.foregroundColor
              accent: root.accentColor
              fontFamily: root.fontFamily
              bordered: true
              onClicked: if (root.host) root.host.installForMe()
            }

            Button {
              width: (parent.width - parent.spacing) / 2
              iconText: "󰑐"
              text: root.t("setup.checkAgain")
              foreground: root.foregroundColor
              accent: root.accentColor
              fontFamily: root.fontFamily
              bordered: true
              onClicked: if (root.host) root.host.detect()
            }
          }

          PlainText {
            width: parent.width
            text: root.host && root.host.installing ? root.t("setup.waiting") : root.t("setup.installHint")
            color: root.faintColor
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        // --- player -----------------------------------------------------------

        Column {
          width: parent.width
          spacing: Style.spacing.controlGap
          visible: root.installed

          PanelSectionHeader {
            text: !root.host ? "" : root.host.playing ? root.t("player.playing")
              : root.host.active ? root.t("player.paused") : root.t("player.stopped")
            foreground: root.foregroundColor
            fontFamily: root.fontFamily
          }

          PlainText {
            width: parent.width
            text: !root.host ? ""
              : root.host.pendingTitle ? root.host.pendingTitle
              : root.host.active ? root.host.title
              : root.host.lastTitle ? root.host.lastTitle
              : root.t("player.nothing")
            color: root.host && (root.host.active || root.host.pendingTitle) ? root.foregroundColor : root.mutedColor
            font.bold: !!root.host && root.host.active
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
          }

          PlainText {
            width: parent.width
            visible: !!root.host && !root.host.active && !root.host.pendingTitle && root.host.lastTitle !== ""
            text: root.t("player.resumeHint")
            color: root.faintColor
            font.pixelSize: Style.font.caption
          }

          PlainText {
            width: parent.width
            visible: !!root.host && root.host.pendingTitle !== ""
            text: root.t("player.starting")
            color: root.faintColor
            font.pixelSize: Style.font.caption
          }

          Row {
            width: parent.width
            spacing: Style.spacing.md

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              iconText: root.host && root.host.playing ? "󰏤" : "󰐊"
              text: !root.host ? "" : root.host.playing ? root.t("player.pause")
                : root.host.active ? root.t("player.resume") : root.t("player.play")
              enabled: !!root.host && root.host.pendingTitle === ""
              foreground: root.foregroundColor
              accent: root.accentColor
              fontFamily: root.fontFamily
              bordered: true
              onClicked: root.host.playPause()
            }

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              iconText: "󰓛"
              text: root.t("player.stop")
              enabled: !!root.host && root.host.active
              foreground: root.foregroundColor
              accent: root.accentColor
              fontFamily: root.fontFamily
              bordered: true
              onClicked: root.host.stop()
            }

            Button {
              width: (parent.width - parent.spacing * 2) / 3
              iconText: root.host && root.host.currentFavorite ? "󰓎" : "󰓒"
              text: root.host && root.host.currentFavorite ? root.t("player.unfavorite") : root.t("player.favorite")
              selected: !!root.host && root.host.currentFavorite
              enabled: !!root.host && root.host.active && root.host.title !== ""
              foreground: root.foregroundColor
              accent: root.accentColor
              fontFamily: root.fontFamily
              bordered: true
              onClicked: root.host.toggleFavorite()
            }
          }

          Row {
            width: parent.width
            spacing: Style.spacing.md
            opacity: root.host && root.host.active ? 1 : 0.4
            enabled: !!root.host && root.host.active

            PlainText {
              id: volumeIcon
              anchors.verticalCenter: parent.verticalCenter
              text: "󰕾"
              font.pixelSize: Style.font.icon
            }

            PanelSlider {
              id: volumeSlider
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - volumeIcon.width - volumeLabel.width - parent.spacing * 2
              bar: root.bar
              minimum: 0
              maximum: 100
              step: 1
              integer: true
              value: root.host && root.host.volume >= 0 ? Math.min(100, root.host.volume) : 0
              onReleased: function(value) { root.host.setVolume(value) }
            }

            PlainText {
              id: volumeLabel
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(40)
              horizontalAlignment: Text.AlignRight
              text: root.host && root.host.volume >= 0
                ? I18n.formatNumber(Math.round(volumeSlider.liveValue)) + "%" : "—"
              color: root.mutedColor
              font.pixelSize: Style.font.bodySmall
            }
          }

          PlainText {
            width: parent.width
            visible: !!root.host && root.host.lastError !== ""
            text: root.host ? root.host.lastError : ""
            color: Color.urgent
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          PanelSeparator {
            width: parent.width
            foreground: root.foregroundColor
          }

          PanelSectionHeader {
            text: root.t("streams.header")
            foreground: root.foregroundColor
            fontFamily: root.fontFamily
          }

          PlainText {
            width: parent.width
            visible: !!root.host && (root.host.streamsLoading || root.host.streamsError !== ""
              || (root.host.streamsLoaded && root.host.streams.length === 0))
            text: !root.host ? ""
              : root.host.streamsLoading ? root.t("streams.loading")
              : root.host.streamsError !== "" ? root.host.streamsError
              : root.t("streams.none")
            color: root.host && root.host.streamsError !== "" && !root.host.streamsLoading ? Color.urgent : root.faintColor
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Flickable {
            id: streamList
            width: parent.width
            height: Math.min(streamColumn.implicitHeight, root.listCap)
            visible: !!root.host && root.host.streams.length > 0
            contentHeight: streamColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
              id: streamColumn
              width: streamList.width
              spacing: Style.spacing.xxs

              Repeater {
                model: root.host ? root.host.streams : []

                delegate: Column {
                  id: streamEntry
                  required property var modelData
                  width: streamColumn.width
                  spacing: Style.spacing.xxs

                  readonly property bool isCurrent: !!root.host && root.host.active && modelData.title === root.host.title
                  readonly property bool isFavorite: !!root.host && root.host.favorites.indexOf(modelData.title) !== -1

                  PlainText {
                    width: parent.width
                    visible: streamEntry.modelData.firstInSection
                    topPadding: Style.spacing.sm
                    text: streamEntry.modelData.favorite ? root.t("streams.favorites") : streamEntry.modelData.section
                    color: root.mutedColor
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Rectangle {
                    width: parent.width
                    height: root.rowHeight
                    radius: Style.cornerRadius
                    color: streamEntry.isCurrent
                      ? Style.selectedAccentFill
                      : (mouse.containsMouse ? Style.hoverFillFor(root.foregroundColor, root.accentColor) : "transparent")

                    Behavior on color { ColorAnimation { duration: Style.duration(80) } }

                    Row {
                      anchors.fill: parent
                      anchors.leftMargin: Style.spacing.rowPaddingX
                      anchors.rightMargin: Style.spacing.rowPaddingX
                      spacing: Style.spacing.md

                      PlainText {
                        id: rowGlyph
                        width: Style.space(16)
                        anchors.verticalCenter: parent.verticalCenter
                        text: streamEntry.isCurrent ? (root.host.playing ? "󰐊" : "󰏤") : (streamEntry.isFavorite ? "󰓎" : "")
                        color: root.accentColor
                        font.pixelSize: Style.font.bodySmall
                      }

                      PlainText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - rowGlyph.width - parent.spacing
                        text: streamEntry.modelData.favorite
                          ? streamEntry.modelData.title + "  ·  " + streamEntry.modelData.channel
                          : streamEntry.modelData.title
                        color: streamEntry.isCurrent ? root.accentColor : root.foregroundColor
                        font.pixelSize: Style.font.bodySmall
                        elide: Text.ElideRight
                      }
                    }

                    MouseArea {
                      id: mouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (streamEntry.isCurrent) root.host.playPause()
                        else root.host.startStream(streamEntry.modelData)
                      }
                    }
                  }
                }
              }
            }
          }

          PlainText {
            width: parent.width
            text: root.t("streams.hint")
            color: root.faintColor
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        PlainText {
          width: parent.width
          visible: !root.checked
          text: root.t("bar.checking")
          color: root.faintColor
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}
