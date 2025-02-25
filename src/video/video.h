/*
 * Copyright (C) 2013 Canonical Ltd.
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
 */

#ifndef GALLERY_VIDEO_H_
#define GALLERY_VIDEO_H_

// media
#include "media-source.h"

#include <QFileInfo>

/*!
 * \brief The Video class represents one video file
 */
class Video : public MediaSource
{
    Q_OBJECT

public:
    explicit Video(const QFileInfo& file);

    virtual MediaType type() const;

    virtual QImage image(bool respectOrientation = true, const QSize &scaleSize=QSize());

    static bool isCameraVideo(const QFileInfo& file);

    static bool isValid(const QFileInfo& file);

private:
    friend class tst_Video;
};

#endif  // GALLERY_VIDEO_H_
