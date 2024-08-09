/*
 * Copyright (C) 2012-2015 Canonical Ltd.
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
 * Charles Lindsay <chaz@yorba.org>
 * Eric Gregory <eric@yorba.org>
 */

import QtQuick 2.9
import Gallery 1.0
import Lomiri.Components 1.3
import "../Components"

/*!
*/
Item {
    id: albumCover

    /*!
    */
    signal pressed(variant mouse)
    /*!
    */
    signal addPhotos()

    /*!
    */
    property Album album
    /*!
    */
    property bool isBack: false
    /*!
    */
    property bool isBlank: false
    /*!
    */
    property bool isPreview: true
    /*!
    */
    property real titleOpacity: 1
    /*!
    */
    property int titleDateSpacing: units.gu(2) // (Preview-sized; will scale up))

    /*!
    */
    property alias xScale: scale.xScale
    /*!
    */
    property alias yScale: scale.yScale

    // Read-only.
    // Represents the fully scaled border of the cover (without shadows.)
    // Numerical values are based on image pixels.
    property var internalRect: isPreview ? internalRectPreview : internalRectFull

    Item {
        id: internalRectPreview

        visible: false
        x : 9 * xScale
        y : 0
        width: xScale * (coverImagePreviewLeft.width + coverImagePreviewRight.width - 9 - 12)
        height : yScale * (coverImagePreviewLeft.height - 13)
    }

    Item {
        id: internalRectFull

        visible: false
        x : 18 * xScale
        y : 0
        width: xScale * (coverImageFull.width - 18 - 11)
        height : xScale * (coverImageFull.height - 14)
    }

    /*!
  */
    property real spacerScale: cover.height / units.gu(33) // ratio of image height to canonical height
    // Text margins.  Specified as fractions of cover width for scaling (eyeballed)
    property real coverMarginLeft: width / 7
    /*!
  */
    property real coverMarginRight: width / 26
    /*!
  */
    property real coverStartY: height / 50
    /*!
  */
    property variant coverElement: album !== null ?
                                       coverList.elementForCoverName(album.coverNickname) : coverList.getDefault();

    readonly property alias isTextEditing: cover.isTextEditing

    // Stops editing title/subtitle.
    function editingDone() {
        title.focus = false
        subtitle.focus = false
        cover.isTextEditing = false
    }

    Item {
        id: cover

        property bool isTextEditing: false

        // Read-only
        property int previewPixelWidth: coverImagePreviewLeft.width
                                        + coverImagePreviewRight.width

        anchors.fill: parent

        transform: Scale {
            id: scale
        }

        AlbumCoverList {
            id: coverList
        }

        Image {
            id: coverImagePreviewLeft

            source: "img/album-cover-preview-left.png"
            visible: isPreview

            width: isPreview ? 6 : undefined
            height: isPreview ? 281 : undefined

            anchors.left: parent.left
            anchors.top: parent.top
            cache: true
        }

        Image {
            id: coverImagePreviewRight

            source: coverElement.imagePreview
            visible: isPreview

            width: isPreview ? 229 : undefined
            height: isPreview ? 281 : undefined

            anchors.left: coverImagePreviewLeft.right
            anchors.top: parent.top
            cache: true
        }

        // Must be positioned before TextEdit elements to capture mouse events
        // underneath the album title.
        MouseArea {
            anchors.fill: parent

            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: {
                mouse.accepted = false;
                albumCover.pressed(mouse);
            }
        }

        Image {
            id: coverImageFull
            objectName: "albumCoverImage"

            source: coverElement.imageFull
            visible: !isPreview

            anchors.fill: parent
            cache: true

            Image {
                id: addPhotosImage
                objectName: "albumCoverAddPhotosImage"

                // Size ratio of image to screen space.
                property real sizeRatio: coverImageFull.parent.width / coverImageFull.sourceSize.width

                source: coverElement.addFilename
                visible: !isPreview

                // Eyeballed in GIMP
                x: 543 * sizeRatio
                y: 0
                width: sourceSize.width * sizeRatio
                height: sourceSize.height * sizeRatio

                MouseArea {
                    id: addPhotosButton

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent
                    onClicked: addPhotos()
                }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: coverMarginLeft
            anchors.rightMargin: coverMarginRight
            anchors.top: parent.top
            anchors.topMargin: coverStartY

            visible: !isBack && !isBlank

            // Spacer
            Item {
                id: spacerTop

                width: 1
                height: units.gu(5) * spacerScale
            }

            Item {
                id: titleContainer
                height: title.height
                width: parent.width

                Rectangle {
                    id: titleBackground

                    color: "black"
                    opacity: 0.5
                    visible: !isPreview

                    anchors.top: titleContainer.top
                    height: title.height
                    width: parent.width
                }

                TextEdit{
                    id: title
                    objectName: "albumTitleField"
                    anchors{
                        top: titleContainer.top
                        left: parent.left
                        right: parent.right
                    }
                    readOnly: isPreview
                    enabled: !readOnly // do not block mouse clicks when readOnly
                    opacity: titleOpacity
                    color: "#ffffff"
                    font.family: "Ubuntu"
                    font.pixelSize: albumCover.height * 0.09
                    smooth: true
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter

                    text: album ? album.title : ""

                    // workaround to limit lineCount
                    // Idea taken from: https://bugreports.qt-project.org/browse/QTBUG-12304
                    // this workaround should be replaceable with maximumLength property in Qt 5.15
                    readonly property int maximumLineCount: 2
                    property string previousText: ""
                    onTextChanged: {
                        if (lineCount > maximumLineCount) {
                            var cursor = cursorPosition;
                            text = previousText;
                            cursorPosition = cursor > text.length ? text.length : cursor - 1;
                        }

                        // Save text so we can revert if necessary.
                        previousText = text;
                    }

                    Keys.onPressed: {
                        // when pressing enter: give focus to subtitle + don't insert line break character to title
                        if (event.key === Qt.Key_Return) {
                            subtitle.forceActiveFocus()
                            event.accepted = true
                        }
                    }

                    // commit changes when leaving or destroying the text field
                    onActiveFocusChanged: {
                        if (!activeFocus && album)
                            album.title = text
                    }
                    Component.onDestruction: {
                        if (album)
                            album.title = text
                    }
                }
            }

            // Spacer
            Item {
                width: 1
                height: titleDateSpacing * spacerScale
            }

            Item {
                id: subtitleContainer
                height: title.height
                width: parent.width

                Rectangle {
                    id: subtitleBackground

                    color: "black"
                    opacity: 0.5
                    visible: !isPreview

                    anchors.top: subtitleContainer.top
                    height: subtitle.height
                    width: parent.width
                }

                TextEdit{
                    id: subtitle
                    objectName: "albumSubtitleField"
                    anchors{
                        top: subtitleContainer.top
                        left: parent.left
                        right: parent.right
                    }
                    readOnly: isPreview
                    enabled: !readOnly // do not block mouse clicks when readOnly
                    opacity: titleOpacity
                    color: "#ffffff"
                    font.family: "Ubuntu"
                    font.pixelSize: albumCover.height * 0.07
                    smooth: true
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter

                    text: album ? album.subtitle : ""

                    // workaround to limit lineCount
                    // Idea taken from: https://bugreports.qt-project.org/browse/QTBUG-12304
                    // this workaround should be replaceable with maximumLength property in Qt 5.15
                    readonly property int maximumLineCount: 2
                    property string previousText: ""
                    onTextChanged: {
                        if (lineCount > maximumLineCount) {
                            var cursor = cursorPosition;
                            text = previousText;
                            cursorPosition = cursor > text.length ? text.length : cursor - 1;
                        }

                        // Save text so we can revert if necessary.
                        previousText = text;
                    }

                    Keys.onPressed: {
                        // when pressing enter: leave focus + don't insert line break character to title
                        if (event.key === Qt.Key_Return) {
                            subtitle.focus = false
                            event.accepted = true
                        }
                    }

                    // commit changes when leaving or destroying the text field
                    onActiveFocusChanged: {
                        if (!activeFocus)
                            album.subtitle = text
                    }
                    Component.onDestruction: album.subtitle = text
                }
            }
        }
    }
}
