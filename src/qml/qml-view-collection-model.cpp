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

#include "qml-view-collection-model.h"
#include "container-source.h"
#include "data-object.h"
#include "selectable-view-collection.h"
#include "util/variants.h"

/*!
 * \brief QmlViewCollectionModel::QmlViewCollectionModel
 * \param parent
 * \param objectTypeName
 * \param default_comparator
 */
QmlViewCollectionModel::QmlViewCollectionModel(QObject* parent, const QString& objectTypeName,
                                               DataObjectComparator default_comparator)
    : QAbstractListModel(parent), view_(NULL), default_comparator_(default_comparator),
      head_(0), limit_(-1)
{
    roles_.insert(ObjectRole, "object");
    roles_.insert(SelectionRole, "isSelected");
    roles_.insert(TypeNameRole, "typeName");

    // allow for subclasses to give object a semantically-significant name
    if (!objectTypeName.isEmpty())
        roles_.insert(SubclassRole, objectTypeName.toLatin1());
}

/*!
 * \brief QmlViewCollectionModel::~QmlViewCollectionModel
 */
QmlViewCollectionModel::~QmlViewCollectionModel()
{
    delete view_;
}

/*!
 * \brief QmlViewCollectionModel::for_collection
 * \return
 */
QVariant QmlViewCollectionModel::for_collection() const
{
    return collection_;
}

/*!
 * \brief QmlViewCollectionModel::set_for_collection
 * \param var
 */
void QmlViewCollectionModel::set_for_collection(QVariant var)
{
    QObject* obj = qvariant_cast<QObject*>(var);
    if (obj == NULL) {
        // Print a warning if we got an unexpected type.  If the type is QObject*,
        // we assume it's uninitialized and nothing to worry about.
        if (var.isValid() && ((QMetaType::Type) var.type()) != QMetaType::QObjectStar)
            qDebug("Unable to set collection of type %s", var.typeName());

        StopMonitoring();

        return;
    }

    ContainerSource* container = qobject_cast<ContainerSource*>(obj);
    if (container != NULL) {
        collection_ = var;
        MonitorContainerSource(container);

        return;
    }

    SourceCollection* source = qobject_cast<SourceCollection*>(obj);
    if (source != NULL) {
        collection_ = var;
        MonitorSourceCollection(source);

        return;
    }

    StopMonitoring();

    qDebug("Unable to set collection that is neither ContainerSource nor SourceCollection");
}

/*!
 * \brief QmlViewCollectionModel::monitor_selection
 * \return
 */
QVariant QmlViewCollectionModel::monitor_selection() const
{
    return monitor_selection_;
}

/*!
 * \brief QmlViewCollectionModel::set_monitor_selection
 * \param vmodel
 */
void QmlViewCollectionModel::set_monitor_selection(QVariant vmodel)
{
    // always stop monitoring
    monitor_selection_ = QVariant();
    if (view_ != NULL)
        view_->stopMonitoringSelectionState();
    
    QmlViewCollectionModel* model = UncheckedVariantToObject<QmlViewCollectionModel*>(vmodel);
    if (model == NULL) {
        if (vmodel.isValid())
            qDebug("Unable to monitor selection of type %s", vmodel.typeName());

        return;
    }

    monitor_selection_ = vmodel;
    if (view_ != NULL)
        view_->monitorSelectionState(model->view_);
}

/*!
 * \brief QmlViewCollectionModel::indexOf
 * \param var
 * \return
 */
int QmlViewCollectionModel::indexOf(QVariant var)
{
    DataObject* object = UncheckedVariantToObject<DataObject*>(var);
    if (object == NULL)
        return -1;

    return (view_ != NULL) ? view_->indexOf(object) : -1;
}

/*!
 * \brief QmlViewCollectionModel::getAt
 * \param index
 * \return
 */
QVariant QmlViewCollectionModel::getAt(int index)
{
    if (view_ == NULL || index < 0)
        return QVariant();

    DataObject* object = view_->getAt(index);

    return (object != NULL) ? VariantFor(object) : QVariant();
}

