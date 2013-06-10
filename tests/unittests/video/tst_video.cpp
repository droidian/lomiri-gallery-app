/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QtTest/QtTest>
#include <QString>

#include "video.h"

class tst_Video : public QObject
{
  Q_OBJECT

private slots:
    void galleryPath();
    void galleryPreviewPath();
    void galleryThumbnailPath();
};

void tst_Video::galleryPath()
{
    QFileInfo fi;
    Video video(fi);
    QCOMPARE(video.galleryPath().toString().endsWith(QString("img/video-thumbnail.png")), true);
}

void tst_Video::galleryPreviewPath()
{
    QFileInfo fi;
    Video video(fi);
    QCOMPARE(video.galleryPreviewPath().toString().endsWith(QString("img/video-thumbnail.png")), true);
}

void tst_Video::galleryThumbnailPath()
{
    QFileInfo fi;
    Video video(fi);
    QCOMPARE(video.galleryThumbnailPath().toString().endsWith(QString("img/video-thumbnail.png")), true);
}

QTEST_MAIN(tst_Video);

#include "tst_video.moc"
