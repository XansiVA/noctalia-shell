import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Cards
import qs.Modules.MainScreen
import qs.Services.Media
import qs.Services.UI
import qs.Widgets

SmartPanel {
  id: root

  // Get horizontal layout setting from Settings
  readonly property bool horizontalLayout: Settings.data.controlCenter.horizontalLayout

  // Check if media card is enabled (needed for width calculation)
  readonly property bool hasMediaCard: {
    for (var i = 0; i < Settings.data.controlCenter.cards.length; i++) {
      if (Settings.data.controlCenter.cards[i].id === "media-sysmon-card") {
        return Settings.data.controlCenter.cards[i].enabled;
      }
    }
    return false;
  }

  // Positioning
  readonly property string controlCenterPosition: Settings.data.controlCenter.position

  // Check if there's a bar on this screen
  readonly property bool hasBarOnScreen: {
    var monitors = Settings.data.bar.monitors || [];
    return monitors.length === 0 || monitors.includes(screen?.name);
  }

  // When position is "close_to_bar_button" but there's no bar, fall back to center
  readonly property bool shouldCenter: controlCenterPosition === "close_to_bar_button" && !hasBarOnScreen

  panelAnchorHorizontalCenter: shouldCenter || (controlCenterPosition !== "close_to_bar_button" && (controlCenterPosition.endsWith("_center") || controlCenterPosition === "center"))
  panelAnchorVerticalCenter: shouldCenter || controlCenterPosition === "center"
  panelAnchorLeft: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_left")
  panelAnchorRight: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_right")
  panelAnchorBottom: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("bottom_")
  panelAnchorTop: !shouldCenter && controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("top_")

  // Adaptive dimensions based on layout orientation
  preferredWidth: {
    if (!horizontalLayout) {
      return Math.round(440 * Style.uiScaleRatio);
    }
    // In horizontal mode, use fixed width because setting it to lower breaks it!
    return Math.round(800 * Style.uiScaleRatio);
  }

  preferredHeight: {
    if (horizontalLayout) {
      return Math.round(350 * Style.uiScaleRatio);
    } else {
      var height = 0;
      var count = 0;
      for (var i = 0; i < Settings.data.controlCenter.cards.length; i++) {
        const card = Settings.data.controlCenter.cards[i];
        if (!card.enabled)
          continue;
        const contributes = (card.id !== "weather-card" || Settings.data.location.weatherEnabled);
        if (!contributes)
          continue;
        count++;
        switch (card.id) {
        case "profile-card":
          height += profileHeight;
          break;
        case "shortcuts-card":
          height += shortcutsHeight;
          break;
        case "audio-card":
          height += audioHeight;
          break;
        case "brightness-card":
          height += brightnessHeight;
          break;
        case "weather-card":
          height += weatherHeight;
          break;
        case "media-sysmon-card":
          height += mediaSysMonHeight;
          break;
        default:
          break;
        }
      }
      return height + (count + 1) * Style.marginL;
    }
  }

  readonly property int profileHeight: Math.round(64 * Style.uiScaleRatio)
  readonly property int shortcutsHeight: Math.round(52 * Style.uiScaleRatio)
  readonly property int audioHeight: Math.round(60 * Style.uiScaleRatio)
  readonly property int brightnessHeight: Math.round(60 * Style.uiScaleRatio)
  readonly property int mediaSysMonHeight: Math.round(260 * Style.uiScaleRatio)

  // We keep a dynamic weather height due to a more complex layout and font scaling
  property int weatherHeight: Math.round(210 * Style.uiScaleRatio)

  onOpened: {
    MediaService.autoSwitchingPaused = true;
  }

  onClosed: {
    MediaService.autoSwitchingPaused = false;
  }

  panelContent: Item {
    id: panelContent

    // Vertical Layout (original)
    ColumnLayout {
      id: verticalLayout
      visible: !root.horizontalLayout
      x: Style.marginL
      y: Style.marginL
      width: parent.width - (Style.marginL * 2)
      spacing: Style.marginL

      Repeater {
        model: Settings.data.controlCenter.cards
        Loader {
          active: modelData.enabled && (modelData.id !== "weather-card" || Settings.data.location.weatherEnabled)
          visible: active
          Layout.fillWidth: true
          Layout.preferredHeight: {
            switch (modelData.id) {
            case "profile-card":
              return profileHeight;
            case "shortcuts-card":
              return shortcutsHeight;
            case "audio-card":
              return audioHeight;
            case "brightness-card":
              return brightnessHeight;
            case "weather-card":
              return weatherHeight;
            case "media-sysmon-card":
              return mediaSysMonHeight;
            default:
              return 0;
            }
          }
          sourceComponent: {
            switch (modelData.id) {
            case "profile-card":
              return profileCard;
            case "shortcuts-card":
              return shortcutsCard;
            case "audio-card":
              return audioCard;
            case "brightness-card":
              return brightnessCard;
            case "weather-card":
              return weatherCard;
            case "media-sysmon-card":
              return mediaSysMonCard;
            }
          }
        }
      }
    }

    // Horizontal Layout - Dynamic Grid
    Item {
      id: horizontalLayoutContainer
      visible: root.horizontalLayout
      anchors.fill: parent
      anchors.margins: Style.marginL

      // Calculate enabled cards
      readonly property bool hasMedia: getCardEnabled("media-sysmon-card")
      readonly property bool hasSysmon: getCardEnabled("media-sysmon-card")
      readonly property bool hasWeather: getCardEnabled("weather-card") && Settings.data.location.weatherEnabled
      readonly property bool hasAudio: getCardEnabled("audio-card")
      readonly property bool hasShortcuts: getCardEnabled("shortcuts-card")
      readonly property bool hasBrightness: getCardEnabled("brightness-card")
      readonly property bool hasProfile: getCardEnabled("profile-card")

      // Count top row items for dynamic width calculation
      readonly property int topRowCount: (hasShortcuts ? 1 : 0) + (hasProfile ? 1 : 0)

      readonly property int topRowHeight: {
        if (!topRowCount) return 0;
        return Math.max(root.shortcutsHeight, root.profileHeight);
      }

      // Calculate available width for columns
      readonly property real mediaWidth: hasMedia ? Math.round(parent.width * 0.30) : 0
      readonly property real sysmonWidth: hasSysmon ? Math.round(75 * Style.uiScaleRatio) : 0

      // Top Row - Shortcuts and Profile (spans full width including over media area)
      // Shortcuts - spans from left edge
      Loader {
        id: shortcutsLoader
        active: horizontalLayoutContainer.hasShortcuts
        visible: active
        anchors.left: parent.left
        anchors.top: parent.top
        width: active ? Math.round(430 * Style.uiScaleRatio) : 0
        height: horizontalLayoutContainer.topRowHeight
        sourceComponent: shortcutsCard
      }

      // Profile Card - fills remaining width to the right
      Loader {
        id: profileLoader
        active: horizontalLayoutContainer.hasProfile
        visible: active
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: shortcutsLoader.active ? shortcutsLoader.right : parent.left
        anchors.leftMargin: shortcutsLoader.active ? Style.marginL : 0
        height: horizontalLayoutContainer.topRowHeight
        sourceComponent: profileCard
      }

      // Left column - Media Card (starts below shortcuts/profile row)
      Item {
        id: mediaColumn
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: horizontalLayoutContainer.topRowCount > 0 ? (Math.max(root.shortcutsHeight, root.profileHeight) + Style.marginL) : 0
        anchors.bottom: parent.bottom
        width: horizontalLayoutContainer.mediaWidth
        visible: width > 0

        Loader {
          active: horizontalLayoutContainer.hasMedia
          visible: active
          anchors.fill: parent
          sourceComponent: mediaCardOnly
        }
      }

      // Middle column - Weather + Audio/Brightness row
      Item {
        id: middleColumn
        anchors.left: mediaColumn.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: horizontalLayoutContainer.topRowCount > 0 ? (Math.max(root.shortcutsHeight, root.profileHeight) + Style.marginL) : 0
        anchors.bottom: parent.bottom
        anchors.leftMargin: horizontalLayoutContainer.hasMedia ? Style.marginL : 0
        anchors.rightMargin: (horizontalLayoutContainer.hasSysmon && horizontalLayoutContainer.hasWeather) ? (horizontalLayoutContainer.sysmonWidth + Style.marginL) : 0

        // Weather Card - fills remaining space in middle column
        Loader {
          id: weatherLoader
          active: horizontalLayoutContainer.hasWeather
          visible: active
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: audioBrightnessRow.height > 0 ? audioBrightnessRow.top : parent.bottom
          anchors.bottomMargin: audioBrightnessRow.height > 0 ? Style.marginL : 0
          sourceComponent: weatherCard
        }

        // Audio + Brightness Row - at the bottom with reasonable height
        Row {
          id: audioBrightnessRow
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: {
            if (!(horizontalLayoutContainer.hasAudio || horizontalLayoutContainer.hasBrightness)) return 0;
            return root.audioHeight;
          }
          spacing: Style.marginL

          // Audio Card - takes half width if brightness enabled, full width otherwise
          Loader {
            id: audioLoader
            active: horizontalLayoutContainer.hasAudio
            visible: active
            width: {
              if (!active) return 0;
              if (brightnessLoader.active) {
                return (parent.width - Style.marginL) / 2;
              }
              return parent.width;
            }
            height: parent.height
            sourceComponent: audioCard
          }

          // Brightness Card - takes half width when both enabled
          Loader {
            id: brightnessLoader
            active: horizontalLayoutContainer.hasBrightness
            visible: active
            width: {
              if (!active) return 0;
              if (audioLoader.active) {
                return (parent.width - Style.marginL) / 2;
              }
              return parent.width;
            }
            height: parent.height
            sourceComponent: brightnessCard
          }
        }
      }

      // Right column - System Monitor (vertical mode when weather exists)
      Item {
        id: sysmonColumn
        visible: horizontalLayoutContainer.hasSysmon && horizontalLayoutContainer.hasWeather
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: horizontalLayoutContainer.topRowCount > 0 ? (Math.max(root.shortcutsHeight, root.profileHeight) + Style.marginL) : 0
        width: horizontalLayoutContainer.sysmonWidth

        Loader {
          active: horizontalLayoutContainer.hasSysmon && horizontalLayoutContainer.hasWeather
          visible: active
          anchors.fill: parent
          sourceComponent: systemMonitorOnly
        }
      }

      // System Monitor Horizontal - spans below top row when no weather
      Loader {
        id: sysmonHorizontal
        active: horizontalLayoutContainer.hasSysmon && !horizontalLayoutContainer.hasWeather
        visible: active
        anchors.left: horizontalLayoutContainer.hasMedia ? mediaColumn.right : parent.left
        anchors.leftMargin: horizontalLayoutContainer.hasMedia ? Style.marginL : 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: (horizontalLayoutContainer.topRowCount > 0 ? Math.max(root.shortcutsHeight, root.profileHeight) : 0) + Style.marginL
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (horizontalLayoutContainer.hasAudio || horizontalLayoutContainer.hasBrightness) ? (root.audioHeight + Style.marginL) : 0
        sourceComponent: systemMonitorOnly
      }
    }
  }

  // Helper function to check if a card is enabled
  function getCardEnabled(cardId) {
    for (var i = 0; i < Settings.data.controlCenter.cards.length; i++) {
      if (Settings.data.controlCenter.cards[i].id === cardId) {
        return Settings.data.controlCenter.cards[i].enabled;
      }
    }
    return false;
  }

  Component {
    id: profileCard
    ProfileCard {}
  }

  Component {
    id: shortcutsCard
    ShortcutsCard {}
  }

  Component {
    id: audioCard
    AudioCard {}
  }

  Component {
    id: brightnessCard
    BrightnessCard {}
  }

  Component {
    id: weatherCard
    WeatherCard {
      Component.onCompleted: {
        root.weatherHeight = this.height;
      }
    }
  }

  Component {
    id: mediaSysMonCard
    RowLayout {
      spacing: Style.marginL

      // Media card
      MediaCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }

      // System monitors combined in one card
      SystemMonitorCard {
        Layout.preferredWidth: Math.round(Style.baseWidgetSize * 2.625)
        Layout.fillHeight: true
      }
    }
  }

  // Media card only (for horizontal layout)
  Component {
    id: mediaCardOnly
    MediaCard {}
  }

  // System monitor only (for horizontal layout)
  Component {
    id: systemMonitorOnly
    SystemMonitorCard {}
  }
}
