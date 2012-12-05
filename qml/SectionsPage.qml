// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import "./UIConstants.js" as UI

Page {
    orientationLock: PageOrientation.LockPortrait

    tools : ToolBarLayout {
        visible: true

         ToolButton {
            text: "Add"
            anchors{
              centerIn: parent
            }
            onClicked: {
              goto_page("SectionPage.qml", {isAdd: true});
            }
         }
        ToolIcon {
            iconId: "toolbar-back"
            anchors{
              verticalCenter:parent.verticalCenter
              left: parent.left
            }
            onClicked: {
                pageStack.pop();
            }
        }
    }

    Header {
        id: header
        color: UI.HEADER_COLOR
        content: 'Sessions'
    }


    CommonList{
      id : session_list
      anchors{
        top: header.bottom
        left: parent.left
        right: parent.right
        bottom: parent.bottom
      }
        onItemClicked: {
            goto_page("SectionPage.qml", {section: filter});
        }
    }
    onStatusChanged: {
        if (status == PageStatus.Activating) {
            session_list.model.clear()
            var sections = syncTool.getConfigSections();
            var i
            for (i in sections)
            {
              var title = sections[i];
              var subtitle = [{title:syncTool.getConfigOption(title,'type')}]
              var iconSource = syncTool.getAccountIcon(syncTool.getConfigOption(title,'account'))
              if (subtitle[0]['title'] == '')
                subtitle[0]['title'] = 'None'
              session_list.model.append({
                  title: title,
                  subtitle: subtitle,
                  iconSource: iconSource,
                  //iconSource: "./images/sms-backup.png",
                  filter: title
              })
            }
        }
    }
}
