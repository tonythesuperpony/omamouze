import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "omamouze"
  ipcTarget: "omamouze"
  manageIpc: false

  IpcHandler {
    target: "omamouze"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.fetchState() }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Path to backend CLI
  readonly property string ctlScript: Quickshell.env("HOME") + "/.config/omarchy/plugins/omamouze/bin/omamouze-ctl"

  // State data
  property var stateData: null
  readonly property var mice: (stateData && stateData.mice) ? stateData.mice : []
  readonly property string activeDevice: (stateData && stateData.activeDevice) ? stateData.activeDevice : ""
  readonly property var activeConfig: (stateData && stateData.activeConfig) ? stateData.activeConfig : ({})
  readonly property int cursorSize: (stateData && stateData.cursorSize) ? stateData.cursorSize : 24
  readonly property var presetActions: (stateData && stateData.presetActions) ? stateData.presetActions : []

  // Active config properties
  readonly property real sensitivity: (activeConfig && activeConfig.sensitivity !== undefined) ? activeConfig.sensitivity : 0.0
  readonly property real scrollFactor: (activeConfig && activeConfig.scrollFactor !== undefined) ? activeConfig.scrollFactor : 1.0
  readonly property int baseDpi: (activeConfig && activeConfig.baseDpi) ? activeConfig.baseDpi : 1200
  readonly property string accelProfile: (activeConfig && activeConfig.accelProfile) ? activeConfig.accelProfile : "flat"
  readonly property var bindings: (activeConfig && activeConfig.bindings) ? activeConfig.bindings : ({})

  // Modal / Action picker state
  property string selectedButtonId: ""
  property string selectedButtonLabel: ""
  property bool showActionPicker: false
  property string customCommandInput: ""

  function fetchState() {
    if (!fetchProc.running) fetchProc.running = true
  }

  // Pending command queue — if actionProc is already running, stash the
  // latest command so it runs when the current one finishes.
  property var pendingCtlCmd: null

  function runCtl(args) {
    var cmd = [root.ctlScript]
    for (var i = 0; i < args.length; i++) {
      cmd.push(String(args[i]))
    }
    if (actionProc.running) {
      root.pendingCtlCmd = cmd
    } else {
      actionProc.command = cmd
      actionProc.running = true
    }
  }

  Component.onCompleted: fetchState()
  onOpenedChanged: if (opened) fetchState()

  // Background refresh timer
  Timer {
    interval: root.opened ? 4000 : 20000
    running: true
    repeat: true
    onTriggered: root.fetchState()
  }

  Process {
    id: fetchProc
    command: [root.ctlScript, "get-state"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          root.stateData = parsed
        } catch (e) {}
      }
    }
  }

  Process {
    id: actionProc
    onRunningChanged: {
      if (!running && root.pendingCtlCmd) {
        var next = root.pendingCtlCmd
        root.pendingCtlCmd = null
        actionProc.command = next
        actionProc.running = true
      }
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          root.stateData = parsed
        } catch (e) {}
      }
    }
  }

  // Bar button with mouse icon
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\udb80\udf7d" // Material Design Mouse icon
    active: root.opened
    onPressed: function(b) { root.toggle() }
  }

  // Themed Popup Panel
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight + Style.space(28), Style.space(660))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: {
        if (root.showActionPicker) {
          root.showActionPicker = false
        } else {
          root.close()
        }
      }

      Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainColumn.implicitHeight + Style.space(16)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: mainColumn
          width: parent.width
          spacing: Style.space(14)

          // ------------------------------------------------------------- Header
          RowLayout {
            width: parent.width
            spacing: Style.space(10)

            Rectangle {
              width: Style.space(36)
              height: Style.space(36)
              radius: Style.cornerRadius
              color: Style.selectedFillFor(Color.foreground, Color.accent)

              Text {
                anchors.centerIn: parent
                text: "\udb80\udf7d"
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                color: Color.accent
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.space(2)

              Text {
                text: "OmaMouze"
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
                color: Color.foreground
              }

              Text {
                text: root.activeConfig.displayName || root.activeDevice || "Detecting mouse..."
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                color: Qt.darker(Color.foreground, 1.4)
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Button {
              iconText: ""
              tooltipText: "Refresh devices"
              onClicked: root.fetchState()
            }

            Button {
              iconText: "✕"
              tooltipText: "Close panel"
              onClicked: root.close()
            }
          }

          PanelSeparator { width: parent.width }

          // ============================================================= VIEW 1: MAIN PANEL
          Column {
            width: parent.width
            spacing: Style.space(14)
            visible: !root.showActionPicker

            // ----------------------------------------------------------- Detected Mice
            Column {
              width: parent.width
              spacing: Style.space(6)

              PanelSectionHeader {
                text: "CONNECTED MICE"
              }

              Flow {
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: root.mice
                  delegate: Button {
                    text: modelData.displayName
                    iconText: "\udb80\udf7d"
                    selected: modelData.name === root.activeDevice
                    bordered: true
                    onClicked: {
                      root.runCtl(["set-device", modelData.name])
                    }
                  }
                }
              }
            }

            PanelSeparator { width: parent.width }

            // ----------------------------------------------------------- DPI & Sensitivity
            Column {
              width: parent.width
              spacing: Style.space(8)

              RowLayout {
                width: parent.width
                PanelSectionHeader {
                  text: "DPI & SENSITIVITY"
                  Layout.fillWidth: true
                }

                Text {
                  readonly property int effDpi: Math.round(root.baseDpi * (1.0 + root.sensitivity))
                  text: effDpi + " DPI (" + (root.sensitivity >= 0 ? "+" : "") + Number(root.sensitivity).toFixed(2) + ")"
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  color: Color.accent
                }
              }

              // Base DPI row
              RowLayout {
                width: parent.width
                spacing: Style.space(6)

                Text {
                  text: "Sensor Base:"
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  color: Qt.darker(Color.foreground, 1.4)
                }

                Flow {
                  Layout.fillWidth: true
                  spacing: Style.space(4)

                  Repeater {
                    model: [400, 800, 1200, 1600, 2400, 3200]
                    delegate: Button {
                      text: String(modelData)
                      selected: root.baseDpi === modelData
                      bordered: true
                      onClicked: {
                        root.runCtl(["set-dpi", root.sensitivity, root.accelProfile, modelData])
                      }
                    }
                  }
                }
              }

              // Sensitivity Slider
              PanelSlider {
                width: parent.width
                bar: root.bar
                minimum: -0.90
                maximum: 1.00
                step: 0.05
                value: root.sensitivity
                onReleased: function(v) {
                  root.runCtl(["set-dpi", v, root.accelProfile, root.baseDpi])
                }
                
                // Block wheel events from changing the slider so the Flickable can scroll
                MouseArea {
                  anchors.fill: parent
                  acceptedButtons: Qt.NoButton
                  onWheel: function(wheel) { wheel.accepted = false }
                }
              }

              // Acceleration profile and Quick Presets
              RowLayout {
                width: parent.width
                spacing: Style.space(6)

                Button {
                  text: "Sniper"
                  tooltipText: "Low sensitivity (-0.50)"
                  selected: Math.abs(root.sensitivity - (-0.50)) < 0.05
                  bordered: true
                  onClicked: root.runCtl(["set-dpi", -0.50, root.accelProfile, root.baseDpi])
                }

                Button {
                  text: "Balanced"
                  tooltipText: "Default 1:1 sensitivity (0.00)"
                  selected: Math.abs(root.sensitivity) < 0.05
                  bordered: true
                  onClicked: root.runCtl(["set-dpi", 0.00, root.accelProfile, root.baseDpi])
                }

                Button {
                  text: "Fast"
                  tooltipText: "Fast sensitivity (+0.50)"
                  selected: Math.abs(root.sensitivity - 0.50) < 0.05
                  bordered: true
                  onClicked: root.runCtl(["set-dpi", 0.50, root.accelProfile, root.baseDpi])
                }

                Item { Layout.fillWidth: true }

                Button {
                  text: root.accelProfile === "flat" ? "Profile: Flat (Raw 1:1)" : "Profile: Adaptive"
                  tooltipText: "Click to toggle acceleration profile"
                  bordered: true
                  onClicked: {
                    var nextProfile = root.accelProfile === "flat" ? "adaptive" : "flat"
                    root.runCtl(["set-dpi", root.sensitivity, nextProfile, root.baseDpi])
                  }
                }
              }
            }

            PanelSeparator { width: parent.width }

            // ----------------------------------------------------------- Scrolling Speed & Cursor Size
            RowLayout {
              width: parent.width
              spacing: Style.space(12)

              // Scroll Speed
              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.space(6)

                RowLayout {
                  Layout.fillWidth: true
                  PanelSectionHeader { text: "SCROLL SPEED"; Layout.fillWidth: true }
                  Text {
                    readonly property int lines: Math.round(root.scrollFactor * 3)
                    text: Number(root.scrollFactor).toFixed(1) + "x (~" + lines + " lines)"
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: Color.accent
                  }
                }

                PanelSlider {
                  Layout.fillWidth: true
                  bar: root.bar
                  minimum: 0.40
                  maximum: 3.00
                  step: 0.20
                  value: root.scrollFactor
                  onReleased: function(v) {
                    root.runCtl(["set-scroll", v])
                  }
                  
                  // Block wheel events from changing the slider so the Flickable can scroll
                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(wheel) { wheel.accepted = false }
                  }
                }
              }

              // Cursor Size
              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.space(6)

                RowLayout {
                  Layout.fillWidth: true
                  PanelSectionHeader { text: "CURSOR SIZE"; Layout.fillWidth: true }
                }

                Dropdown {
                  Layout.fillWidth: true
                  showLabel: false
                  value: String(root.cursorSize)
                  options: [
                    { value: "16", label: "16 px (Smallest)" },
                    { value: "20", label: "20 px (Small)" },
                    { value: "24", label: "24 px (Default)" },
                    { value: "28", label: "28 px (Medium)" },
                    { value: "32", label: "32 px (Large)" }
                  ]
                  onChanged: function(val) {
                    root.runCtl(["set-cursor", val])
                  }
                }
              }
            }

            PanelSeparator { width: parent.width }

            // ----------------------------------------------------------- Buttons Assigned & Visual Indicators
            Column {
              width: parent.width
              spacing: Style.space(8)

              RowLayout {
                width: parent.width
                PanelSectionHeader {
                  text: "BUTTON ASSIGNMENTS"
                  Layout.fillWidth: true
                }

                Text {
                  text: "Click any button to assign action"
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  color: Qt.darker(Color.foreground, 1.4)
                }
              }

              // Visual Button Matrix with Status Indicators
              Column {
                width: parent.width
                spacing: Style.space(6)

                // Define standard mouse buttons
                readonly property var mouseButtonsList: [
                  { "id": "275", "name": "Side Back (Button 4)", "icon": "", "desc": "Usually Thumb Back" },
                  { "id": "276", "name": "Side Forward (Button 5)", "icon": "", "desc": "Usually Thumb Forward" },
                  { "id": "274", "name": "Middle Click (Wheel)", "icon": "", "desc": "Wheel Press" },
                  { "id": "277", "name": "Extra Button (Button 6)", "icon": "", "desc": "Gesture or Top DPI switch" },
                  { "id": "272", "name": "Left Click", "icon": "", "desc": "Primary Button" },
                  { "id": "273", "name": "Right Click", "icon": "", "desc": "Secondary / Context" }
                ]

                Repeater {
                  model: parent.mouseButtonsList
                  delegate: Rectangle {
                    width: parent.width
                    height: Style.space(44)
                    radius: Style.cornerRadius
                    color: btnMouseArea.containsMouse ? Style.hoverFillFor(Color.foreground, Color.accent) : "transparent"
                    border.width: 1
                    border.color: hasBinding ? Color.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.15)

                    readonly property var bindingInfo: root.bindings ? root.bindings[modelData.id] : null
                    readonly property bool hasBinding: bindingInfo !== null && bindingInfo !== undefined

                    MouseArea {
                      id: btnMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.selectedButtonId = modelData.id
                        root.selectedButtonLabel = modelData.name
                        root.customCommandInput = (hasBinding && bindingInfo.cmd) ? bindingInfo.cmd : ""
                        root.showActionPicker = true
                      }
                    }

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: Style.space(10)
                      spacing: Style.space(10)

                      // Visual status indicator dot
                      Rectangle {
                        width: Style.space(8)
                        height: Style.space(8)
                        radius: 4
                        color: hasBinding ? Color.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.3)
                      }

                      // Button icon + name
                      Text {
                        text: modelData.icon + "  " + modelData.name
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        color: Color.foreground
                      }

                      Text {
                        text: modelData.desc
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                        color: Qt.darker(Color.foreground, 1.6)
                        visible: parent.width > Style.space(320)
                      }

                      Item { Layout.fillWidth: true }

                      // Action badge
                      Rectangle {
                        height: Style.space(24)
                        width: actionBadgeText.implicitWidth + Style.space(16)
                        radius: Style.cornerRadius
                        color: hasBinding ? Style.selectedFillFor(Color.foreground, Color.accent) : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)

                        Text {
                          id: actionBadgeText
                          anchors.centerIn: parent
                          text: hasBinding ? bindingInfo.label : "Default"
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption
                          font.bold: hasBinding
                          color: hasBinding ? Color.accent : Qt.darker(Color.foreground, 1.4)
                        }
                      }

                      Text {
                        text: "✎"
                        font.pixelSize: Style.font.caption
                        color: Qt.darker(Color.foreground, 1.4)
                      }
                    }
                  }
                }
              }
            }
          }

          // ============================================================= VIEW 2: ACTION PICKER
          Column {
            width: parent.width
            spacing: Style.space(12)
            visible: root.showActionPicker

            RowLayout {
              width: parent.width
              spacing: Style.space(8)

              Button {
                iconText: ""
                tooltipText: "Back to overview"
                onClicked: root.showActionPicker = false
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.space(2)

                Text {
                  text: "Assign: " + root.selectedButtonLabel
                  font.family: Style.font.family
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                  color: Color.foreground
                }

                Text {
                  text: "Choose an action or enter a custom command"
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  color: Qt.darker(Color.foreground, 1.4)
                }
              }

              Button {
                text: "Reset to Default"
                bordered: true
                onClicked: {
                  root.runCtl(["clear-binding", root.selectedButtonId])
                  root.showActionPicker = false
                }
              }
            }

            PanelSeparator { width: parent.width }

            // Preset Action Groups
            Text {
              text: "PRESET ACTIONS"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              color: Qt.darker(Color.foreground, 1.4)
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.presetActions
                delegate: Button {
                  text: modelData.label
                  bordered: true
                  onClicked: {
                    root.runCtl(["set-binding", root.selectedButtonId, modelData.label, modelData.cmd, modelData.id])
                    root.showActionPicker = false
                  }
                }
              }
            }

            PanelSeparator { width: parent.width }

            // Custom Command Field
            Text {
              text: "CUSTOM SHELL COMMAND / SHORTCUT"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              color: Qt.darker(Color.foreground, 1.4)
            }

            RowLayout {
              width: parent.width
              spacing: Style.space(6)

              TextField {
                id: customInput
                Layout.fillWidth: true
                text: root.customCommandInput
                placeholderText: "e.g. wtype -M ctrl -k c -m ctrl or alacritty"
                onTextChanged: root.customCommandInput = text
              }

              Button {
                text: "Apply Command"
                selected: true
                onClicked: {
                  if (root.customCommandInput.trim() !== "") {
                    root.runCtl(["set-binding", root.selectedButtonId, "Custom Command", root.customCommandInput.trim(), "custom"])
                    root.showActionPicker = false
                  }
                }
              }
            }
          }

          // ------------------------------------------------------------- Footer
          PanelSeparator { width: parent.width }

          RowLayout {
            width: parent.width

            Text {
              text: "● Hyprland native · Instant apply"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              color: Qt.darker(Color.foreground, 1.6)
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "v1.0.0"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              color: Qt.darker(Color.foreground, 1.8)
            }
          }
        }
      }
    }
  }
}
