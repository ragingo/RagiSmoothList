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
>: UIViewControllerRepresentable
{
    typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, ItemType>
    typealias ListDataType = [ListSectionModelType]
    typealias UIViewControllerType = UIViewController
    typealias RowDeleteCallback = ((sectionIndex: Int, itemIndex: Int, section: SectionType, item: ItemType)) -> Void

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionHeaderContent: (SectionType, [ItemType]) -> SectionHeader
    private let sectionFooterContent: (SectionType, [ItemType]) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    @Binding private var needsRefresh: Bool
    @Binding private var needsScrollToTop: Bool
    private let onLoadMore: () -> Void
    private let onRefresh: () -> Void
    private let onRowDeleted: RowDeleteCallback

    init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionHeaderContent: @escaping (SectionType, [ItemType]) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType, [ItemType]) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        needsRefresh: Binding<Bool>,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onRowDeleted: @escaping RowDeleteCallback,
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
        self._needsScrollToTop = needsScrollToTop
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()

        let collectionView = CollectionView(
            sectionHeaderContent: sectionHeaderContent,
            sectionFooterContent: sectionFooterContent,
            cellContent: cellContent,
            listConfiguration: listConfiguration,
            onRefresh: onRefresh
        ) { uiCollectionView in
            viewController.view = uiCollectionView
        }

        context.coordinator.collectionView = collectionView

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if needsRefresh {
            if let dataSource = context.coordinator.collectionView?.dataSource {
                var newSnapshot = NSDiffableDataSourceSnapshot<SectionType, ItemType>()
                newSnapshot.appendSections(data.map { $0.section })

                data.forEach { section in
                    newSnapshot.appendItems(section.items, toSection: section.section)
                }

                let isInitialApply = dataSource.snapshot().sectionIdentifiers.isEmpty
                dataSource.apply(newSnapshot, animatingDifferences: !isInitialApply)
            }
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

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    final class Coordinator: NSObject {
        private let parent: InnerList
        fileprivate var collectionView: CollectionView<SectionType, ItemType, SectionHeader, SectionFooter, Cell>?

        init(parent: InnerList) {
            self.parent = parent
        }
    }

    private func trailingSwipeActionsConfigurationProvider(dataSource: DataSource<SectionType, ItemType, Cell>) -> UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? {
        let provider: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider = { indexPath -> UISwipeActionsConfiguration? in
            let snapshot = dataSource.snapshot()
            let sectionData = snapshot.sectionIdentifiers[indexPath.section]
            let item = snapshot.itemIdentifiers(inSection: sectionData)[indexPath.row]

            var actions: [UIContextualAction] = []

            if let editableItem = item as? RagiSmoothListCellEditable, editableItem.canEdit {
                let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, handler) in
                    onRowDeleted((
                        sectionIndex: indexPath.section,
                        itemIndex: indexPath.row,
                        section: sectionData,
                        item: item
                    ))
                    handler(true)
                }

                if let backgroundColor = listConfiguration?.edit.deleteButtonBackgroundColor {
                    deleteAction.backgroundColor = UIColor(backgroundColor)
                }
                deleteAction.image = listConfiguration?.edit.deleteButtonImage

                actions.append(deleteAction)
            }

            return UISwipeActionsConfiguration(actions: actions)
        }

        return provider
    }
}
