#include "smshelp.h"


SMSHelp::SMSHelp()
{
    p_syncModel = NULL;
}

SMSHelp::~SMSHelp()
{
    if(p_syncModel)
        delete p_syncModel;
    p_syncModel = NULL;
}


const char* SMSHelp::getTimeZone()
{
    QDateTime dt1 = QDateTime::currentDateTime();
    QDateTime dt2 = dt1.toUTC();
    dt1.setTimeSpec(Qt::UTC);

    int offset = dt2.secsTo(dt1)/60;
    if(offset <0)
    {
        offset = -offset;
        return QString().sprintf("-%02d%02d",offset/60,offset%60).toUtf8().constData();
    }else
    {
        return QString().sprintf("+%02d%02d",offset/60,offset%60).toUtf8().constData();
    }
}


int SMSHelp::selectChannel(dict config)
{
    const char* type =  extract<const char *>(config["type"]);
    const char* account =  extract<const char *>(config["account"]);
    const char* since_time =  extract<const char *>(config["since_time"]);
    date_format =  extract<const char *>(config["date_format"]);

    if(!strcasecmp( type, "SMS"))
        eventType = Event::SMSEvent;
    else if (!strcasecmp( type, "IM"))
        eventType = Event::IMEvent;
    else if (!strcasecmp( type, "CALL"))
        eventType = Event::CallEvent;
    else if (!strcasecmp( type, "MMS"))
        eventType = Event::MMSEvent;
    else
    {
        return -1;         /* "Wrong type for channel "*/
    }

    if (p_syncModel)
        delete p_syncModel;
    p_syncModel = new  SyncMessageModel(ALL,eventType,account,
            QDateTime().fromString(QString(since_time),date_format));

    p_syncModel->setQueryMode(EventModel::SyncQuery);
    p_syncModel->getEvents();

    return p_syncModel->rowCount();
}

dict SMSHelp::getMessage(int i)
{
    dict dic;
    Event e = p_syncModel->event(p_syncModel->index(i,0));

    dic["Uid"] = e.remoteUid().toUtf8().constData();
    Event::EventDirection direction = e.direction();
    if (direction == Event::Inbound)
        dic["Direction"] = "Inbound";
    else
        dic["Direction"] = "Outbound";

    dic["StartTime"] = e.startTime()
        .toLocalTime().toString(date_format).toUtf8().constData();
    dic["EndTime"] = e.endTime() 
        .toLocalTime().toString(date_format).toUtf8().constData();

    dic["FreeText"] = e.freeText().toUtf8().constData();

    if (eventType == Event::CallEvent)
    {
        if(e.isMissedCall())
            dic["IsMissedCall"] = 1;
        else
            dic["IsMissedCall"] = 0;
    }
    if (eventType == Event::MMSEvent)
    {
        list messageParts;
        foreach(MessagePart part, e.messageParts())
        {
            dict dic1;
            dic1["contentId"] = part.contentId().toUtf8().constData();
            dic1["contentType"] = part.contentType().toUtf8().constData();
            dic1["contentLocation"] = part.contentLocation().toUtf8().constData();
            dic1["plainText"] = part.plainTextContent().toUtf8().constData();
            messageParts.append(dic1);
        }
        dic["MessageParts"] = messageParts;
        dic["Subject"] = e.subject().toUtf8().constData();
    }

    return dic;
}

BOOST_PYTHON_MODULE(SyncHelp)
{
    class_<SMSHelp>("SyncTool")
        .def("getTimeZone",&SMSHelp::getTimeZone)
        .def("getMessage",&SMSHelp::getMessage)
        .def("selectChannel",&SMSHelp::selectChannel)
        ;
}
