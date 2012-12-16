/******************************************************************************
 **
 ** This file is part of libcommhistory.
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** Contact: Alexander Shalamov <alexander.shalamov@nokia.com>
 **
 ** This library is free software; you can redistribute it and/or modify it
 ** under the terms of the GNU Lesser General Public License version 2.1 as
 ** published by the Free Software Foundation.
 **
 ** This library is distributed in the hope that it will be useful, but
 ** WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 ** or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 ** License for more details.
 **
 ** You should have received a copy of the GNU Lesser General Public License
 ** along with this library; if not, write to the Free Software Foundation, Inc.,
 ** 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 **
 ******************************************************************************/

#include <CommHistory/eventmodel_p.h>
#include <CommHistory/TrackerIO>
#include <CommHistory/eventsquery.h>
#include <CommHistory/Group>
#include "syncmessagemodel.h"


using namespace CommHistory;


class SyncMessageModelPrivate: public EventModelPrivate
{
    public:
        SyncMessageModelPrivate(EventModel* model, int _parentId,Event::EventType _type, QString _account, QDateTime _dtTime, bool _lastModified)
            : EventModelPrivate(model)
              , dtTime(_dtTime)
              , parentId(_parentId)
              , lastModified(_lastModified)
              , type(_type)
              , account(_account)
    {
    }

        bool acceptsEvent(const Event &event) const {
            qDebug() << __PRETTY_FUNCTION__ << event.id();

            if (!lastModified) {
                if (!dtTime.isNull()) {
                    return (event.endTime() > dtTime);
                } else {
                    return true;
                }
            }

            if (!dtTime.isNull() && ((event.endTime() > dtTime)
                        || (event.lastModified() <= dtTime))) {
                return false;
            } else if (lastModified && (event.lastModified() <= dtTime)) {
                return false;
            }

            return true;
        }

        QDateTime dtTime;
        int parentId;
        bool lastModified;
        Event::EventType  type;
        QString account;
};

    SyncMessageModel::SyncMessageModel(int parentId , Event::EventType type, QString account,QDateTime time, bool lastModified ,QObject *parent)
: EventModel(*(new SyncMessageModelPrivate(this, parentId, type,account,time, lastModified)), parent)
{

}

SyncMessageModel::~SyncMessageModel()
{
}

bool SyncMessageModel::getEvents()
{
    Q_D(SyncMessageModel);

    reset();
    d->clearEvents();

    //EventsQuery query(d->propertyMask);
    EventsQuery query(Event::allProperties());

    if (d->parentId != ALL) {
        query.addPattern(QString(QLatin1String("%2 nmo:phoneMessageId \"%1\" . "))
                .arg(d->parentId))
            .variable(Event::Id);
    }

    if (d->lastModified) {
        if (!d->dtTime.isNull()) { //get all last modified messages after time t1
            query.addPattern(QString(QLatin1String("FILTER(nmo:receivedDate(%2) <= \"%1\"^^xsd:dateTime)"))
                    .arg(d->dtTime.toUTC().toString(Qt::ISODate)))
                .variable(Event::Id);
            query.addPattern(QString(QLatin1String("FILTER(nie:contentLastModified(%2) > \"%1\"^^xsd:dateTime)"))
                    .arg(d->dtTime.toUTC().toString(Qt::ISODate)))
                .variable(Event::Id);
        } else {
            query.addPattern(QString(QLatin1String("FILTER(nie:contentLastModified(%2) > \"%1\"^^xsd:dateTime)"))
                    .arg(QDateTime::fromTime_t(0).toUTC().toString(Qt::ISODate)))
                .variable(Event::Id);
        }
    } else {
        if (!d->dtTime.isNull()) { //get all messages after time t1(including modified)
            query.addPattern(QString(QLatin1String("FILTER(nmo:receivedDate(%2) > \"%1\"^^xsd:dateTime)"))
                    .arg(d->dtTime.toUTC().toString(Qt::ISODate)))
                .variable(Event::Id);
        }
    }

    if(!d->account.isEmpty())
    {
        const char managerFormat[] =
            "{%2 nmo:to [nco:hasContactMedium <telepathy:/org/freedesktop/Telepathy/Account/%1>]} UNION {%2 nmo:from [nco:hasContactMedium <telepathy:/org/freedesktop/Telepathy/Account/%1>]}";

        query.addPattern( QString(QLatin1String(managerFormat)).arg(d->account))
            .variable(Event::Id);
    }

    if(d->type)
    {
        switch(d->type)
        {
            case Event::SMSEvent:
                query.addPattern(QLatin1String("{%1 rdf:type nmo:SMSMessage }")).variable(Event::Id);
                break;
            case Event::IMEvent:
                query.addPattern(QLatin1String("{%1 rdf:type nmo:IMMessage }")).variable(Event::Id);
                break;
            case Event::CallEvent:
                query.addPattern(QLatin1String("{%1 rdf:type nmo:Call }")).variable(Event::Id);
                break;
            case Event::MMSEvent:
                query.addPattern(QLatin1String("{%1 rdf:type nmo:MMSMessage }")).variable(Event::Id);
                break;
            default:
                break;
        }
    }

    query.addModifier("ORDER BY ASC(%1) ASC(tracker:id(%2))")
        .variable(Event::EndTime)
        .variable(Event::Id);


    return d->executeQuery(query);
}

void SyncMessageModel::setSyncMessageFilter(const SyncMessageFilter& filter)
{
    Q_D(SyncMessageModel);
    d->parentId = filter.parentId;
    d->dtTime = filter.time;
    d->lastModified = filter.lastModified;
    d->type = filter.type;
    d->account = filter.account;
}
