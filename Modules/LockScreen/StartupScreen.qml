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
  active: Settings.splashRunning

  Component.onCompleted: {
    Logger.i("StartupScreen", "Startup screen initialized");
  }

  onActiveChanged: {
    if (!active) {
      Logger.i("StartupScreen", "Startup screen unloaded");
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

      // Background with theme color
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
          id: logo
          anchors.centerIn: parent
          width: 120
          height: 120
          radius: 20
          imagePath: Quickshell.shellDir + "/Assets/noctalia.svg"
          fallbackIcon: "rocket"
          fallbackIconSize: 80

          // Subtle pulsing animation
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

        // Loading spinner around the logo
        Canvas {
          id: spinner
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
            var ctx = getContext("2d");
            if (!ctx) return;

            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var centerX = width / 2;
            var centerY = height / 2;
            var radius = 80;
            var lineWidth = 4;

            // Rotate canvas
            ctx.translate(centerX, centerY);
            ctx.rotate(rotation * Math.PI / 180);
            ctx.translate(-centerX, -centerY);

            // Draw spinner arc
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 1.5);
            ctx.strokeStyle = Color.mPrimary;
            ctx.lineWidth = lineWidth;
            ctx.lineCap = "round";
            ctx.stroke();

            // Gradient effect on spinner
            var gradient = ctx.createLinearGradient(centerX - radius, centerY, centerX + radius, centerY);
            gradient.addColorStop(0, Color.mPrimary);
            gradient.addColorStop(1, Qt.alpha(Color.mPrimary, 0.2));
            
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 1.5);
            ctx.strokeStyle = gradient;
            ctx.lineWidth = lineWidth;
            ctx.lineCap = "round";
            ctx.stroke();
          }
        }

        // Simple loading text
        NText {
          anchors.top: spinner.bottom
          anchors.topMargin: 40
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Noctalia"
          pointSize: Style.fontSizeXL
          font.weight: Font.Bold
          color: Color.mOnSurface

          // Pulsing opacity
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
