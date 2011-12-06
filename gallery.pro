######################################################################
# Automatically generated by qmake (2.01a) Mon Oct 24 15:04:00 2011
######################################################################

isEmpty(PREFIX) {
	PREFIX = /usr/local
}

TEMPLATE = app
TARGET = gallery
DEPENDPATH += . src
INCLUDEPATH += .
CONFIG += qt debug
QT += gui declarative
MOC_DIR = build
OBJECTS_DIR = build
RESOURCES = gallery.qrc

install.path = $$PREFIX/bin/
install.files = gallery
INSTALLS = install

# Input

SOURCES += \
	src/album.cpp \
	src/album-collection.cpp \
	src/checkerboard.cpp \
	src/checkerboard-agent.cpp \
	src/container-source.cpp \
	src/container-source-collection.cpp \
	src/data-collection.cpp \
	src/data-object.cpp \
	src/data-source.cpp \
	src/gui-controller.cpp \
	src/main.cpp \
	src/media-collection.cpp \
	src/media-source.cpp \
	src/photo.cpp \
	src/photo-collection.cpp \
	src/photo-viewer.cpp \
	src/photo-viewer-agent.cpp \
	src/qml-media-model.cpp \
	src/selectable-view-collection.cpp \
	src/source-collection.cpp \
	src/view-collection.cpp

HEADERS += \
	src/album.h \
	src/album-collection.h \
	src/checkerboard.h \
	src/checkerboard-agent.h \
	src/container-source.h \
	src/container-source-collection.h \
	src/data-collection.h \
	src/data-object.h \
	src/data-source.h \
	src/gui-controller.h \
	src/media-collection.h \
	src/media-source.h \
	src/photo.h \
	src/photo-collection.h \
	src/photo-viewer.h \
	src/photo-viewer-agent.h \
	src/qml-media-model.h \
	src/selectable-view-collection.h \
	src/source-collection.h \
	src/view-collection.h

OTHER_FILES += \
	qml/BinaryTabGroup.qml \
	qml/Checkerboard.qml \
	qml/NavButton.qml \
	qml/NavToolbar.qml \
	qml/PhotoViewer.qml \
	qml/TabletSurface.qml \
	qml/Tab.qml \
	qml/TopBar.qml \
	LICENSE