/*!
 * \brief QmlViewCollectionModel::clear
 */
void QmlViewCollectionModel::clear()
{
    StopMonitoring();
}

/*!
 * \brief QmlViewCollectionModel::add
 * \param var
 */
void QmlViewCollectionModel::add(QVariant var)
{
    DataObject* object = FromVariant(var);
    if (object == NULL) {
        qDebug("Unable to convert variant into appropriate DataObject");

        return;
    }

    if (view_ == NULL) {
        SelectableViewCollection* view = new SelectableViewCollection("Manual ViewCollection");
        if (default_comparator_ != NULL)
            view->setComparator(default_comparator_);

        SetBackingViewCollection(view);
    }

    view_->add(object);
}

/*!
 * \brief QmlViewCollectionModel::selectAll
 */
void QmlViewCollectionModel::selectAll()
{
    if (view_ != NULL)
        view_->selectAll();
}

/*!
 * \brief QmlViewCollectionModel::unselectAll
 */
void QmlViewCollectionModel::unselectAll()
{
    if (view_ != NULL)
        view_->unselectAll();
}

/*!
 * \brief QmlViewCollectionModel::toggleSelection
 * \param var
 */
void QmlViewCollectionModel::toggleSelection(QVariant var)
{
    if (view_ != NULL)
        view_->toggleSelect(VariantToObject<DataObject*>(var));
}

/*!
 * \brief QmlViewCollectionModel::isSelected
 * \param var
 * \return
 */
bool QmlViewCollectionModel::isSelected(QVariant var)
{
    return (view_ != NULL && var.isValid()
            ? view_->isSelected(VariantToObject<DataObject*>(var))
            : false);
}

/*!
 * \brief QmlViewCollectionModel::rowCount
 * \param parent
 * \return
 */
int QmlViewCollectionModel::rowCount(const QModelIndex& parent) const
{
    return count();
}

/*!
 * \brief QmlViewCollectionModel::data
 * \param index
 * \param role
 * \return
 */
QVariant QmlViewCollectionModel::data(const QModelIndex& index, int role) const
{
    if (view_ == NULL)
        return QVariant();

    if (limit_ == 0)
        return QVariant();

    // calculate actual starting index from the head (a negative head means to
    // start from n elements from the tail of the list; relying on negative value
    // for addition in latter part of ternary operator her)
    int real_start = (head_ >= 0) ? head_ : view_->count() + head_;
    int real_index = index.row() + real_start;

    // bounds checking
    if (real_index < 0 || real_index >= view_->count())
        return QVariant();

    // watch for indexing beyond upper limit
    if (limit_ > 0 && real_index >= (real_start + limit_))
        return QVariant();

    DataObject* object = view_->getAt(real_index);
    if (object == NULL)
        return QVariant();

    switch (role) {
    case ObjectRole:
    case SubclassRole:
        return VariantFor(object);

    case SelectionRole:
        return QVariant(view_->isSelected(object));

    case TypeNameRole:
        // Return type name with the pointer ("*") removed
        return QVariant(QString(VariantFor(object).typeName()).remove('*'));

    default:
        return QVariant();
    }
}

/*!
 * \brief QmlViewCollectionModel::count
 * \return
 */
int QmlViewCollectionModel::count() const
{
    int count = (view_ != NULL) ? view_->count() : 0;

    // account for head (if negative, means head of list starts at tail)
    count -= (head_ > 0) ? head_ : (-head_);

    // watch for underflow
    if (count < 0)
        count = 0;

    // apply limit, if set
    if (limit_ >= 0 && count > limit_)
        count = limit_;

    return count;
}

/*!
 * \brief QmlViewCollectionModel::raw_count
 * \return
 */
int QmlViewCollectionModel::raw_count() const
{
    return (view_ != NULL) ? view_->count() : 0;
}

/*!
 * \brief QmlViewCollectionModel::selected_count
 * \return
 */
