/*
 * Copyright (C) 2011 Canonical Ltd
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
 * Charles Lindsay <chaz@yorba.org>
 */

import QtQuick 1.1
import Gallery 1.0
import "../Capetown"

// Some custom components and animations that we want to invoke whenever we
// bring up the album viewer.
Item {
  id: albumViewerTransition
  
  property Album album
  property Rectangle backgroundGlass
  property int durationMsec: 200
  
  function transitionToAlbumViewer(album, thumbnailRect) {
    var translatedRect = mapFromItem(application, thumbnailRect.x, thumbnailRect.y);
    translatedRect.width = thumbnailRect.width;
    translatedRect.height = thumbnailRect.height;
    
    albumViewerTransition.album = album;
    
    expandAlbum.x = translatedRect.x;
    expandAlbum.y = translatedRect.y;
    expandAlbum.width = translatedRect.width;
    expandAlbum.height = translatedRect.height;
    
    showAlbumViewerAnimation.start();
  }

  function transitionFromAlbumViewer(album, thumbnailRect) {
    var translatedRect = mapFromItem(application, thumbnailRect.x, thumbnailRect.y);
    translatedRect.width = thumbnailRect.width;
    translatedRect.height = thumbnailRect.height;
    
    albumViewerTransition.album = album;
    
    expandAlbum.x = 0;
    expandAlbum.y = 0;
    expandAlbum.width = width;
    expandAlbum.height = height;
    hideAlbumViewerAnimation.thumbnailRect = translatedRect;
    
    hideAlbumViewerAnimation.start();
  }

  function dissolve(fadeOutTarget, fadeInTarget) {
    dissolveAlbumViewerTransition.fadeOutTarget = fadeOutTarget;
    dissolveAlbumViewerTransition.fadeInTarget = fadeInTarget;
    dissolveAlbumViewerTransition.start();
  }

  signal transitionToAlbumViewerCompleted()
  signal transitionFromAlbumViewerCompleted()
  signal dissolveCompleted(variant fadeOutTarget, variant fadeInTarget)

  AlbumPreviewComponent {
    id: expandAlbum
    
    album: parent.album
    
    visible: false
  }

  SequentialAnimation {
    id: showAlbumViewerAnimation

    PropertyAction { target: expandAlbum; property: "visible"; value: true; }
    
    PropertyAction {
      target: backgroundGlass
      property: "opacity"
      value: 0.0
    }
    
    ParallelAnimation {
      ExpandAnimation {
        target: expandAlbum
        endHeight: albumViewerTransition.height + expandAlbum.nameHeight
        duration: durationMsec
      }

      PropertyAnimation {
        target: backgroundGlass
        property: "opacity"
        to: 1.0
        duration: durationMsec
      }
    }

    PropertyAction { target: expandAlbum; property: "visible"; value: false; }
    PropertyAction { target: backgroundGlass; property: "opacity"; value: 0.0; }

    onCompleted: {
      transitionToAlbumViewerCompleted();
    }
  }

  SequentialAnimation {
    id: hideAlbumViewerAnimation

    property variant thumbnailRect: {"x": 0, "y": 0, "width": 0, "height": 0}

    PropertyAction { target: expandAlbum; property: "visible"; value: true; }
    
    PropertyAction {
      target: backgroundGlass
      property: "opacity"
      value: 1.0
    }
    
    ParallelAnimation {
      ExpandAnimation {
        target: expandAlbum
        endX: hideAlbumViewerAnimation.thumbnailRect.x
        endY: hideAlbumViewerAnimation.thumbnailRect.y
        endWidth: hideAlbumViewerAnimation.thumbnailRect.width
        endHeight: hideAlbumViewerAnimation.thumbnailRect.height
        duration: durationMsec
        easingType: Easing.OutQuad
      }

      PropertyAnimation {
        target: backgroundGlass
        property: "opacity"
        to: 0.0
        duration: durationMsec
      }
    }
    PropertyAction { target: expandAlbum; property: "visible"; value: false; }

    onCompleted: {
      transitionFromAlbumViewerCompleted();
    }
  }

  DissolveAnimation {
    id: dissolveAlbumViewerTransition

    fadeOutTarget: Rectangle { } // Dummy Rectangle to avoid compilation errors.
    fadeInTarget: Rectangle { } // Dummy Rectangle to avoid compilation errors.

    onCompleted: {
      dissolveCompleted(fadeOutTarget, fadeInTarget);
    }
  }
}
