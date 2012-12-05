#!/usr/bin/python
# -*- coding: utf-8 -*-
import os,dbus,sys

if __name__=="__main__":
	try:
		bus = dbus.SessionBus()
		remote_object = bus.get_object("com.cuckoo.meego.SyncTool.SyncToolService", "/")
		print "FOUND RUNNING INSTANCE"
		remote_object.show();
		sys.exit();
	except dbus.exceptions.DBusException as e:
		print "CAUGHT EXCEPT"
		os.system("exec /usr/bin/invoker --single-instance --type=e --splash /opt/synctool/qml/images/synctoolsplash.png /opt/synctool/bin/synctool.py");
