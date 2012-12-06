// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1
import "./UIConstants.js" as UI

Page {
    orientationLock: PageOrientation.LockPortrait
    property string section : ''
    property bool isAdd : false
    property bool isCallTimePicker : false

    property string messMailbox : ''
    property string messHeaderFormat : ''
    property string smsDate : '2005-11-11-11:11:11'
    property bool messFlagsSeen : false


    property string callMailbox : ''
    property string callHeaderFormat : ''
    property string callDate : '2005-11-11-11:11:11'
    property bool callFlagsSeen : false

    function datePickerCallback()
    {
        if (isCallTimePicker)
        {
            var times = callDate.split(/[-]/);
            callDate = datePickerDialog.year+'-'+(datePickerDialog.month < 10 ? '0':'')+datePickerDialog.month+'-'+(datePickerDialog.day< 10 ? '0':'')+datePickerDialog.day+'-'+times[3];
        }else
        {
            var times = smsDate.split(/[-]/);
            smsDate = datePickerDialog.year+'-'+(datePickerDialog.month < 10 ? '0':'')+datePickerDialog.month+'-'+(datePickerDialog.day< 10 ? '0':'')+datePickerDialog.day+'-'+times[3];
        }
    }

    function timePickerCallback()
    {
        if (isCallTimePicker)
        {
            var times = callDate.split(/[-]/);
            callDate = times[0]+'-'+times[1]+'-'+times[2]+'-'+(timePickerDialog.hour <10 ? '0':'')+timePickerDialog.hour+':'+(timePickerDialog.minute<10 ? '0':'')+timePickerDialog.minute+':'+(timePickerDialog.second<10 ? '0':'')+timePickerDialog.second;
        }else
        {
            var times = smsDate.split(/[-]/);
            smsDate = times[0]+'-'+times[1]+'-'+times[2]+'-'+(timePickerDialog.hour <10 ? '0':'')+timePickerDialog.hour+':'+(timePickerDialog.minute<10 ? '0':'')+timePickerDialog.minute+':'+(timePickerDialog.second<10 ? '0':'')+timePickerDialog.second;
        }
    }

    function getTimeDate(time)
    {
        var times = time.split(/[-:]/);
        return times[0]+'-'+times[1]+'-'+times[2];
    }

    function getTimeTime(time)
    {
        var times = time.split(/[-:]/);
        return times[3]+':'+times[4]+':'+times[5];
    }

    tools : ToolBarLayout {
        visible: true

        Row{
            anchors{
                verticalCenter:parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            spacing : UI.NORMAL_MARGIN

            ToolButton {
                text: qsTr("Save")
                width: isAdd? 186:140
                enabled: sectionText.text!='' && (mess_button.checked ? (messMailbox != '' && messHeaderFormat !='') : true) && (call_button.checked ?  (callMailbox != '' && callHeaderFormat !='') : true)
                onClicked: {
                    var configs = {}
                    configs['isAdd'] = isAdd
                    configs['section'] = section
                    configs['sectionName'] = sectionText.text
                    configs['account'] = accountButton.text
                    configs['type'] = ''
                    if(mess_button.checked)
                    {
                        configs['time_'+mess_button.text] = smsDate
                        configs['mailbox_'+mess_button.text] = messMailbox
                        configs['header_format_'+mess_button.text] = messHeaderFormat
                        configs['flags_'+mess_button.text] = messFlagsSeen ? UI.IMAP_FLAGS : '';
                        configs['type'] = mess_button.text
                    }
                    if(call_button.checked)
                    {
                        configs['time_call'] = callDate
                        configs['mailbox_call'] = callMailbox
                        configs['header_format_call'] = callHeaderFormat
                        configs['flags_call'] = callFlagsSeen ? UI.IMAP_FLAGS : '';
                        configs['type'] = 'CALL'
                    }
                    if(mess_button.checked && call_button.checked)
                    {
                        configs['type'] = mess_button.text+'/CALL'
                    }
                    var ret = syncTool.setConfigSection(configs)
                    if(ret[0])
                        pageStack.pop()
                    else
                        show_info_bar(ret[1])
                }
            }
            Loader {
                id : deleteLoader
            }
            ToolButton {
                text: qsTr("Cancel")
                width: isAdd ? 186:140
                onClicked: pageStack.pop();
            }
        }
    }
    Component {
        id: deleteToolButton
        ToolButton {
            text: qsTr("Delete")
            width: 140
            onClicked:{
                deleteConfirm.open()
            }
        }
    }

    QueryDialog {
        id: deleteConfirm
        titleText: qsTr("Confirm Delete")
        message: qsTr("Are you sure you want to delete section ")+section+"?"
        acceptButtonText: qsTr("Yes")
        rejectButtonText: qsTr("No")
        onAccepted: {
            syncTool.deleteConfigSection(section)
            pageStack.pop()
        }
    }


    Header {
        id: header
        color: UI.HEADER_COLOR
        content: qsTr("Section Setting")
    }

    Flickable {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentHeight: logo.height+accountColumn.height + ( mess_button.checked ? messLoader.height : 0) + (call_button.checked ? callLoader.height : 0) + 80

        Image {
            id: logo
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: UI.NORMAL_MARGIN
            }
            source: syncTool.getAccountIcon(accountButton.text)
            width: parent.width*1/4
            height: logo.width
        }

        Column {
            id: accountColumn
            spacing : UI.SMALL_MARGIN

            anchors {
                top: logo.bottom
                left: parent.left
                right: parent.right
                margins: UI.NORMAL_MARGIN
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Section")
            }

            TextField {
                id: sectionText
                anchors.right : parent.right
                anchors.left : parent.left
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Account")
            }

            TumblerButton {
                id: accountButton
                enabled : isAdd
                anchors.right : parent.right
                anchors.left : parent.left
                onClicked: accountDialog.open()
            }

            ButtonRow {
                exclusive: false
                Button {
                    id: mess_button
                    text: accountButton.text == 'ring/tel/ring' ? 'SMS' : 'IM'
                    checkable: true
                }
                Button {
                    id: call_button
                    text: "CALL"
                    checkable: true
                }
            }
        }

        Loader {
            id: messLoader
            anchors{
                top: accountColumn.bottom
                left: parent.left
                right: parent.right
            }
            sourceComponent: mess_button.checked ? smsColumn:null
        }

        Loader {
            id: callLoader
            anchors{
                top: messLoader.sourceComponent == null ? accountColumn.bottom : messLoader.bottom
                left: parent.left
                right: parent.right
            }
            sourceComponent: call_button.checked ? callColumn:null
        }
    }

    Component {
        id: smsColumn
        Column {
            spacing : UI.SMALL_MARGIN

            anchors {
                top: messLoader.top
                left: messLoader.left
                right: messLoader.right
                margins: UI.NORMAL_MARGIN
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: mess_button.text+qsTr(" Mailbox")
            }

            TextField {
                anchors.right : parent.right
                anchors.left : parent.left
                placeholderText: qsTr("SMS")
                text : messMailbox
                onTextChanged: messMailbox = text
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: mess_button.text+qsTr(" Header Format")
            }

            TextField {
                anchors.right : parent.right
                anchors.left : parent.left
                placeholderText: qsTr("SMS with %s")
                text : messHeaderFormat
                onTextChanged: messHeaderFormat = text
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: mess_button.text+qsTr(" Since Time")
            }

            Row{
                anchors{
                    left: parent.left
                    right: parent.right
                }
                TumblerButton {
                    id: smsTimeDate
                    text: getTimeDate(smsDate)
                    onClicked:{
                        isCallTimePicker = false;
                        var times = smsDate.split(/[-:]/);
                        datePickerDialog.year = parseInt(times[0]);
                        datePickerDialog.month = parseInt(times[1]);
                        datePickerDialog.day = parseInt(times[2]);
                        datePickerDialog.open()
                    }
                }
                TumblerButton {
                    id: smsTimeTime
                    text: getTimeTime(smsDate)
                    onClicked: {
                        isCallTimePicker = false;
                        var times = smsDate.split(/[-:]/);
                        timePickerDialog.hour= parseInt(times[3]);
                        timePickerDialog.minute = parseInt(times[4]);
                        timePickerDialog.second = parseInt(times[5]);
                        timePickerDialog.open()
                    }
                }
            }
            CheckBox{
                text: qsTr("Mark as Seen")
                checked: messFlagsSeen
                onClicked: messFlagsSeen = checked
            }
        }
    }

    Component {
        id: callColumn
        Column {
            spacing : UI.SMALL_MARGIN

            anchors {
                top: callLoader.top
                left: callLoader.left
                right: callLoader.right
                margins: UI.NORMAL_MARGIN
            }
            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Call Mailbox")
            }

            TextField {
                anchors.right : parent.right
                anchors.left : parent.left
                placeholderText: qsTr("Call log")
                text : callMailbox
                onTextChanged: callMailbox = text
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Call log Header Format")
            }

            TextField {
                anchors.right : parent.right
                anchors.left : parent.left
                placeholderText: qsTr("Call with %s")
                text : callHeaderFormat
                onTextChanged: callHeaderFormat = text
            }

            Label {
                font.pixelSize: UI.FONT_DEFAULT_SIZE
                text: qsTr("Call Since Time")
            }

            Row{
                anchors{
                    left: parent.left
                    right: parent.right
                }
                TumblerButton {
                    id: callTimeDate
                    text: getTimeDate(callDate)
                    onClicked: {
                        isCallTimePicker = true;
                        var times = callDate.split(/[-:]/);
                        datePickerDialog.year = parseInt(times[0]);
                        datePickerDialog.month = parseInt(times[1]);
                        datePickerDialog.day = parseInt(times[2]);
                        datePickerDialog.open()
                    }
                }
                TumblerButton {
                    id: callTimeTime
                    text: getTimeTime(callDate)
                    onClicked: {
                        isCallTimePicker = true;
                        var times = callDate.split(/[-:]/);
                        timePickerDialog.hour= parseInt(times[3]);
                        timePickerDialog.minute = parseInt(times[4]);
                        timePickerDialog.second = parseInt(times[5]);
                        timePickerDialog.open()
                    }
                }
            }
            CheckBox{
                text: qsTr("Mark as Seen")
                checked: callFlagsSeen
                onClicked: callFlagsSeen = checked
            }
        }
    }

    SelectionDialog {
        id: accountDialog
        titleText: qsTr("Select Available Account")
        selectedIndex: 0

        model: ListModel {}
        onSelectedIndexChanged: accountButton.text = accountDialog.model.get(accountDialog.selectedIndex).name
    }

    TimePickerDialog {
        id: timePickerDialog
        onAccepted: timePickerCallback()
    }

    DatePickerDialog {
        id: datePickerDialog
        onAccepted: datePickerCallback()
        minimumYear: 2005
        maximumYear: 2020
    }



    Component.onCompleted: {
        if (isAdd)
        {
            var accounts = syncTool.getAvailableAccounts();
            var i;
            for (i in accounts)
            {
                accountDialog.model.append({ name : accounts[i] });
            }
            if (accounts.length == 0)
            {
                accountDialog.model.append({ name : qsTr("No more account")});
                sectionText.enabled  = false;
                mess_button.enabled = false;
                call_button.enabled = false;
            }
        }else
        {
            sectionText.text = section;
            var account = syncTool.getConfigOption(section,'account');
            accountDialog.model.append({ name : account});
            deleteLoader.sourceComponent = deleteToolButton
            var types = syncTool.getConfigOption(section,'type').split('/');
            var accountType = (account == 'ring/tel/ring') ? 'SMS' : 'IM';
            var i;
            for (i in types)
            {
                if (types[i] == accountType)
                {
                    mess_button.checked = true
                }else if (types[i] == 'CALL')
                {
                    call_button.checked = true
                }
            }
            messMailbox = syncTool.getConfigOption(section,'mailbox_'+accountType)
            messHeaderFormat = syncTool.getConfigOption(section,'header_format_'+accountType)
            smsDate = syncTool.getConfigOption(section,'time_'+accountType)
            if (smsDate == '')
                smsDate = '2005-11-11-11:11:11';
            if (syncTool.getConfigOption(section,'flags_'+accountType)==UI.IMAP_FLAGS)
                messFlagsSeen = true;

            callMailbox = syncTool.getConfigOption(section,'mailbox_call')
            callHeaderFormat = syncTool.getConfigOption(section,'header_format_call')
            callDate = syncTool.getConfigOption(section,'time_call')
            if (callDate == '')
                callDate = '2005-11-11-11:11:11'
            if (syncTool.getConfigOption(section,'flags_call')==UI.IMAP_FLAGS)
                callFlagsSeen = true;
        }
        accountButton.text = accountDialog.model.get(accountDialog.selectedIndex).name
    }
}
