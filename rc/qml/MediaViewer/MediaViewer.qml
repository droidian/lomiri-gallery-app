/*
 * Copyright (C) 2011-2015 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Jim Nelson <jim@yorba.org>
 * Lucas Beeler <lucas@yorba.org>
 *
 * Emanuele Sorce <emanuele.sorce@hotmail.com>
 */

import QtQuick 2.9
import QtQuick.Layouts 1.1
import QtSensors 5.0
import Gallery 1.0
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.ListItems 1.3 as ListItem
import Lomiri.Content 1.3
import "../Components"
import "../Utility"
import "../../js/Gallery.js" as Gallery

/*!
*/
Item {
    id: viewerWrapper

    /*!
    */
    property alias media: galleryPhotoViewer.media
    /*!
    */
    property alias model: galleryPhotoViewer.model
    /*!
    */
    property alias index: galleryPhotoViewer.index
    /*!
    */
    property alias currentIndexForHighlight:
        galleryPhotoViewer.currentIndexForHighlight

    // Set this when entering from an album.
    property variant album

    // Read-only
    // Set to true when an image is loaded and displayed.
    //
    // NOTE: The empty-model check does perform a useful function here and should NOT be
    // removed; for whatever reason, it's possible to get here and have what would have
    // been the current item be deleted, but not be null, and what it actually points to
    // is no longer valid and will result in an immediate segfault if dereferenced.
    //
    // Since there is no current item if there are no more photo objects left in the model,
    // the check catches this before we can inadvertently follow a stale pointer.
    property bool isReady: model != null && model.count > 0 && galleryPhotoViewer.currentItem

    // tooolbar actions for the full view
    property variant actions: (media && !sharePicker.visible) ? d.mediaActions : []

    property variant backAction: d.backAction

    /*!
    */
    signal closeRequested()
    /*!
    */
    signal editRequested(variant photo)

    signal setHeaderVisibilityRequested(bool visibility)
    signal toggleHeaderVisibilityRequested()

    /*!
    */
    function setCurrentIndex(index) {
        galleryPhotoViewer.setCurrentIndex(index);
    }

    /*!
    */
    function setCurrentPhoto(photo) {
        galleryPhotoViewer.setCurrentPhoto(photo);
    }

    /*!
    */
    function goBack() {
        galleryPhotoViewer.goBack();
    }

    /*!
    */
    function goForward() {
        galleryPhotoViewer.goForward();
    }

    function closeMediaViewer()
    {
        galleryPhotoViewer.currentItem.reset();
        closeRequested();
    }

    Rectangle{
        color: "black"
        anchors.fill: parent
    }

    MediaListView {
        id: galleryPhotoViewer
        objectName: "mediaListView"

        // When the user clicks the back button.
        signal closeRequested()
        signal editRequested(variant photo) // The user wants to edit this photo.

        // NOTE: These properties should be treated as read-only, as setting them
        // individually can lead to bogus results.  Use setCurrentPhoto() or
        // setCurrentIndex() to initialize the view.
        property variant media: null

        function setCurrentPhoto(photo) {
            setCurrentIndex(model.indexOf(photo));
        }

        function goBack() {
            galleryPhotoViewer.currentItem.reset();
            pageBack();
        }

        function goForward() {
            galleryPhotoViewer.currentItem.reset();
            pageForward();
        }

        anchors.fill: parent

        onCurrentIndexChanged: {
            if (model)
                media = model.getAt(currentIndex);
        }

        delegate: SingleMediaViewer {
            id: media
            objectName: "openedMedia" + index
            mediaSource: model.mediaSource
            rotation: overview.staticRotationAngle

            Behavior on rotation {
                RotationAnimator {
                    duration: LomiriAnimation.BriskDuration
                    easing: LomiriAnimation.StandardEasing
                    direction: RotationAnimator.Shortest
                }
            }

            width: galleryPhotoViewer.width
            height: galleryPhotoViewer.height

            // Needed as ListView.isCurrentItem can't be used directly in a change handler
            property bool isActive: ListView.isCurrentItem
            onIsActiveChanged: if (!isActive) reset();

            onClicked: viewerWrapper.toggleHeaderVisibilityRequested()
        }

        // Don't allow flicking while the chrome is actively displaying a popup
        // menu, or the image is zoomed. When images are zoomed,
        // mouse drags should pan, not flick.
        interactive: currentItem != null &&
                     !currentItem.userInteracting  // FIXME: disable when editing ??

        Component {
            id: contentItemComp
            ContentItem {}
        }

        Page {
            id: sharePicker
            visible: false

            title: i18n.tr("Share to")

            onVisibleChanged: viewerWrapper.setHeaderVisibilityRequested(!visible)

            ContentPeerPicker {
                objectName: "sharePicker"
                showTitle: false
                anchors.fill: parent
                contentType: galleryPhotoViewer.media.type === MediaSource.Video ? ContentType.Videos : ContentType.Pictures
                handler: ContentHandler.Share

                onPeerSelected: {
                    overview.popPage();
                    sharePicker.visible = false;
                    var curTransfer = peer.request();
                    if (curTransfer.state === ContentTransfer.InProgress)
                    {
                        curTransfer.items = [ contentItemComp.createObject(parent, {"url": viewerWrapper.media.path}) ];
                        curTransfer.state = ContentTransfer.Charged;
                    }
                }
                onCancelPressed: {
                    overview.popPage();
                    sharePicker.visible = false;
                }
            }
        }

        Component {
            id: deleteDialog
            Dialog {
                id: dialogue
                objectName: "deletePhotoDialog"
                title: (galleryPhotoViewer.media.type === MediaSource.Photo) ? i18n.tr("Delete a photo") : i18n.tr("Delete a video")

                function finishRemove() {
                    if (!album === undefined)
                        return;
                    if (model.count === 0)
                        galleryPhotoViewer.closeRequested();
                }

                Button {
                    objectName: "deletePhotoDialogYes"
                    text: i18n.tr("Delete")
                    color: theme.palette.normal.negative
                    onClicked: {
                        PopupUtils.close(dialogue)
                        viewerWrapper.model.destroyMedia(galleryPhotoViewer.media, true);
                        galleryPhotoViewer.currentIndexChanged();
                        dialogue.finishRemove();
                    }
                }

                Button {
                    objectName: "deletePhotoDialogNo"
                    text: i18n.tr("Cancel")
                    onClicked: PopupUtils.close(dialogue)
                }
            }
        }

        Component {
            id: removeFromAlbumDialog
            Dialog {
                id: dialogue
                objectName: "removePhotoFromAlbumDialog"
                title: (galleryPhotoViewer.media.type === MediaSource.Photo) ? i18n.tr("Remove a photo from album") : i18n.tr("Remove a video from album")

                function finishRemove() {
                    if (model.count === 0)
                        galleryPhotoViewer.closeRequested();
                }

                Button {
                    objectName: "removeFromAlbumButton"
                    text: i18n.tr("Remove from Album")
                    color: theme.palette.normal.negative
                    onClicked: {
                        PopupUtils.close(dialogue)
                        viewerWrapper.model.removeMediaFromAlbum(album, galleryPhotoViewer.media);
                        dialogue.finishRemove();
                    }
                }

                Button {
                    objectName: "removeFromAlbumAndDeleteButton"
                    text: i18n.tr("Remove from Album and Delete")
                    onClicked: {
                        PopupUtils.close(dialogue)
                        viewerWrapper.model.destroyMedia(galleryPhotoViewer.media, true);
                        dialogue.finishRemove();
                    }
                }

                Button {
                    objectName: "removeFromAlbumCancelButton"
                    text: i18n.tr("Cancel")
                    onClicked: PopupUtils.close(dialogue)
                }
            }

        }

        onCloseRequested: viewerWrapper.closeRequested()
        onEditRequested: viewerWrapper.editRequested(media)
    }

    property int __pickerContentHeight: galleryPhotoViewer.height - units.gu(10)
    property PopupAlbumPicker __albumPicker
    Connections {
        target: __albumPicker
        onAlbumPicked: {
            album.addMediaSource(galleryPhotoViewer.media);
        }
        onNewAlbumPicked: {
            viewerWrapper.closeRequested();
        }
    }

    ActivityIndicator {
        id: busySpinner
        objectName: "busySpinner"
        anchors.centerIn: parent
        visible: media ? media.busy : false
        running: visible
    }

    Item {
        id: d

        property list<Action> mediaActions: [
            Action {
                objectName: "editButton"
                text: i18n.tr("Edit")
                iconName: "edit"
                visible: galleryPhotoViewer.media.type === MediaSource.Photo && galleryPhotoViewer.media.canBeEdited
                onTriggered: {
                    var path = galleryPhotoViewer.media.path.toString();
                    path = path.replace("file://", "")
                    var editor;
                    try {
                        Qt.createQmlObject('import QtQuick 2.9; import Lomiri.Components.Extras 0.2; Item {}', viewerWrapper);
                        editor = overview.pushPage(Qt.resolvedUrl("PhotoEditorPage.qml"), { photo: path });
                    } catch (e) {
                        console.log("WARNING: Unable to load PhotoEditor from Lomiri.Components.Extras");
                        return;
                    }
                    editor.done.connect(function(photoWasModified) {
                        if (photoWasModified) {
                            galleryPhotoViewer.media.refresh();
                            galleryPhotoViewer.media.dataChanged();
                        }
                        overview.popPage();
                    });
                }
            },
            Action {
                objectName: "addButton"
                text: i18n.tr("Add to album")
                iconName: "add"
                onTriggered: {
                    __albumPicker = PopupUtils.open(Qt.resolvedUrl("../Components/PopupAlbumPicker.qml"),
                                                    null,
                                                    {contentHeight: viewerWrapper.__pickerContentHeight});
                }
            },
            Action {
                objectName: "deleteButton"
                text: i18n.tr("Delete")
                iconName: "delete"
                onTriggered: {
                    if (album)
                        PopupUtils.open(removeFromAlbumDialog, null);
                    else
                        PopupUtils.open(deleteDialog, null);
                }
            },
            Action {
                objectName: "shareButton"
                text: i18n.tr("Share")
                iconName: "share"
                visible: !APP.desktopMode
                onTriggered: {
                    overview.pushPage(sharePicker)
                    sharePicker.visible = true;
                }
            },
            Action {
                objectName: "infoButton"
                text: i18n.tr("Info")
                iconName: "info"
                onTriggered: {
                    PopupUtils.open(mediaInfo)
                }
            }
        ]

        property Action backAction: Action {
            objectName: "backButton"
            iconName: "back"
            onTriggered: {
                galleryPhotoViewer.currentItem.reset();
                closeRequested();
            }
        }
    }

    Component {
        id: mediaInfo

        Dialog {
            id: mediaInfoDialog
            title: i18n.tr("Information")

            Label {
                text: i18n.tr("Media type: ") +
                      ((galleryPhotoViewer.media.type === MediaSource.Photo) ? i18n.tr("photo") : i18n.tr("video")) + "<br><br>" +
                      i18n.tr("Media name: ") + galleryPhotoViewer.media.path.toString() + "<br><br>" +
                      i18n.tr("Date: ") + galleryPhotoViewer.media.exposureDate.toLocaleString(Qt.locale(), "ddd MMM d yyyy") + "<br><br>" +
                      i18n.tr("Time: ") + galleryPhotoViewer.media.exposureTimeOfDay.toLocaleTimeString(Qt.locale(), "h:mm:ss a t")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                text: i18n.tr("ok")
                color: theme.palette.normal.focus
                onClicked: PopupUtils.close(mediaInfoDialog)
            }
        }
    }
}
