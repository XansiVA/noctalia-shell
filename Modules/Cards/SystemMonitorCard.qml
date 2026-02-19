import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

// Unified system card: monitors CPU, temp, memory, disk
// Adapts layout based on control center orientation and weather card visibility
NBox {
  id: root

  Component.onCompleted: SystemStatService.registerComponent("card-sysmonitor")
  Component.onDestruction: SystemStatService.unregisterComponent("card-sysmonitor")

  readonly property string diskPath: Settings.data.controlCenter.diskPath || "/"
  readonly property real contentScale: 0.95 * Style.uiScaleRatio
  
  // Determine if we should use horizontal layout
  // CRITICAL: Horizontal ONLY when control center is horizontal AND weather card is NOT active
  readonly property bool shouldUseHorizontalLayout: {
    // First check: Control center must be in horizontal mode
    if (!Settings.data.controlCenter.horizontalLayout) {
      return false;
    }
    
    // Second check: Weather card must be disabled
    for (var i = 0; i < Settings.data.controlCenter.cards.length; i++) {
      if (Settings.data.controlCenter.cards[i].id === "weather-card") {
        const weatherActive = Settings.data.controlCenter.cards[i].enabled && Settings.data.location.weatherEnabled;
        // Return true (horizontal) only if weather is NOT active
        return !weatherActive;
      }
    }
    
    // Default: if weather card not found in config, assume it's safe to go horizontal
    return true;
  }

  Item {
    id: content
    anchors.fill: parent
    anchors.margins: Style.marginS

    // Vertical Layout (original - used in vertical mode or when weather card is active)
    Column {
      id: verticalLayout
      visible: !root.shouldUseHorizontalLayout
      anchors.fill: parent

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: cpuUsageGauge
          anchors.centerIn: parent
          ratio: SystemStatService.cpuUsage / 100
          icon: "cpu-usage"
          contentScale: root.contentScale
          fillColor: SystemStatService.cpuColor
          tooltipText: I18n.tr("system-monitor.cpu-usage") + `: ${Math.round(SystemStatService.cpuUsage)}%`
        }

        Connections {
          target: SystemStatService
          function onCpuUsageChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === cpuUsageGauge) {
              TooltipService.updateText(I18n.tr("system-monitor.cpu-usage") + `: ${Math.round(SystemStatService.cpuUsage)}%`);
            }
          }
        }
      }

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: cpuTempGauge
          anchors.centerIn: parent
          ratio: SystemStatService.cpuTemp / 100
          suffix: "°C"
          icon: "cpu-temperature"
          contentScale: root.contentScale
          fillColor: SystemStatService.tempColor
          tooltipText: I18n.tr("system-monitor.cpu-temp") + `: ${Math.round(SystemStatService.cpuTemp)}°C`
        }

        Connections {
          target: SystemStatService
          function onCpuTempChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === cpuTempGauge) {
              TooltipService.updateText(I18n.tr("system-monitor.cpu-temp") + `: ${Math.round(SystemStatService.cpuTemp)}°C`);
            }
          }
        }
      }

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: memPercentGauge
          anchors.centerIn: parent
          ratio: SystemStatService.memPercent / 100
          icon: "memory"
          contentScale: root.contentScale
          fillColor: SystemStatService.memColor
          tooltipText: I18n.tr("common.memory") + `: ${Math.round(SystemStatService.memPercent)}%`
        }

        Connections {
          target: SystemStatService
          function onMemPercentChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === memPercentGauge) {
              TooltipService.updateText(I18n.tr("common.memory") + `: ${Math.round(SystemStatService.memPercent)}%`);
            }
          }
        }
      }

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: diskPercentsGauge
          anchors.centerIn: parent
          ratio: (SystemStatService.diskPercents[root.diskPath] ?? 0) / 100
          icon: "storage"
          contentScale: root.contentScale
          fillColor: SystemStatService.getDiskColor(root.diskPath)
          tooltipText: I18n.tr("system-monitor.disk") + `: ${SystemStatService.diskPercents[root.diskPath] || 0}%\n${root.diskPath}`
        }

        Connections {
          target: SystemStatService
          function onDiskPercentsChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === diskPercentsGauge) {
              TooltipService.updateText(I18n.tr("system-monitor.disk") + `: ${SystemStatService.diskPercents[root.diskPath] || 0}%\n${root.diskPath}`);
            }
          }
        }
      }
    }

    // Horizontal Layout (new - used ONLY when control center is horizontal AND weather is disabled)
    // ZIGZAG PATTERN: top, bottom, top, bottom!
    Row {
      id: horizontalLayout
      visible: root.shouldUseHorizontalLayout
      anchors.fill: parent
      spacing: Style.marginM

      // CPU - TOP
      Item {
        width: (parent.width - (Style.marginM * 3)) / 4
        height: parent.height

        NCircleStat {
          id: cpuUsageGaugeH
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: -parent.height * 0.15  // Offset upward (closer to center)
          ratio: SystemStatService.cpuUsage / 100
          icon: "cpu-usage"
          contentScale: root.contentScale * 1.6 // Bigger in horizontal mode
          fillColor: SystemStatService.cpuColor
          tooltipText: I18n.tr("system-monitor.cpu-usage") + `: ${Math.round(SystemStatService.cpuUsage)}%`
        }

        Connections {
          target: SystemStatService
          function onCpuUsageChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === cpuUsageGaugeH) {
              TooltipService.updateText(I18n.tr("system-monitor.cpu-usage") + `: ${Math.round(SystemStatService.cpuUsage)}%`);
            }
          }
        }
      }

      // TEMP - BOTTOM
      Item {
        width: (parent.width - (Style.marginM * 3)) / 4
        height: parent.height

        NCircleStat {
          id: cpuTempGaugeH
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: parent.height * 0.15  // Offset downward (closer to center)
          ratio: SystemStatService.cpuTemp / 100
          suffix: "°C"
          icon: "cpu-temperature"
          contentScale: root.contentScale * 1.6 // Bigger in horizontal mode
          fillColor: SystemStatService.tempColor
          tooltipText: I18n.tr("system-monitor.cpu-temp") + `: ${Math.round(SystemStatService.cpuTemp)}°C`
        }

        Connections {
          target: SystemStatService
          function onCpuTempChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === cpuTempGaugeH) {
              TooltipService.updateText(I18n.tr("system-monitor.cpu-temp") + `: ${Math.round(SystemStatService.cpuTemp)}°C`);
            }
          }
        }
      }

      // MEMORY - TOP
      Item {
        width: (parent.width - (Style.marginM * 3)) / 4
        height: parent.height

        NCircleStat {
          id: memPercentGaugeH
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: -parent.height * 0.15  // Offset upward (closer to center)
          ratio: SystemStatService.memPercent / 100
          icon: "memory"
          contentScale: root.contentScale * 1.6 // Bigger in horizontal mode
          fillColor: SystemStatService.memColor
          tooltipText: I18n.tr("common.memory") + `: ${Math.round(SystemStatService.memPercent)}%`
        }

        Connections {
          target: SystemStatService
          function onMemPercentChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === memPercentGaugeH) {
              TooltipService.updateText(I18n.tr("common.memory") + `: ${Math.round(SystemStatService.memPercent)}%`);
            }
          }
        }
      }

      // DISK - BOTTOM
      Item {
        width: (parent.width - (Style.marginM * 3)) / 4
        height: parent.height

        NCircleStat {
          id: diskPercentsGaugeH
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: parent.height * 0.15  // Offset downward (closer to center)
          ratio: (SystemStatService.diskPercents[root.diskPath] ?? 0) / 100
          icon: "storage"
          contentScale: root.contentScale * 1.6 // Bigger in horizontal mode
          fillColor: SystemStatService.getDiskColor(root.diskPath)
          tooltipText: I18n.tr("system-monitor.disk") + `: ${SystemStatService.diskPercents[root.diskPath] || 0}%\n${root.diskPath}`
        }

        Connections {
          target: SystemStatService
          function onDiskPercentsChanged() {
            if (TooltipService.activeTooltip && TooltipService.activeTooltip.targetItem === diskPercentsGaugeH) {
              TooltipService.updateText(I18n.tr("system-monitor.disk") + `: ${SystemStatService.diskPercents[root.diskPath] || 0}%\n${root.diskPath}`);
            }
          }
        }
      }
    }
  }
}
