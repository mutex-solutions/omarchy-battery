import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "../Model.js" as M

// Battery page, laid out like Omarchy's own battery panel (panels/power):
// hero (icon · title/state · percentage), the charge bar, a two-column facts
// grid, a separator, then bordered buttons under a section header — the same
// components (qs.Ui Button / PanelSectionHeader / PanelSeparator), so it reads
// as part of Omarchy. What that panel only shows, this one can change.
Item {
  id: page

  property var state: null
  property var host: null

  readonly property var st: state
  readonly property color fg: Color.foreground
  readonly property string family: Style.font.family
  readonly property bool ready: !!st && st.present
  readonly property var snap: st ? st.snapshot : ({})

  implicitHeight: column.implicitHeight

  component InfoPair: Row {
    property string label: ""
    property string value: ""
    width: parent.width
    spacing: Style.space(8)
    InfoLabel { text: label }
    Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
    InfoValue { text: value }
  }
  component InfoLabel: Text {
    textFormat: Text.PlainText
    color: page.fg
    opacity: 0.6
    font.family: page.family
    font.pixelSize: Style.font.bodySmall
  }
  component InfoValue: Text {
    textFormat: Text.PlainText
    color: page.fg
    font.family: page.family
    font.pixelSize: Style.font.bodySmall
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(14)

    // ---------- Hero ----------
    Item {
      width: parent.width
      implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroPercent.implicitHeight)

      Text {
        id: heroIcon
        textFormat: Text.PlainText
        text: page.st ? page.st.icon : "󰁹"
        color: page.fg
        font.family: page.family
        font.pixelSize: Style.font.display
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        id: heroLabels
        anchors.left: heroIcon.right
        anchors.leftMargin: Style.space(14)
        anchors.right: heroPercent.left
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Text {
          text: "Battery"
          textFormat: Text.PlainText
          color: page.fg
          font.family: page.family
          font.pixelSize: Style.font.title
          font.bold: true
          elide: Text.ElideRight
          width: parent.width
        }

        Text {
          textFormat: Text.PlainText
          text: (page.ready ? (page.st.restoreTo > 0 ? "Charging to 100% once" : M.stateText(page.snap)) : "No charge limit").toUpperCase()
          color: Qt.darker(page.fg, 1.4)
          font.family: page.family
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
          elide: Text.ElideRight
          width: parent.width
        }
      }

      Text {
        id: heroPercent
        textFormat: Text.PlainText
        text: page.st && page.st.capacity >= 0 ? page.st.capacity + "%" : "—"
        color: page.fg
        font.family: page.family
        font.pixelSize: Style.font.displayLarge
        font.bold: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    // ---------- Charge bar, with a tick at the limit ----------
    Item {
      width: parent.width
      implicitHeight: Style.space(8)

      Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(page.fg.r, page.fg.g, page.fg.b, 0.12)
      }

      Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        height: track.height
        radius: track.radius
        color: page.fg
        width: Math.max(track.height, track.width * Math.max(0, Math.min(1, (page.st ? page.st.capacity : 0) / 100)))
        Behavior on width { NumberAnimation { duration: Style.duration(320); easing.type: Easing.OutCubic } }
      }

      // Where charging stops.
      Rectangle {
        visible: page.ready && page.st.limitOn
        x: Math.round(track.width * (page.st ? page.st.end : 100) / 100) - width / 2
        anchors.verticalCenter: track.verticalCenter
        width: Math.max(2, Style.space(2))
        height: track.height + Style.space(6)
        radius: width / 2
        color: Color.accent
      }
    }

    // ---------- Facts ----------
    Row {
      visible: page.ready
      width: parent.width
      spacing: Style.space(20)

      Column {
        width: (parent.width - parent.spacing) / 2
        spacing: Style.spacing.labelGap
        InfoPair { label: "Battery size"; value: page.st ? M.wh(page.st.energyFull) : "—" }
        InfoPair { label: "Charge cycles"; value: page.st && page.st.cycles >= 0 ? String(page.st.cycles) : "—" }
        InfoPair { label: "Health"; value: page.st ? (M.health(page.st.energyFull, page.st.energyDesign) || "—") : "—" }
      }

      Column {
        width: (parent.width - parent.spacing) / 2
        spacing: Style.spacing.labelGap
        InfoPair { label: "Charge limit"; value: page.st ? M.limitText(page.st.start, page.st.end) : "—" }
        InfoPair { label: "Battery state"; value: page.ready ? M.stateText(page.snap) : "—" }
        InfoPair { label: "Power"; value: page.st && page.st.onAC ? "Plugged in" : "On battery" }
      }
    }

    PanelSeparator { foreground: page.fg }

    // ---------- Charge limit ----------
    Column {
      width: parent.width
      spacing: Style.space(10)
      visible: page.ready

      PanelSectionHeader {
        text: "Charge limit"
        foreground: page.fg
        fontFamily: page.family
      }

      Row {
        id: limitRow
        width: parent.width
        spacing: Style.space(6)
        readonly property real cellWidth: (width - spacing * (M.LIMITS.length - 1)) / M.LIMITS.length

        Repeater {
          model: M.LIMITS
          Button {
            required property int modelData
            width: limitRow.cellWidth
            text: modelData >= 100 ? "Off" : modelData + "%"
            fontSize: Style.font.bodySmall
            foreground: page.fg
            fontFamily: page.family
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            active: !!page.st && page.st.end === modelData && page.st.restoreTo === 0
            onClicked: if (page.st) page.st.setLimit(modelData)
          }
        }
      }

      Row {
        id: actionRow
        width: parent.width
        spacing: Style.space(6)
        readonly property int count: page.st && page.st.canPause ? 2 : 1
        readonly property real cellWidth: (width - spacing * (count - 1)) / count

        Button {
          width: actionRow.cellWidth
          iconText: "󰂅"
          iconSize: Style.font.title
          text: page.st && page.st.restoreTo > 0 ? "Cancel 100%" : "100% once"
          fontSize: Style.font.bodySmall
          foreground: page.fg
          fontFamily: page.family
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          active: !!page.st && page.st.restoreTo > 0
          visible: !!page.st && (page.st.limitOn || page.st.restoreTo > 0)
          onClicked: {
            if (!page.st) return
            if (page.st.restoreTo > 0) page.st.cancelFullOnce()
            else page.st.chargeFullOnce()
          }
        }

        Button {
          width: actionRow.cellWidth
          visible: !!page.st && page.st.canPause
          iconText: "󰏤"
          iconSize: Style.font.title
          text: "Pause charging"
          fontSize: Style.font.bodySmall
          foreground: page.fg
          fontFamily: page.family
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          active: !!page.st && page.st.paused
          onClicked: if (page.st) page.st.setPaused(!page.st.paused)
        }
      }

      Text {
        width: parent.width
        visible: !!page.st && page.st.limitOn && page.st.start > 0
        text: "Charging stops at " + (page.st ? page.st.end : "") + "% and resumes below " + (page.st ? page.st.start : "") + "%."
        textFormat: Text.PlainText
        color: page.fg
        opacity: 0.55
        font.family: page.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
      }

      Text {
        width: parent.width
        visible: !!page.st && page.st.error !== ""
        text: page.st ? page.st.error : ""
        textFormat: Text.PlainText
        color: Color.urgent
        font.family: page.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.Wrap
      }
    }

    // ---------- Helper not installed ----------
    Column {
      width: parent.width
      spacing: Style.space(8)
      visible: page.ready && !page.st.helperReady

      Text {
        width: parent.width
        text: "Changing the limit needs a small root helper (once):"
        textFormat: Text.PlainText
        color: page.fg
        opacity: 0.7
        font.family: page.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
      }

      Button {
        width: parent.width
        leftAlign: true
        text: "bash ~/.config/omarchy/plugins/mutex-solutions.battery/scripts/install-helper.sh"
        fontSize: Style.font.caption
        foreground: page.fg
        fontFamily: page.family
        bordered: true
        tooltipText: "Copy"
        onClicked: Quickshell.execDetached(["wl-copy", "bash ~/.config/omarchy/plugins/mutex-solutions.battery/scripts/install-helper.sh"])
      }
    }

    Text {
      width: parent.width
      visible: !!page.st && !page.st.present
      text: "This laptop's firmware exposes no charge limit (no charge_control_end_threshold)."
      textFormat: Text.PlainText
      color: page.fg
      opacity: 0.6
      font.family: page.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.Wrap
    }
  }
}
