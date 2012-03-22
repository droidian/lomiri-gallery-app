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
 * Jim Nelson <jim@yorba.org>
 */

import QtQuick 1.1

Item {
  property alias mediaSource: photo.mediaSource
  property real leftMargin
  property real rightMargin
  property real topMargin
  property real bottomMargin
  property alias isPreview: photo.isPreview
  
  anchors.leftMargin: leftMargin
  anchors.rightMargin: rightMargin
  anchors.topMargin: topMargin
  anchors.bottomMargin: bottomMargin

  PhotoComponent {
    id: photo

    anchors.fill: parent

    ownerName: "FramePortrait"
    isCropped: true
  }
}
