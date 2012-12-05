// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0

ListView {
    id: list_view
    signal modelLoad(string filter)
    signal itemClicked(string filter)

    clip: true
    focus: true
    model: ListModel{}
    delegate: ListDelegate {
        Image {
            source: "image://theme/icon-m-common-drilldown-arrow" + (theme.inverted ? "-inverse" : "")
            anchors.right: parent.right;
            anchors.verticalCenter: parent.verticalCenter
        }
        onClicked: itemClicked(filter)
    }

    ScrollDecorator {
        flickableItem: list_view
    }

    function model_clear() {
        list_view.model.clear();
    }

    function model_refresh(filter) {
        list_view.model.clear();
        model_load(filter);
    }

    function model_load(filter) {
        modelLoad(filter);
    }
}