int QmlViewCollectionModel::selected_count() const
{
    // TODO: Selected count should honor limit and head as well
    return (view_ != NULL) ? view_->selectedCount() : 0;
}

/*!
 * \brief QmlViewCollectionModel::head
 * \return
 */
int QmlViewCollectionModel::head() const
{
    return head_;
}

void QmlViewCollectionModel::set_head(int head) {
    if (head_ == head)
        return;

    head_ = head;

    emit head_changed();
    // TODO: this could be checked for and optimized instead of nuking it all.
    emit count_changed();
    NotifyReset();
}

/*!
 * \brief QmlViewCollectionModel::limit
 * \return
 */
int QmlViewCollectionModel::limit() const
{
    return limit_;
}

/*!
 * \brief QmlViewCollectionModel::set_limit
 * \param limit
 */
void QmlViewCollectionModel::set_limit(int limit)
{
    int normalized = (limit >= 0) ? limit : -1;

    if (limit_ == normalized)
        return;

    limit_ = normalized;

    emit limit_changed();
    emit count_changed();
    NotifyReset();
}

/*!
 * \brief QmlViewCollectionModel::clear_limit
 */
void QmlViewCollectionModel::clear_limit()
{
    set_limit(-1);
}

/*!
 * \brief QmlViewCollectionModel::SetBackingViewCollection
 * \param view
 */
void QmlViewCollectionModel::SetBackingViewCollection(SelectableViewCollection* view)
{
    int old_count = (view_ != NULL) ? view_->count() : 0;
    int old_selected_count = (view_ != NULL) ? view_->selectedCount() : 0;

    DisconnectBackingViewCollection();

    beginResetModel();

    view_ = view;

    endResetModel();

    QObject::connect(view_,
                     SIGNAL(selectionChanged(const QSet<DataObject*>*, const QSet<DataObject*>*)),
                     this,
                     SLOT(on_selection_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));

    QObject::connect(view_,
                     SIGNAL(contentsAboutToBeChanged(const QSet<DataObject*>*, const QSet<DataObject*>*)),
                     this,
                     SLOT(on_contents_to_be_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));

    QObject::connect(view_,
                     SIGNAL(contentsChanged(const QSet<DataObject*>*, const QSet<DataObject*>*)),
                     this,
                     SLOT(on_contents_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));

    QObject::connect(view_, SIGNAL(orderingChanged()),
                     this, SLOT(on_ordering_altered()));

    notify_backing_collection_changed();

    if (old_count != view_->count()) {
        emit raw_count_changed();
        // TODO: we could maybe check for this instead of always firing it.
        emit count_changed();
    }

    if (old_selected_count != view_->selectedCount())
        emit selectedCountChanged();
}

/*!
 * \brief QmlViewCollectionModel::DisconnectBackingViewCollection
 */
void QmlViewCollectionModel::DisconnectBackingViewCollection()
{
    if (view_ == NULL)
        return;

    QObject::disconnect(view_,
                        SIGNAL(selectionChanged(const QSet<DataObject*>*, const QSet<DataObject*>*)),
                        this,
                        SLOT(on_selection_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));

    QObject::disconnect(view_,
                        SIGNAL(contentsAboutToBeChanged(const QSet<DataObject*>*, const QSet<DataObject*>*)),
                        this,
                        SLOT(on_contents_to_be_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));

    QObject::disconnect(view_,
                        SIGNAL(contentsChanged(const QSet<DataObject*>*, const QSet<DataObject*>*)),
                        this,
                        SLOT(on_contents_altered(const QSet<DataObject*>*, const QSet<DataObject*>*)));

    QObject::disconnect(view_, SIGNAL(orderingChanged()),
                        this, SLOT(on_ordering_altered()));

    beginResetModel();

    delete view_;
    view_ = NULL;

    endResetModel();
}

/*!
 * \brief QmlViewCollectionModel::BackingViewCollection
 * \return
 */
SelectableViewCollection* QmlViewCollectionModel::BackingViewCollection() const
{
    return view_;
}

