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
 * Clint Rogers <clinton@yorba.org>
 * Lucas Beeler <lucas@yorba.org>
 */

import QtQuick 2.9
import Lomiri.Components 1.3
import "../../js/Gallery.js" as Gallery
import "../Utility"

/*!
*/
LomiriShape {
    id: eventCard

    /*!
    */
    property variant event
    /*!
    */

    radius: "medium"
    backgroundColor: theme.palette.normal.base

    width: units.gu(12)
    height: units.gu(12)

    Label {
        id: eventMonthYear

        y: units.gu(1.5)
        width: parent.width - units.gu(2)
        height: units.gu(1)
        anchors.horizontalCenter: parent.horizontalCenter

        font.pixelSize: units.dp(12)

        font.capitalization: Font.AllUppercase
        horizontalAlignment: Text.AlignHCenter

        /// The event lomirishape's month/year part, keep as is unless you know what you're doing
        text: (event) ? Qt.formatDate(event.date, i18n.tr("MMM yyyy")) : ""
        color: theme.palette.normal.baseText
    }

    Label {
        id: eventDay

        anchors.top: eventMonthYear.bottom
        width: parent.width

        font.pixelSize: units.dp(67)

        horizontalAlignment: Text.AlignHCenter

        /// The event lomirishape's day part, keep as is unless you know what you're doing
        text: (event) ? Qt.formatDate(event.date, i18n.tr("dd")) : ""
        color: theme.palette.normal.baseText
    }
}
