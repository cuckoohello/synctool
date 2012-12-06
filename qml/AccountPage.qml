// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import "./UIConstants.js" as UI

Page {
    orientationLock: PageOrientation.LockPortrait
    property alias username: usernameText.text
    property alias password: passwordText.text
    property alias imapserver: imapText.text

    tools : ToolBarLayout {
        visible: true

        Row{
            anchors{
                verticalCenter:parent.verticalCenter
                horizontalCenter : parent.horizontalCenter
            }
            spacing : UI.NORMAL_MARGIN
            ToolButton {
                text: qsTr("Save")
                enabled: usernameText.text != '' && passwordText.text != '' && imapText.text != ''
                onClicked: {
                    syncTool.saveAccountSettings(usernameText.text,passwordText.text,imapText.text)
                    pageStack.pop()
                }
            }
            ToolButton {
                text: qsTr("Cancel")
                onClicked: pageStack.pop()
            }
        }
    }

    Header {
        id: header
        color: UI.HEADER_COLOR
        content: qsTr("Account")
    }

    Flickable {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentHeight: accountColumn.height

        Column {
            id: accountColumn
            spacing : UI.SMALL_MARGIN

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: UI.NORMAL_MARGIN
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Username")
            }

            TextField {
                id: usernameText
                anchors.right : parent.right
                anchors.left : parent.left
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Password")
            }

            TextField {
                id: passwordText
                anchors.right : parent.right
                anchors.left : parent.left
                echoMode: TextInput.Password
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("IMAP Server")
            }

            TextField {
                id: imapText
                anchors.right : parent.right
                anchors.left : parent.left
                placeholderText: 'imap.gmail.com'
            }
        }
    }
}