/*!
 * \brief QmlViewCollectionModel::default_comparator
 * \return
 */
DataObjectComparator QmlViewCollectionModel::default_comparator() const
{
    return default_comparator_;
}

/*!
 * \brief QmlViewCollectionModel::set_default_comparator
 * \param comparator
 */
void QmlViewCollectionModel::set_default_comparator(DataObjectComparator comparator)
{
    default_comparator_ = comparator;
}

/*!
 * \brief QmlViewCollectionModel::MonitorSourceCollection
 * \param sources
 */
void QmlViewCollectionModel::MonitorSourceCollection(SourceCollection* sources)
{
    SelectableViewCollection* view = new SelectableViewCollection("MonitorSourceCollection");
    if (default_comparator_ != NULL)
        view->setComparator(default_comparator_);
    view->monitorDataCollection(sources, NULL, (default_comparator_ == NULL));

    SetBackingViewCollection(view);
}

/*!
 * \brief QmlViewCollectionModel::MonitorContainerSource
 * \param container
 */
void QmlViewCollectionModel::MonitorContainerSource(ContainerSource* container)
{
    SelectableViewCollection* view = new SelectableViewCollection("MonitorContainerSource");
    if (default_comparator_ != NULL)
        view->setComparator(default_comparator_);
    view->monitorDataCollection(container->contained(), NULL,
                                (default_comparator_ == NULL));

    SetBackingViewCollection(view);
}

/*!
 * \brief QmlViewCollectionModel::IsMonitoring
 * \return
 */
bool QmlViewCollectionModel::IsMonitoring() const
{
    return view_ != NULL && view_->isMonitoring();
}

/*!
 * \brief QmlViewCollectionModel::StopMonitoring
 */
void QmlViewCollectionModel::StopMonitoring()
{
    if (view_ == NULL)
        return;

    int old_count = view_->count();
    int old_selected_count = view_->selectedCount();

    DisconnectBackingViewCollection();

    notify_backing_collection_changed();

    if (old_count != 0) {
        emit raw_count_changed();
        emit count_changed();
    }

    if (old_selected_count != 0)
        emit selectedCountChanged();
}

/*!
 * \brief QmlViewCollectionModel::notify_backing_collection_changed
 */
void QmlViewCollectionModel::notify_backing_collection_changed()
{
    emit backing_collection_changed();
}

/*!
 * \brief QmlViewCollectionModel::NotifyElementAdded
 * This notifies model subscribers that the element has been added at the
 * particular index ... note that QmlViewCollectionModel monitors
 * the SelectableViewCollections "contents-altered" signal already
 * \param index
 */
void QmlViewCollectionModel::NotifyElementAdded(int index)
{
    if (index >= 0) {
        beginInsertRows(QModelIndex(), index, index);
        endInsertRows();
    }
}

/*!
 * \brief QmlViewCollectionModel::NotifyElementRemoved
 * This notifies model subscribers that the element at this index was
 * removed ... note that QmlViewCollectionModel monitors the
 * SelectableViewCollections' "contents-altered" signal already
 * \param index
 */
void QmlViewCollectionModel::NotifyElementRemoved(int index)
{
    if (index >= 0) {
        beginRemoveRows(QModelIndex(), index, index);
        endRemoveRows();
    }
}

/*!
 * \brief QmlViewCollectionModel::NotifyElementAltered
 * This notifies model subscribers that the element at the particular index
 * has been altered in some way.
 * \param index
 * \param role
 */
void QmlViewCollectionModel::NotifyElementAltered(int index, int role)
{
    if (index >= 0) {
        QModelIndex model_index = createIndex(index, role);
        emit dataChanged(model_index, model_index);
    }
}

/*!
 * \brief QmlViewCollectionModel::NotifySetAltered
 * \param list
 * \param role
 */
void QmlViewCollectionModel::NotifySetAltered(const QSet<DataObject*>* list, int role)
{
    DataObject* object;
    foreach (object, *list)
        NotifyElementAltered(view_->indexOf(object), role);
}

