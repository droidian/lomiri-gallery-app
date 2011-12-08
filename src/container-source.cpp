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

#include "container-source.h"

ContainerSource::ContainerSource() {
  QObject::connect(&contained_,
    SIGNAL(contents_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)),
    this,
    SLOT(on_contents_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));
}

void ContainerSource::Attach(DataObject* object) {
  contained_.Add(object);
}

void ContainerSource::AttachMany(const QSet<DataObject*>& objects) {
  contained_.AddMany(objects);
}

const ViewCollection* ContainerSource::ContainedObjects() const {
  return &contained_;
}

void ContainerSource::notify_container_contents_altered(const QSet<DataObject*>* added,
  const QSet<DataObject*>* removed) {
  emit container_contents_altered(added, removed);
}

void ContainerSource::on_contents_altered(const QSet<DataObject*>* added,
  const QSet<DataObject*>* removed) {
  notify_container_contents_altered(added, removed);
}
