import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Ui
import qs.Commons

// Standalone bar widget. Click opens the same page Deck renders. Run this or
// the Deck section, not both: each would keep its own "100% once" watch.
Panel {
  id: root

  moduleName: "mutex-solutions.battery"
  ipcTarget: "mutex-solutions.battery"

  readonly property var state: stateLoader.item

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: stateLoader
    source: "State.qml"
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.state ? root.state.icon : ""
    active: root.state ? root.state.active : false
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(Math.min(content.implicitHeight, Style.space(560)), Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.close()
    }

    ScrollView {
      id: scroll
      anchors.fill: parent
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: ScrollBar.AlwaysOff

      Column {
        id: content
        width: scroll.availableWidth

        Loader {
          id: pageLoader
          width: parent.width
          active: root.opened
          source: "deck/Page.qml"
          onLoaded: if (item) item.state = root.state
        }
      }
    }
  }

  onStateChanged: if (pageLoader.item) pageLoader.item.state = root.state
  onOpenedChanged: if (root.opened && root.state) root.state.refresh()
}
