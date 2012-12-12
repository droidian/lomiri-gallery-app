/*
 * Copyright (C) 2012 Canonical Ltd
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

import QtQuick 2.0
import Gallery 1.0
import Ubuntu.Components 0.1
import "../../Capetown"
import "../Utility"

Item {
  id: albumCover
  
  signal pressed(variant mouse)
  signal addPhotos()
  
  property Album album
  property bool isBack: false
  property bool isBlank: false
  property bool isPreview: true
  property real titleOpacity: 1
  property int titleDateSpacing: units.gu(2) // (Preview-sized; will scale up))
  
  property alias xScale: scale.xScale
  property alias yScale: scale.yScale
  
  // internal
  // Scale text and spacers by factor of cover size. 
  property real textScale: isPreview || width <= 0 || cover.previewPixelWidth <= 0 
    ? 1 : coverImageFull.sourceSize.width / cover.previewPixelWidth
  property real spacerScale: cover.height / units.gu(33) // ratio of image height to canonical height
  // Text margins.  Specified as fractions of cover width for scaling (eyeballed)
  property real coverMarginLeft: width / 7
  property real coverMarginRight: width / 26
  property real coverStartY: height / 50
  property variant coverElement: album !== null ?
    coverList.elementForActionName(album.coverNickname) : coverList.getDefault();
  
  // Read-only
  property bool isTextEditing: title.isEditing || subtitle.isEditing
  
  // Stops editing title/subtitle.
  function editingDone() {
    title.done();
    subtitle.done();
  }
  
  Item {
    id: cover
    
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
      
      source: coverElement.imageFull
      visible: !isPreview
      
      anchors.fill: parent
      cache: true
      
      Image {
        id: addPhotosImage
        
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
          
          anchors.top: titleContainer.top
          height: title.height
          width: parent.width
        }
        
        TextEditOnClick {
          id: title
          objectName: "albumTitleField"
          
          text: (album) ? album.title : ""
          onTextUpdated: album.title = text
          
          editable: !isPreview
          
          anchors.top: titleContainer.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          
          opacity: titleOpacity
          color: "#ffffff"
          
          fontFamily: "Ubuntu"
          // Subtract small amount due to a slight mismatch in preview vs. 
          // full album cover aspect ratios.
          fontPointSize: (pointUnits(16) * textScale) - (isPreview ? 2 : 0)
          smooth: true
          textFormat: TextEdit.PlainText
          
          wrapMode: Text.Wrap
          horizontalAlignment: Text.AlignHCenter
          
          onEnterPressed: {
            // If the user hits enter, start editing the subtitle.
            done();
            subtitle.start(-1, -1);
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
          
          anchors.top: subtitleContainer.top
          height: subtitle.height
          width: parent.width
        }
        
        TextEditOnClick {
          id: subtitle
          objectName: "albumSubtitleField"
          
          text: (album) ? album.subtitle : ""
          onTextUpdated: album.subtitle = text
          
          editable: !isPreview
          
          anchors.top: subtitleContainer.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          
          opacity: titleOpacity
          color: "#ffffff"
          
          fontFamily: "Ubuntu"
          
          // Subtract small amount due to a slight mismatch in preview vs. 
          // full album cover aspect ratios.
          fontPointSize: (pointUnits(10) * textScale) - (isPreview ? 1 : 0)
          smooth: true
          textFormat: TextEdit.PlainText
          
          wrapMode: Text.Wrap
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
