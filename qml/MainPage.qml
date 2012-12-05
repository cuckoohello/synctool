import QtQuick 1.1
import com.nokia.meego 1.0
import "UIConstants.js" as UI

Page {
    orientationLock: PageOrientation.LockPortrait
    tools : ToolBarLayout {
        id: commonTools
        visible: true
        ToolIcon{

             id:menuTool
             enabled: true
             iconId: "toolbar-view-menu";
             visible:true

            anchors.verticalCenter:  parent.verticalCenter
            anchors.right: (parent === undefined) ? undefined : parent.right
            onClicked:
            (contentmenu.status === DialogStatus.Closed) ? contentmenu.open() : contentmenu.close()

          }

    }

    Menu{
        id:contentmenu
        opacity: 0.9
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        visualParent: pageStack
        MenuLayout {
        MenuItem {
            text: "Account"
            enabled : !syncTool.isSyncing
            onClicked:goto_page("AccountPage.qml",syncTool.getAccountInfo())}
        MenuItem { text: "Sections"
            enabled : !syncTool.isSyncing
           onClicked:goto_page("SectionsPage.qml")}
        MenuItem { text: "About"
            onClicked:goto_page("AboutPage.qml")}
        MenuItem { text: "Hide"
            onClicked:hideSignal()}
        MenuItem { text: "Exit"
            enabled : !syncTool.isSyncing
          onClicked:quitConfirm.open() }
        }

       }
    Header {
        id: header
        color: UI.HEADER_COLOR
        content: 'SMS/IM/Call Backup'
    }

    Image {
        id: logo
        anchors {
            top: header.bottom
            horizontalCenter: parent.horizontalCenter
            topMargin: UI.NORMAL_MARGIN
        }
        source: syncTool.currentMainIconSource 
        width: parent.width/4
        height: width
    }

    Label {
      id: label
      text: syncTool.currentLog
      font.pixelSize: UI.FONT_DEFAULT_SIZE
      width: 300
      wrapMode: 'WordWrap'

      anchors {
            top : logo.bottom
            horizontalCenter : parent.horizontalCenter
            topMargin : UI.NORMAL_MARGIN
      }
    }

    ProgressBar {
        anchors {
            horizontalCenter : parent.horizontalCenter
            verticalCenter : parent.verticalCenter
        }
        id: progressBar
        width: 300
        minimumValue: 0
        maximumValue: syncTool.totalMessage
        value: syncTool.currentMessageId
    }

    ButtonRow {
        anchors {
            horizontalCenter : parent.horizontalCenter
            bottom : parent.bottom
            bottomMargin : parent.height*2/9
        }
        Button {
           text: "Start"
           enabled : !syncTool.isSyncing
           onClicked: syncTool.start()
        }
        Button {
           text: "Stop"
           enabled : syncTool.isSyncing
           onClicked: syncTool.stop()
        }
    }

}