/*!
 * \brief QmlViewCollectionModel::NotifyReset Tells model subscribers that everything has changed.
 */
void QmlViewCollectionModel::NotifyReset()
{
    beginResetModel();
    endResetModel();
}

/*!
 * \brief QmlViewCollectionModel::roleNames
 * \return
 */
QHash<int, QByteArray> QmlViewCollectionModel::roleNames() const
{
    return roles_;
}

/*!
 * \brief QmlViewCollectionModel::on_selection_altered
 * \param selected
 * \param unselected
 */
void QmlViewCollectionModel::on_selection_altered(const QSet<DataObject*>* selected,
                                                  const QSet<DataObject*>* unselected)
{
    if (selected != NULL)
        NotifySetAltered(selected, SelectionRole);

    if (unselected != NULL)
        NotifySetAltered(unselected, SelectionRole);

    emit selectedCountChanged();
}

/*!
 * \brief QmlViewCollectionModel::on_contents_to_be_altered
 * \param added
 * \param removed
 */
void QmlViewCollectionModel::on_contents_to_be_altered(const QSet<DataObject*>* added,
                                                       const QSet<DataObject*>* removed)
{
    // Gather the indexes of all the elements to be removed before removal,
    // then report their removal when they've actually been removed
    if (removed != NULL) {
        // should already be cleared; either first use or cleared in on_contents_altered()
        Q_ASSERT(to_be_removed_.count() == 0);
        DataObject* object;
        foreach (object, *removed) {
            int index = view_->indexOf(object);
            Q_ASSERT(index >= 0);
            to_be_removed_.append(index);
        }
    }
}

/*!
 * \brief QmlViewCollectionModel::on_contents_altered
 * \param added
 * \param removed
 */
void QmlViewCollectionModel::on_contents_altered(const QSet<DataObject*>* added,
                                                 const QSet<DataObject*>* removed)
{
    // Report removed items using indices gathered from on_contents_to_be_altered()
    if (to_be_removed_.count() > 0) {
        // sort indices in reverse order and walk in descending order so they're
        // always accurate as items are "removed"
        qSort(to_be_removed_.begin(), to_be_removed_.end(), IntReverseLessThan);

        // Only if we aren't getting a sub-view do we directly map these up to QML.
        if (head_ == 0 && limit_ < 0) {
            int index;
            foreach (index, to_be_removed_)
                NotifyElementRemoved(index);
        }

        to_be_removed_.clear();
    }

    // Report inserted items after they've been inserted
    if (added != NULL) {
        // sort the indices in ascending order so each element is added in the
        // right place inside the "virtual" list held by QAbstractListModel
        QList<int> indices;

        DataObject* object;
        foreach (object, *added)
            indices.append(view_->indexOf(object));

        qSort(indices.begin(), indices.end(), IntLessThan);

        // Again, don't map directly to QML if we're only getting a sub-view.
        if (head_ == 0 && limit_ < 0) {
            int index;
            foreach (index, indices)
                NotifyElementAdded(index);
        }
    }

    // TODO: "filtered" views get some special treatment.  Instead of figuring
    // out how each addition/deletion affects it, we just wipe the whole thing
    // out each time it's altered.  This is probably wasteful.
    if (head_ != 0 || limit_ >= 0)
        NotifyReset();

    emit raw_count_changed();
    emit count_changed();
}

/*!
 * \brief QmlViewCollectionModel::on_ordering_altered
 */
void QmlViewCollectionModel::on_ordering_altered()
{
    NotifyReset();

    emit ordering_altered();
}

/*!
 * \brief QmlViewCollectionModel::IntLessThan
 * \param a
 * \param b
 * \return
 */
bool QmlViewCollectionModel::IntLessThan(int a, int b)
{
    return a < b;
}

/*!
 * \brief QmlViewCollectionModel::IntReverseLessThan
 * \param a
 * \param b
 * \return
 */
bool QmlViewCollectionModel::IntReverseLessThan(int a, int b)
{
    return b < a;
}
