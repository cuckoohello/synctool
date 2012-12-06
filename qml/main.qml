import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

PageStackWindow {
    id: appWindow

    signal quit()
    signal hideSignal()

    InfoBanner{
        id: info_banner
        topMargin: 40
        timerShowTime: 2*1000
        z: 1
    }

    function show_info_bar(text) {
        info_banner.text = text;
        info_banner.show();
    }

    function goto_page(path, param) {
        if (!arguments.length) {
            console.log('Error!');
            return;
        }

        if (arguments.length == 1) {
            pageStack.push(Qt.resolvedUrl(path));
        }else if(arguments.length == 2){
            pageStack.push(Qt.resolvedUrl(path), param);
        }
    }
    QueryDialog {
        id: quitConfirm
        titleText: qsTr("Confirm Quit")
        message: qsTr("Are you sure you want to quit SyncTool?")
        acceptButtonText: qsTr("Yes")
        rejectButtonText: qsTr("No")
        onAccepted: quit();
    }

    initialPage: MainPage{}
}
