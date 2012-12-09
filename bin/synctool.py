#!/usr/bin/python
# -*- coding: utf-8 -*- 
from PySide.QtCore import *
from PySide.QtGui import *
from PySide.QtDeclarative import *
from QtMobility.Contacts import *
import SyncHelp
import os,sys,locale
import imaplib
import email
import email.Message
import time
import base64
import ConfigParser
import threading
from socket import gaierror
import dbus
import dbus.service
import dbus.glib
import dbus.mainloop

version = '1.1.5'

class SyncTool(QObject):
    '''
    Wrap of SyncHelp for easy use
    '''
    def __init__(self):
        QObject.__init__(self)
        self.manager = None
        self.contactsManager = ContactsManager()
        self.has_login = False
        self.date_format = 'yyyy-MM-dd-hh:mm:ss'
        self.total = 0
        self.log = self.tr('Press start button to start!')
        self.currentMessageNumber = -1
        self.thread = None
        self.configFile = '/home/user/.synctool.conf'
        self.config = None
        self.username = ''
        self.password = ''
        self.imapserver = ''
        self.has_get_config = False
        self.stop_thread = True
        self.iconsDic = dict()
        self.iconsDic['ring/tel/ring'] = 'image://theme/icon-l-telephony'
        self.has_started = False
        self.mainIconSource =  u'./images/sms-backup.png'

    def getCurrentStatus(self):
        return self.has_started

    @Slot(result=str)
    def getCurrentVersion(self):
        return version

    currentStatusChanged  = Signal()

    def setCurrentStatus(self,state):
        self.has_started = state
        self.currentStatusChanged.emit()

    isSyncing = Property(bool,
            fget=getCurrentStatus,
            notify=currentStatusChanged)

    def getMainIconSource(self):
        return self.mainIconSource

    currentMainIconSourceChanged  = Signal()

    def setMainIconSource(self,source):
        self.mainIconSource = source
        self.currentMainIconSourceChanged.emit()

    currentMainIconSource = Property(unicode,
            fget=getMainIconSource,
            notify=currentMainIconSourceChanged)

    @Slot(result='QVariant')
    def getAccountInfo(self):
        if self.has_get_config == False:
            self.loadConfig()
        return {u'username':unicode(self.username,'utf8'),u'password':unicode(self.password,'utf8'),u'imapserver':unicode(self.imapserver,'utf8')}

    @Slot(result='QVariant')
    def getConfigSections(self):
        if self.has_get_config == False:
            self.loadConfig()
        sections = self.config.sections()
        try:
            sections.remove('account')
        except ValueError:
            pass
        secs = []
        for section in sections:
            secs.append(unicode(section,'utf8'))
        return secs

    @Slot(unicode)
    def deleteConfigSection(self,section):
        self.config.remove_section(section.encode('utf8'))
        self.saveConfig()

    @Slot('QVariant',result='QVariant')
    def setConfigSection(self,sectionConfig):
        section = sectionConfig[u'sectionName'].encode('utf8')
        if sectionConfig[u'isAdd']:
            if self.config.has_section(section):
                return [False,self.tr("Section name {0} has already existed!").format(unicode(section,'utf8'))]
            self.config.add_section(section)
        else:
            originSection = sectionConfig[u'section'].encode('utf8')
            if section != originSection:
                if self.config.has_section(section):
                    return [False,self.tr("Section name {0} has already existed!").format(unicode(section,'utf8'))]
            items = self.config.items(originSection)
            self.config.remove_section(originSection)
            self.config.add_section(section)
            for item in items:
                self.config.set(section,item[0],item[1])

        sectionConfig.pop(u'isAdd')
        sectionConfig.pop(u'section')
        sectionConfig.pop(u'sectionName')
        for item in sectionConfig:
            self.config.set(section,item.encode('utf8'),sectionConfig[item].encode('utf8'))
        self.saveConfig()
        return [True]

    @Slot(unicode,unicode,result=unicode)
    def getConfigOption(self,section,option):
        if self.has_get_config == False:
            self.loadConfig()
        try:
            return unicode(self.config.get(section.encode('utf8'),option.encode('utf8')),'utf8')
        except ConfigParser.NoOptionError:
            return u''

    @Slot(unicode,unicode,unicode)
    def saveAccountSettings(self,username,password,imapserver):
        try:
            self.config.add_section('account')
        except ConfigParser.DuplicateSectionError:
            pass

        self.username = username.encode('utf8')
        self.password = password.encode('utf8')
        self.imapserver = imapserver.encode('utf8')

        self.config.set('account','username',self.username)
        self.config.set('account','password',base64.encodestring(self.password))
        self.config.set('account','imapserver',self.imapserver)
        self.saveConfig()


    def getCurrentMessageNumber(self):
        return self.currentMessageNumber+1

    currentMessageIdChanged = Signal()

    currentMessageId = Property(int,
            fget=getCurrentMessageNumber,
            notify=currentMessageIdChanged)

    def getTotalMessage(self):
        return self.total

    totalMessageChanged = Signal()

    totalMessage = Property(int,
            fget=getTotalMessage,
            notify=totalMessageChanged)

    currentIdChanged = Signal()

    def getCurrentLog(self):
        return self.log

    logMessageChanged = Signal()

    currentLog = Property(unicode,
            fget=getCurrentLog,
            notify=logMessageChanged)

    def setCurrentLog(self,log):
        self.log = log
        self.logMessageChanged.emit()

    def selectChannel(self,mess_type='SMS',account='ring/tel/ring',since_time='1999-11-11-11:11:11'):
        dic = dict()
        dic['type'] = mess_type
        dic['account'] = account
        dic['since_time'] = since_time
        dic['date_format'] = self.date_format
        self.mess_type = mess_type
        self.channel = account
        if self.manager == None:
            self.manager = SyncHelp.SyncTool()
            self.timeZone = self.manager.getTimeZone()
        self.currentMessageNumber = -1
        self.currentMessageIdChanged.emit()
        self.total =  self.manager.selectChannel(dic)
        self.totalMessageChanged.emit()
        return self.total

    def getMessage(self,i):
        '''
        return dic Uid, Direction(Inbound/Outbound),StartTime,EndTime(yyyy-MM-dd-hh:mm:ss)
        GroupId, FreeText, MessageToken, IsMissedCall(1,true), Name, Email
        '''
        self.currentMessageNumber = i
        self.currentMessageIdChanged.emit()
        mess = self.manager.getMessage(i)
        mess['Name'],mess['Email'] = self.contactsManager.getContacts(self.mess_type,mess['Uid'])
        return mess

    def getAccounts(self):
        stdout = os.popen('mc-tool list').read()
        return stdout.split()

    @Slot(unicode,result=unicode)
    def getAccountIcon(self,account):
        account = account.encode('utf8')
        try:
            return unicode(self.iconsDic[account],'utf8')
        except KeyError: 
            stdout = os.popen('mc-tool show %s | awk \'/Service:/ {printf "/usr/share/accounts/services/"$2".service" }\' | xargs awk -F "[<>]" \'/icon-m-normal/ {printf "image://theme/"$3}\''%(account.encode('utf8'))).read()
            if stdout == '':
                stdout = './images/sms-backup.png'
            self.iconsDic[account] = stdout;
            return unicode(stdout,'utf8')

    @Slot(result='QVariant')
    def getAvailableAccounts(self):
        if self.has_get_config == False:
            self.loadConfig()
        sections = self.config.sections()
        try:
            sections.remove('account')
        except ValueError:
            pass
        accounts = self.getAccounts()
        for section in sections:
            accounts.remove(self.config.get(section,'account'))
        accounts.remove('mmscm/mms/mms0')
        accs = []
        for account in accounts:
            accs.append(unicode(account,'utf8'))
        return accs

    def getConfig(self):
        return self.config

    def login(self):
        if self.has_login:
            return
        self.has_login = True
        self.imapser = imaplib.IMAP4_SSL(self.imapserver)
        ret,data = self.imapser.login(self.username,self.password)
        data = data[0].split()
        if self.imapserver == 'imap.gmail.com':
            self.accountEmail = data[0]
            if data[3] == 'authenticated':
                self.accountName = data[1]+' '+data[2]
            else:
                self.accountName = data[1]
            self.accountTitle = self.encodeMailUTF8(self.accountName)+'<'+self.accountEmail+'>'
        else:
            try:
                self.username.index('@')
                self.accountTitle = self.username
            except ValueError:
                self.accountEmail = self.username+self.imapserver.replace('imap.','@')
                self.accountTitle = self.accountEmail
        return

    def logout(self):
        if self.has_login: 
            try:
                self.imapser.close()
                self.imapser.logout()
            except imaplib.IMAP4.error:
                pass
            del self.imapser
            self.has_login = False
        if self.manager:
            del self.manager
            self.manager = None

    def selectMailBox(self,mailbox):
        if self.has_login == False:
            self.login()
        self.mailbox = mailbox.decode('utf8').encode('utf7').replace('+','&',1)
        self.imapser.create(self.mailbox)
        self.imapser.select(self.mailbox)
        return

    def encodeMailUTF8(self,content):
        return '=?UTF-8?B?'+base64.encodestring(content).split()[0]+'?= '

    def setSubjectFormat(self,subject_format):
        '''
        for example 'SMS with %s'
        '''
        self.subject_format = subject_format
        return

    def createEmail(self,dic):
        mail = email.Message.Message()
        mail['Subject'] = self.encodeMailUTF8(self.subject_format%(dic['Name']))
        if dic['Direction'] == 'Inbound':
            mail['From'] = self.encodeMailUTF8(dic['Name'])+'<'+dic['Email'] +'>'
            mail['To'] = self.accountTitle
        else:
            mail['From'] = self.accountTitle
            mail['To'] = self.encodeMailUTF8(dic['Name'])+'<'+dic['Email'] +'>'

        sms_time = time.strptime(dic['StartTime'],'%Y-%m-%d-%H:%M:%S')
        mail['Date'] =  time.strftime('%a, %d %b %Y %H:%M:%S ',sms_time)+self.timeZone

        mail['Message-ID'] = "<%s.%s@n9-sms-backup.local>"%(dic['StartTime'],dic['Uid'])
        mail['References'] = "<vgh9cncxqdbp18aap94lw77b.%s@n9-sms-backup-local>"%(dic['Uid'])

        mail['X-smssync-Uid'] = dic['Uid']
        mail['X-smssync-Type'] = self.mess_type
        mail['X-smssync-Direction'] = dic['Direction']
        mail['X-smssync-EndTime'] = dic['EndTime']

        if self.mess_type == 'CALL':
            if dic['Direction'] == 'Outbound' or dic['IsMissedCall'] == 0:
                end_time = time.strptime(dic['EndTime'],'%Y-%m-%d-%H:%M:%S')
                n_secs = int(time.mktime(end_time) - time.mktime(sms_time))
                mins,secs = n_secs/60,n_secs%60
                hours,mins = mins/60,mins%60
                content = "%ds(%02d:%02d:%02d)\n"%(n_secs,hours,mins,secs)

            if dic['Direction'] == 'Outbound':
                content += '(Outgoing Call)\n'
            elif dic['IsMissedCall'] == 1:
                content = '(Missed Call)\n'
            else:
                content += '(Incoming Call)\n'

            mail.set_payload(content)
        else:
            mail.set_payload(dic['FreeText'])

        mail.set_charset('utf-8')
        return [mail,sms_time]

    def backupMessage(self,sms,flags,sms_time):
        return self.imapser.append(self.mailbox,flags,imaplib.Time2Internaldate(sms_time),str(sms))

    def loadConfig(self):
        '''
        -1 no config account
        '''
        if self.config:
            del self.config
        self.config = ConfigParser.ConfigParser()
        self.config.read(self.configFile)
        self.has_get_config = True
        if self.config.has_section('account'):
            self.username = self.config.get('account','username')
            self.password = base64.decodestring(self.config.get('account','password'))
            self.imapserver = self.config.get('account','imapserver')
            return 0
        else:
            return -1

    def saveConfig(self):
        self.config.write(open(self.configFile,'w'))

    @Slot()
    def start(self):
        if self.thread:
            return
        self.setCurrentLog(self.tr('<center>Starting...</center>'))
        self.stop_thread = False
        self.setCurrentStatus(True)
        self.thread = threading.Thread(target=self.thread_proc)
        self.thread.setDaemon(True)
        self.thread.start()

    @Slot()
    def stop(self):
        if self.stop_thread == False:
            self.setCurrentLog(self.tr('<center>Stopping....</center>'))
            self.stop_thread = True

    def thread_proc(self):
        self.currentMessageNumber = -1
        self.currentMessageIdChanged.emit()
        self.setCurrentLog(self.tr('<center>Loading config...</center>'))
        ret = self.loadConfig()
        if ret == -1:
            self.setCurrentLog(self.tr('<center>Read account config error!</center>'))
            self.stop_thread = True
            self.thread = None
            self.has_login = False
            self.setCurrentStatus(False)
            return

        sections = self.config.sections()
        sections.remove('account')
        num_synced_messages = 0
        num_channels = 0

        for section in sections:
            if self.stop_thread:
                break
            account = self.config.get(section,'account')
            self.setMainIconSource(self.getAccountIcon(unicode(account,'utf8')))
            channels = self.config.get(section,'type').split('/')
            for channel in channels:
                if channel == '':
                    continue
                if self.stop_thread:
                    break
                num_channels = num_channels+1
                self.setCurrentLog(self.tr('<center>Section:{0} Type:{1}</center>\n<center>Account</center>\n<center>{2}</center>').format(unicode(section,'utf8'),channel,account))
                last_time = self.config.get(section,'time_'+channel)
                header_format = self.config.get(section,'header_format_'+channel)
                mailbox = self.config.get(section,'mailbox_'+channel)
                flags = self.config.get(section,'flags_'+channel)
                count = self.selectChannel(channel,account,last_time)
                if count == 0:
                    continue

                try:
                    self.selectMailBox(mailbox)
                except gaierror:
                    self.setCurrentLog(self.tr('<center>Network error or imap server error!</center>'))
                    self.setMainIconSource(u'./images/sms-backup.png')
                    self.has_login = False
                    self.logout()
                    self.stop_thread = True
                    self.thread = None
                    self.setCurrentStatus(False)
                    return
                except imaplib.IMAP4.error as e:
                    self.setMainIconSource(u'./images/sms-backup.png')
                    self.setCurrentLog(e.args[0])
                    print e.args
                    self.logout()
                    self.stop_thread = True
                    self.thread = None
                    self.setCurrentStatus(False)
                    return


                self.setSubjectFormat(header_format)
                for i in range(0,count):
                    if self.stop_thread:
                        break
                    self.setCurrentLog(self.tr('<center>Section:{0} Type:{1}</center>\n<center>Total messages:</center>\n<center>{2}/{3}</center>').format(unicode(section.upper(),'utf8'),channel.upper(),i+1,count))
                    message = self.getMessage(i)
                    mail,sms_time = self.createEmail(message)
                    num_synced_messages = num_synced_messages+1
                    try:
                        self.backupMessage(mail,flags,sms_time)
                        if i%50 == 25:
                            self.config.set(section,'time_'+channel,message['EndTime'])
                            self.saveConfig()
                            self.imapser.expunge()
                    except:
                        self.setCurrentLog(self.tr('<center>Network error!</center>\n<center>Force Stop!!!</center>'))
                        self.stop_thread = True

                if i !=0 or count == 1 :
                    try:
                        self.config.set(section,'time_'+channel,message['EndTime'])
                    except:
                        print 'Should not have any error here!'
                    self.saveConfig()
                    self.imapser.expunge()

        self.logout()
        self.saveConfig()
        if self.stop_thread:
            self.setCurrentLog(self.tr('<center>Sync has stopped!</center>\n<center>User stopped!</center>'))
        elif num_synced_messages:
            self.setCurrentLog(self.tr('<center>Sync has stopped!</center>\n<center>Total:{0}</center>').format(num_synced_messages))
        elif num_channels == 0:
            self.setCurrentLog(self.tr('<center>Sync has stopped!</center>\n<center>No channels!!!</center>'))
        else:
            self.setCurrentLog(self.tr('<center>Sync has stopped!</center>\n<center>No new messages!</center>'))
        self.stop_thread = True
        self.thread = None
        self.setMainIconSource(u'./images/sms-backup.png')
        self.setCurrentStatus(False)

