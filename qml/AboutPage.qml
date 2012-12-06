// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import "./UIConstants.js" as UI

Page {
    orientationLock: PageOrientation.LockPortrait
    tools: ToolBarLayout {

        ToolIcon {
            iconId: "toolbar-back"
            onClicked: {
                pageStack.pop();
            }
        }
    }

    function isNewerVersion(origin,now)
    {
      var orgs = origin.split('.')
      var nows = now.split('.')
      if (parseInt(orgs[0])< parseInt(nows[0]) || parseInt(orgs[1])< parseInt(nows[1]) || parseInt(orgs[2]) < parseInt(nows[2]))
        return true;
      else
        return false;
    }

    Header {
        id: header
        color: UI.HEADER_COLOR
        content: "About SMS/IM/CALL Backup"
    }

    Flickable {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentHeight: col.height

        Image {
            id: logo
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: UI.NORMAL_MARGIN
            }
            source: "./images/sms-backup.png"
            width: parent.width*1/3
            height: logo.width
        }

        Column {
            id: col
            anchors {
                top: logo.bottom
                left: parent.left
                right: parent.right
                margins: UI.NORMAL_MARGIN
            }
            spacing: UI.NORMAL_MARGIN

            Label {
                width: parent.width
                wrapMode: 'WordWrap'
                text: '<center>Backup your im/sms/call logs (sms, call, skype, fetion, msn etc.) to an imap server such as Gmail.</center>'
            }

            Label {
                width: parent.width
                text: '<center>Source:<a href=https://github.com/cuckoohello>https://github.com/cuckoohello</a></center>'
                onLinkActivated: {
                    Qt.openUrlExternally(link);
                }
            }

            Label {
                width: parent.width
                text: '<center>Email: <a href="mailto:cuckoohello@gmail.com">cuckoohello@gmail.com</a></center>'
                onLinkActivated: {
                    Qt.openUrlExternally(link);
                }
            }

            Label {
                width: parent.width
                text: '<center>Version:'+syncTool.getCurrentVersion()+'</center>'
            }

            BusyIndicator{
                id: getVersionIndicator
                running: false
                visible: running
                anchors.horizontalCenter : parent.horizontalCenter
                platformStyle: BusyIndicatorStyle{
                  size: "large"
                }
            }

            Button{
                anchors.horizontalCenter : parent.horizontalCenter
                text: 'Check Update!'
                enabled: ! getVersionIndicator.running
                onClicked:  {
                  getVersionIndicator.running = true
                  var xmlHttp = new XMLHttpRequest();
                  xmlHttp.onreadystatechange = function() {
                     if (xmlHttp.readyState == XMLHttpRequest.DONE) {
                         getVersionIndicator.running = false;
                         var version = xmlHttp.responseText;
                         if (isNewerVersion(syncTool.getCurrentVersion(),version))
                         {
                           show_info_bar('Find new version:'+version);
                           Qt.openUrlExternally('http://cloud.github.com/downloads/cuckoohello/synctool/synctool_'+version+'_armel.deb')
                         }else
                         {
                           show_info_bar('Your version is up to date!');
                         }
                     }
                  }
                  xmlHttp.open( "GET", "http://cloud.github.com/downloads/cuckoohello/synctool/version.txt")
                  xmlHttp.send();
                }
            }
        }
    }

}
