import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Noctalia
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  NHeader {
    label: "Startup Screen"
    description: "Customize the appearance and scale of the startup splash screen"
  }

  // Master Scale Slider
  NValueSlider {
    Layout.fillWidth: true
    label: "Splash Screen Scale"
    description: "Adjust the overall size of the startup screen elements (logo and spinner)"
    from: 0.5
    to: 3.0
    stepSize: 0.1
    value: Settings.data.general.splashScale
    isSettings: true
    defaultValue: Settings.getDefaultValue("general.splashScale")
    onMoved: value => Settings.data.general.splashScale = value
    text: value.toFixed(1) + "×"
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  // Info section showing calculated sizes
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NLabel {
      label: "Calculated Sizes"
      description: "These values are automatically calculated based on the scale factor"
    }

    // Logo Size Display
    NLabel {
      Layout.fillWidth: true
      label: "Logo Size"
      description: (125 * Settings.data.general.splashScale).toFixed(0) + " × " + 
                   (125 * Settings.data.general.splashScale).toFixed(0) + " pixels"
    }

    // Spinner Size Display
    NLabel {
      Layout.fillWidth: true
      label: "Spinner Size"
      description: (125 * 4 * Settings.data.general.splashScale).toFixed(0) + " × " + 
                   (125 * 4 * Settings.data.general.splashScale).toFixed(0) + " pixels"
    }
  }

  // Spacer to push everything to the top
  Item {
    Layout.fillHeight: true
  }
}