class ContactsManager(QObject):
    '''
    Provides access to phone's contacts manager API
    '''
    def __init__(self):
        super(ContactsManager,self).__init__();
        self.manager = QContactManager(self);
        self.contacts = dict()

    def createFilter(self,sms_type,number):
        if sms_type == 'IM':
            filter = QContactDetailFilter()
            filter.setDetailDefinitionName(QContactOnlineAccount.DefinitionName,QContactOnlineAccount.FieldAccountUri)
            filter.setValue(number)
            filter.setMatchFlags(QContactFilter.MatchExactly)
            return filter
        else:
            return QContactPhoneNumber.match(number)


    def getContacts(self,sms_type,number):
        '''
        Gets all phone contacts
        '''
        try:
            return self.contacts[number]
        except KeyError: 
            contacts = self.manager.contacts(self.createFilter(sms_type,number));
            label,email = '',''
            for contact in contacts:
                label =  contact.displayLabel();
                email =  QContactEmailAddress(contact.detail(QContactEmailAddress.DefinitionName)).emailAddress()

            if label == '': label = number
            if email == '': email = number+'@unknown.email'
            label = label.encode('utf8')
            self.contacts[number] = [label,email]
            return [label,email]

class QSyncToolUI(QDeclarativeView):
    def __init__(self,app):
        super(QSyncToolUI,self).__init__();
        self.app = app
        self.smsTool = SyncTool()
        self.rootContext().setContextProperty('syncTool',self.smsTool)
        self.setSource('qml/main.qml')
        self.rootObject().quit.connect(self.app.quit)
        self.rootObject().hideSignal.connect(self.hide)
        self.dbusService = SyncService(self)

    def closeEvent(self,e):
        if self.smsTool.isSyncing: 
            e.ignore(); 
            self.hide();
        else:
            super(QSyncToolUI,self).closeEvent(e)

class SyncService(dbus.service.Object):

    DEFAULT_NAME = 'com.cuckoo.meego.SyncTool'
    DEFAULT_PATH = '/' 
    DEFAULT_INTF = 'com.cuckoo.meego.SyncTool'

    def __init__(self,ui):
        source_name = "SyncToolService"
        self.ui = ui
        dbus_main_loop = dbus.glib.DBusGMainLoop(set_as_default=True)
        session_bus = dbus.SessionBus(dbus_main_loop)
        self.userId = os.geteuid();

        self.local_name = '.'.join([self.DEFAULT_NAME, source_name])
        bus_name = dbus.service.BusName(self.local_name, bus=session_bus)

        dbus.service.Object.__init__(self,object_path=self.DEFAULT_PATH,bus_name=bus_name)

    @dbus.service.method(DEFAULT_INTF)
    def show(self):
        self.ui.showFullScreen();


if __name__ == "__main__":
    os.chdir('/opt/synctool/')
    translator = QTranslator()
    app = QApplication(sys.argv)
    if translator.load(os.path.join('i18n',locale.getdefaultlocale()[0])):
        app.installTranslator(translator)

    view = QSyncToolUI(app)
    view.showFullScreen()
    app.exec_()
