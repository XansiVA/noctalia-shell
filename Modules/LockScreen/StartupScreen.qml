import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

// Startup/Splash screen that displays while Noctalia is initializing
Loader {
  id: root

  // Desired visibility
  property bool shouldBeActive: Settings.splashRunning

  // Keep loaded until fade-out completes
  active: opacity > 0.0
  opacity: shouldBeActive ? 1.0 : 0.0

Behavior on opacity {
  NumberAnimation {
    duration: root.shouldBeActive ? 200 : 500
    easing.type: Easing.InOutQuad
  }
}


  Component.onCompleted: {
    Logger.i("StartupScreen", "Startup screen initialized")
  }

  onShouldBeActiveChanged: {
    if (!shouldBeActive) {
      Logger.i("StartupScreen", "Startup screen fading out")
    }
  }

  onActiveChanged: {
    if (!active) {
      Logger.i("StartupScreen", "Startup screen unloaded")
    }
  }

  sourceComponent: Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      required property ShellScreen modelData

      color: Color.transparent
      screen: modelData

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "noctalia-startup-" + (screen?.name || "unknown")

      anchors {
        top: true
        bottom: true
        right: true
        left: true
      }

      // ---- FADE TARGET ----
      Item {
        anchors.fill: parent
        opacity: root.opacity

        // Background
        Rectangle {
          anchors.fill: parent
          color: Color.mSurface
        }

        // Subtle gradient overlay
        Rectangle {
          anchors.fill: parent
          color: "transparent"
          gradient: Gradient {
            GradientStop {
              position: 0.0
              color: Qt.alpha(Color.mPrimary, 0.05)
            }
            GradientStop {
              position: 1.0
              color: "transparent"
            }
          }
        }

        // Center content
        Item {
          anchors.centerIn: parent
          width: 300
          height: 300

          // Noctalia Logo
          NImageRounded {
            anchors.centerIn: parent
            width: 120
            height: 120
            radius: 20
            imagePath: Quickshell.shellDir + "/Assets/noctalia.svg"
            fallbackIcon: "rocket"
            fallbackIconSize: 80

            SequentialAnimation on scale {
              loops: Animation.Infinite
              NumberAnimation {
                to: 1.05
                duration: 1500
                easing.type: Easing.InOutQuad
              }
              NumberAnimation {
                to: 1.0
                duration: 1500
                easing.type: Easing.InOutQuad
              }
            }
          }

          // Spinner
          Canvas {
            anchors.centerIn: parent
            width: 180
            height: 180
            antialiasing: true

            property real rotation: 0

            RotationAnimator on rotation {
              from: 0
              to: 360
              duration: 1500
              loops: Animation.Infinite
              running: true
            }

            onRotationChanged: requestPaint()

            onPaint: {
              var ctx = getContext("2d")
              if (!ctx) return

              ctx.reset()
              ctx.clearRect(0, 0, width, height)

              var cx = width / 2
              var cy = height / 2
              var r = 80
              var lw = 4

              ctx.translate(cx, cy)
              ctx.rotate(rotation * Math.PI / 180)
              ctx.translate(-cx, -cy)

              var grad = ctx.createLinearGradient(cx - r, cy, cx + r, cy)
              grad.addColorStop(0, Color.mPrimary)
              grad.addColorStop(1, Qt.alpha(Color.mPrimary, 0.2))

              ctx.beginPath()
              ctx.arc(cx, cy, r, 0, Math.PI * 1.5)
              ctx.strokeStyle = grad
              ctx.lineWidth = lw
              ctx.lineCap = "round"
              ctx.stroke()
            }
          }

          // Title
          NText {
            anchors.top: parent.verticalCenter
            anchors.topMargin: 120
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Noctalia"
            pointSize: Style.fontSizeXL
            font.weight: Font.Bold
            color: Color.mOnSurface

            SequentialAnimation on opacity {
              loops: Animation.Infinite
              NumberAnimation {
                to: 0.6
                duration: 1200
                easing.type: Easing.InOutQuad
              }
              NumberAnimation {
                to: 1.0
                duration: 1200
                easing.type: Easing.InOutQuad
              }
            }
          }
        }
      }
    }
  }
}
