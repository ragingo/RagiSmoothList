//
//  InnerList.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI
import UIKit

struct InnerList<
    SectionType: Identifiable & Hashable,
    ItemType: Identifiable & Hashable,
    SectionHeader: View,
    SectionFooter: View,
    Cell: View
>: UIViewControllerRepresentable {
    typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, ItemType>
    typealias ListDataType = [ListSectionModelType]
    typealias UIViewControllerType = UIViewController
    typealias RowDeletedCallback = ((sectionIndex: Int, itemIndex: Int, section: SectionType, item: ItemType)) -> Void
    typealias CollectionViewType = CollectionView<SectionType, ItemType, SectionHeader, SectionFooter, Cell>

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionHeaderContent: (SectionType, [ItemType]) -> SectionHeader
    private let sectionFooterContent: (SectionType, [ItemType]) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    @Binding private var needsRefresh: Bool
    @Binding private var needsScrollToTop: Bool
    private let onLoadMore: () -> Void
    private let onRefresh: () -> Void
    private let onRowDeleted: RowDeletedCallback
    private var searchable: Binding<String>?

    init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionHeaderContent: @escaping (SectionType, [ItemType]) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType, [ItemType]) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        needsRefresh: Binding<Bool>,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onRowDeleted: @escaping RowDeletedCallback,
        searchable: Binding<String>?,
        needsScrollToTop: Binding<Bool>
    ) {
        self._data = data
        self.listConfiguration = listConfiguration
        self.sectionHeaderContent = sectionHeaderContent
        self.sectionFooterContent = sectionFooterContent
        self.cellContent = cellContent
        self._needsRefresh = needsRefresh
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
        self.onRowDeleted = onRowDeleted
        self.searchable = searchable
        self._needsScrollToTop = needsScrollToTop
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()

        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        viewController.view.addSubview(searchBar)
        searchBar.heightAnchor.constraint(equalToConstant: 0).isActive = searchable == nil
        context.coordinator.searchBar = searchBar

        let collectionView = CollectionView(
            sectionHeaderContent: sectionHeaderContent,
            sectionFooterContent: sectionFooterContent,
            cellContent: cellContent,
            onLoadMore: onLoadMore,
            onRefresh: onRefresh
        ) { uiCollectionView in
            uiCollectionView.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(uiCollectionView)

            NSLayoutConstraint.activate([
                // searchBar
                viewController.view.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
                viewController.view.topAnchor.constraint(equalTo: searchBar.topAnchor),
                // collection view
                viewController.view.leadingAnchor.constraint(equalTo: uiCollectionView.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: uiCollectionView.trailingAnchor),
                searchBar.bottomAnchor.constraint(equalTo: uiCollectionView.topAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: uiCollectionView.bottomAnchor)
            ])
        }

        context.coordinator.collectionView = collectionView

        collectionView.updateLayout(listConfiguration: listConfiguration)
        collectionView.swipeActions(edge: .trailing) { indexPath in
            let snapshot = collectionView.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]

            var actions: [UIContextualAction] = []

            if let editableCell = item as? RagiSmoothListCellEditable, editableCell.canEdit {
                actions += [makeDeleteAction(indexPath: indexPath, section: section, item: item)]
            }

            return actions
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if needsRefresh, let collectionView = context.coordinator.collectionView {
            refreshData(collectionView)
            Task {
                needsRefresh = false
            }
        }

        if needsScrollToTop, let collectionView = context.coordinator.collectionView {
            collectionView.scrollToTop()
            Task {
                needsScrollToTop = false
            }
        }
    }

    private func refreshData(_ collectionView: CollectionViewType) {
        var newSnapshot = NSDiffableDataSourceSnapshot<SectionType, ItemType>()
        newSnapshot.appendSections(data.map { $0.section })

        data.forEach { section in
            newSnapshot.appendItems(section.items, toSection: section.section)
        }

        let isInitialApply = collectionView.dataSource.snapshot().sectionIdentifiers.isEmpty
        collectionView.dataSource.apply(newSnapshot, animatingDifferences: !isInitialApply)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        private let parent: InnerList
        fileprivate var collectionView: CollectionViewType?
        fileprivate var searchBar: UISearchBar?

        init(parent: InnerList) {
            self.parent = parent
        }

        // MARK: - UISearchBarDelegate
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.searchable?.wrappedValue = searchText
        }
    }

    private func makeDeleteAction(
        style: UIContextualAction.Style = .destructive,
        title: String = "Delete",
        indexPath: IndexPath,
        section: SectionType,
        item: ItemType
    ) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: title) { _, _, handler in
            onRowDeleted((
                sectionIndex: indexPath.section,
                itemIndex: indexPath.row,
                section: section,
                item: item
            ))

            handler(true)
        }

        if let backgroundColor = listConfiguration?.edit.deleteButtonBackgroundColor {
            action.backgroundColor = UIColor(backgroundColor)
        }

        action.image = listConfiguration?.edit.deleteButtonImage

        return action
    }
}
