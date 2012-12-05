from distutils.core import setup
import os, sys, glob

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(name="synctool",
      version='1.1.0',
      maintainer="Shan Yafeng",
      maintainer_email="cuckoohello@gmail.com",
      description="Backup your sms/im/call logs to an imap server such as gmail!",
      long_description=read('synctool.longdesc'),
      data_files=[('share/applications',['synctool.desktop']),
                  ('share/icons/hicolor/80x80/apps', ['synctool.png']),
                  ('/opt/synctool/bin/', glob.glob('bin/*')),
                  ('/usr/lib/', glob.glob('lib/*')),
                  ('/opt/synctool/qml/', glob.glob('qml/*.js')),
                  ('/opt/synctool/qml/images/', glob.glob('qml/images/*')),
                  ('/opt/synctool/qml/', glob.glob('qml/*.qml')), ],)
