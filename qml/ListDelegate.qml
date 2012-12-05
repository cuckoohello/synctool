// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0
import "UIConstants.js" as UI

Item {
    id: listItem

    signal clicked
    property alias pressed: mouse_area.pressed

    property int titleSize: 26
    property int titleWeight: Font.Bold
    property color titleColor: theme.inverted ? "#ffffff" : "#282828"

    property int subtitleSize: 22
    property int subtitleWeight: Font.Light
    property color subtitleColor: theme.inverted ? "#d2d2d2" : "#505050"

    height: row.height+20
    width: parent.width

    Rectangle {
        id: background
        z: -1
        anchors.fill: parent
        color: '#2A8EE0'
        visible: mouse_area.pressed
    }

    Row {
        id: row
        width: parent.width  - UI.NORMAL_MARGIN
        anchors.centerIn: parent
        spacing: 18

        Loader {
            sourceComponent: model.iconSource?icon_com:null
        }

        Column {
            id: column
            Label {
                id: mainText
                text: model.title
                font.weight: listItem.titleWeight
                font.pixelSize: listItem.titleSize
                color: listItem.titleColor
            }
            Row {
                spacing: 10
                Repeater {
                    model: subtitle.count
                    Label {
                        text: subtitle.get(index).title
                        font.weight: listItem.subtitleWeight
                        font.pixelSize: listItem.subtitleSize
                        color: listItem.subtitleColor
                    }
                }
            }
        }
    }

    Component {
        id: icon_com

        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: column.height
            height: column.height
            source: model.iconSource
        }
    }

    MouseArea {
        id: mouse_area
        anchors.fill: parent
        onClicked: {
            listItem.clicked();
        }
    }
}

