#ifndef SMSHELP_H
#define SMSHELP_H
#include <QString>
#include <boost/python.hpp>
#include "syncmessagemodel.h"

using namespace boost::python;
using namespace CommHistory;

class SMSHelp
{
    public:
        SMSHelp();
        ~SMSHelp();
        const char* getTimeZone();
        int selectChannel(dict config);
        dict getMessage(int i);

    private:

        Event::EventType eventType;
        SyncMessageModel *p_syncModel;
        const char *date_format;
};

#endif // SMSHELP_H
