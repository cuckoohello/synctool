TARGET      = qtlib
HEADERS     += smshelp.h syncmessagemodel.h
SOURCES     += smshelp.cpp syncmessagemodel.cpp
FORMS       += #UIS#
LEXSOURCES  += #LEXS#
YACCSOURCES += #YACCS#

INCLUDEPATH +=
LIBS        +=
DEFINES     +=

# All generated files goes to the same directory
OBJECTS_DIR = build
MOC_DIR     = build
RCC_DIR     = build
UI_DIR      = build

DESTDIR     = build
TEMPLATE    = lib
DEPENDPATH  +=
VPATH       += src uis
CONFIG      -= 
CONFIG      += debug
CONFIG      += mobility
MOBILITY    += contacts
QT          = core 

PKGCONFIG += commhistory
QMAKE_CXXFLAGS += -I/usr/include/python2.6
QMAKE_LFLAGS += -lboost_python -lcommhistory

INSTALLS    += target
target.path  = /opt/usr/lib

#
# Targets for debian source and binary package creation
#
debian-src.commands = dpkg-buildpackage -S -r -us -uc -d
debian-bin.commands = dpkg-buildpackage -b -r -uc -d
debian-all.depends = debian-src debian-bin

#
# Clean all but Makefile
#
compiler_clean.commands = -$(DEL_FILE) $(TARGET)

QMAKE_EXTRA_TARGETS += debian-all debian-src debian-bin compiler_clean
