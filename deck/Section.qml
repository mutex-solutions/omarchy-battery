import QtQuick

// Deck adapter: the five members Deck reads, forwarded to the shared State.
// Tap toggles the limit (on = the remembered value, off = 100%); hold opens
// the page. Deck hands the page `state`, so tile and page read one object.
Item {
  id: s

  readonly property var state: stateLoader.item

  readonly property bool active: state ? state.active : false
  readonly property string label: state ? state.label : "Battery"
  readonly property string detail: state ? state.detail : ""
  readonly property string icon: state ? state.icon : "󰁹"

  function toggle() {
    if (state) state.toggle()
  }

  Loader {
    id: stateLoader
    source: "../State.qml"
  }
}
