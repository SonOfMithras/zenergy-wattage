import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kquickcontrols as KQuickControls

Item {
    id: page
    width: 400
    height: 500

    property alias cfg_backgroundColorMode: backgroundColorModeCombo.currentIndex
    property int cfg_appletBackgroundMode: 0 // Bound to RadioButtons
    property alias cfg_customBackgroundColor: customColorButton.color
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_fontFamily: fontLoader.currentText
    property alias cfg_fontSize: fontSizeSpinBox.value
    property alias cfg_textBold: textBoldCheckBox.checked
    property alias cfg_textItalic: textItalicCheckBox.checked
    property alias cfg_textUnderline: textUnderlineCheckBox.checked
    property alias cfg_textPosition: textPositionCombo.currentIndex
    property alias cfg_showGraph: showGraphCheckBox.checked
    property alias cfg_graphDuration: graphDurationSpinBox.value
    property alias cfg_graphColorMode: graphColorModeCombo.currentIndex
    property alias cfg_graphLineColor: graphLineColorButton.color
    property alias cfg_graphLineWidth: graphLineWidthSpinBox.value
    property alias cfg_textColorMode: textColorModeCombo.currentIndex
    property alias cfg_customTextColor: customTextColorButton.color

    ScrollView {
        anchors.fill: parent
        // anchors.margins: 10 // Move margins to ColumnLayout or keep here? 
        // Better to have ScrollView fill parent and ColumnLayout have width of ScrollView
        
        ColumnLayout {
            width: parent.width - 20 // Account for scrollbar and margins
            x: 10
            y: 10
            spacing: 10

            Label {
                text: "Applet Background"
                font.bold: true
            }
            
            ColumnLayout {
                spacing: 0
                RadioButton {
                    text: "Default"
                    checked: page.cfg_appletBackgroundMode === 0
                    onToggled: if (checked) page.cfg_appletBackgroundMode = 0
                }
                RadioButton {
                    text: "Transparent"
                    checked: page.cfg_appletBackgroundMode === 1
                    onToggled: if (checked) page.cfg_appletBackgroundMode = 1
                }
                RadioButton {
                    text: "Transparent with shadow"
                    checked: page.cfg_appletBackgroundMode === 2
                    onToggled: if (checked) page.cfg_appletBackgroundMode = 2
                }
            }
 
            Label {
                text: "Text Settings"
                font.bold: true
                Layout.topMargin: 10
            }

            RowLayout {
                Label { text: "Font Family:" }
                ComboBox {
                    id: fontLoader
                    model: Qt.fontFamilies()
                    Layout.fillWidth: true
                    
                    // Set initial value
                    Component.onCompleted: {
                        var idx = find(page.cfg_fontFamily)
                        if (idx !== -1) currentIndex = idx
                    }
                }
            }

            RowLayout {
                Label { text: "Font Size:" }
                SpinBox {
                    id: fontSizeSpinBox
                    from: 8
                    to: 72
                    value: 24
                }
            }

            RowLayout {
                CheckBox {
                    id: textBoldCheckBox
                    text: "Bold"
                }
                CheckBox {
                    id: textItalicCheckBox
                    text: "Italic"
                }
                CheckBox {
                    id: textUnderlineCheckBox
                    text: "Underline"
                }
            }

            RowLayout {
                Label { text: "Color Mode:" }
                ComboBox {
                    id: textColorModeCombo
                    model: ["System Theme", "Custom Color"]
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: textColorModeCombo.currentIndex === 1
                Label { text: "Custom Color:" }
                KQuickControls.ColorButton {
                    id: customTextColorButton
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Label { text: "Position:" }
                ComboBox {
                    id: textPositionCombo
                    model: ["Overlay on Graph", "Below Graph", "Above Graph"]
                    Layout.fillWidth: true
                }
            }

            Label {
                text: "Graph Settings"
                font.bold: true
                Layout.topMargin: 10
            }

            CheckBox {
                id: showGraphCheckBox
                text: "Show Wattage Graph"
            }

            RowLayout {
                visible: showGraphCheckBox.checked
                Label { text: "Duration (min):" }
                SpinBox {
                    id: graphDurationSpinBox
                    from: 1
                    to: 10
                    value: 5
                }
            }

            RowLayout {
                visible: showGraphCheckBox.checked
                Label { text: "Line Color Mode:" }
                ComboBox {
                    id: graphColorModeCombo
                    model: ["System Theme", "Custom Color"]
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: showGraphCheckBox.checked && graphColorModeCombo.currentIndex === 1
                Label { text: "Line Color:" }
                KQuickControls.ColorButton {
                    id: graphLineColorButton
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: showGraphCheckBox.checked
                Label { text: "Line Width:" }
                SpinBox {
                    id: graphLineWidthSpinBox
                    from: 1
                    to: 5
                    value: 2
                }
            }

            RowLayout {
                Label { text: "Graph Background:" }
                ComboBox {
                    id: backgroundColorModeCombo
                    model: ["System Theme", "Transparent", "Custom Color"]
                    Layout.fillWidth: true
                }
            }
           
//            Label {
//                text: "Content Appearance"
//                font.bold: true
//            }

            RowLayout {
                visible: backgroundColorModeCombo.currentIndex === 2
                Label { text: "Color:" }
                KQuickControls.ColorButton {
                    id: customColorButton
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: backgroundColorModeCombo.currentIndex === 2
                Label { text: "Opacity (%):" }
                Slider {
                    id: opacitySlider
                    from: 0
                    to: 100
                    stepSize: 1
                    Layout.fillWidth: true
                }
                Label {
                    text: opacitySlider.value.toFixed(0) + "%"
                    Layout.minimumWidth: 40
                }
            }

            Item { Layout.fillHeight: true } // Spacer
        }
    }
}
