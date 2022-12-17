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

    private let cellID = UUID().uuidString
    private let sectionHeaderID = UUID().uuidString
    private let sectionFooterID = UUID().uuidString

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

        let collectionView = makeCollectionView()
        viewController.view = collectionView

        context.coordinator.collectionView = collectionView
        let dataSource: DataSource<SectionType, ItemType, Cell> = DataSource(
            collectionView: collectionView,
            cellContent: cellContent,
            cellProvider: { collectionView, indexPath, item -> UICollectionViewCell? in
                guard let dataSource = context.coordinator.dataSource else {
                    return nil
                }

                let snapshot = dataSource.snapshot()
                let section = snapshot.sectionIdentifiers[indexPath.section]
                let lastSection = snapshot.sectionIdentifiers.last
                if lastSection == section {
                    let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
                    let lastItem = snapshot.itemIdentifiers(inSection: section).last
                    if lastItem == item {
                        self.onLoadMore()
                    }
                }

                return makeCell(collectionView, cellID: cellID, indexPath: indexPath, cellContent: cellContent, item: item)
            })
        context.coordinator.dataSource = dataSource

        dataSource.supplementaryViewProvider = supplementaryViewProvider(dataSource: dataSource)

        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configureCollectionViewStyles(&configuration)
            configuration.trailingSwipeActionsConfigurationProvider = trailingSwipeActionsConfigurationProvider(dataSource: dataSource)

            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }

        collectionView.collectionViewLayout = layout

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.onRefreshControlValueChanged(sender:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if needsRefresh {
            if let dataSource = context.coordinator.dataSource {
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
            collectionView.setContentOffset(.zero, animated: true)
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
        fileprivate var dataSource: DataSource<SectionType, ItemType, Cell>?
        fileprivate var collectionView: UICollectionView?

        init(parent: InnerList) {
            self.parent = parent
        }

        @objc func onRefreshControlValueChanged(sender: UIRefreshControl) {
            parent.onRefresh()
            sender.endRefreshing()
        }
    }

    private func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
        collectionView.register(InnerListCell<Cell>.self, forCellWithReuseIdentifier: cellID)
        collectionView.register(InnerListSection<SectionHeader>.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionHeaderID)
        collectionView.register(InnerListSection<SectionFooter>.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: sectionFooterID)
        return collectionView
    }

    private func configureCollectionViewStyles(_ configuration: inout UICollectionLayoutListConfiguration) {
        configuration.headerMode = SectionHeader.self is EmptyView.Type ? .none : .supplementary
        configuration.footerMode = SectionFooter.self is EmptyView.Type ? .none : .supplementary

        if #available(iOS 15.0, *) {
            configuration.headerTopPadding = 0
        }

        guard let listConfiguration else { return }

        configuration.showsSeparators = listConfiguration.separator.isVisible

        if let separatorColor = listConfiguration.separator.color {
            if #available(iOS 14.5, *) {
                configuration.separatorConfiguration.color = UIColor(separatorColor)
            }
        }

        if let separatorInsets = listConfiguration.separator.insets {
            if #available(iOS 14.5, *) {
                let insets = NSDirectionalEdgeInsets(
                    top: separatorInsets.top,
                    leading: separatorInsets.leading,
                    bottom: separatorInsets.bottom,
                    trailing: separatorInsets.trailing
                )
                configuration.separatorConfiguration.topSeparatorInsets = insets
                configuration.separatorConfiguration.bottomSeparatorInsets = insets
            }
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

// MARK: - SupplementaryViewProvider
extension InnerList {
    typealias SupplementaryViewProvider = UICollectionViewDiffableDataSource<SectionType, ItemType>.SupplementaryViewProvider

    func supplementaryViewProvider(dataSource: DataSource<SectionType, ItemType, Cell>) -> SupplementaryViewProvider? {
        let provider: SupplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return makeSectionHeader(collectionView, indexPath: indexPath, dataSource: dataSource)
            case UICollectionView.elementKindSectionFooter:
                return makeSectionFooter(collectionView, indexPath: indexPath, dataSource: dataSource)
            default:
                return nil
            }
        }
        return provider
    }

    private func dequeueSectionHeader(_ collectionView: UICollectionView, indexPath: IndexPath) -> InnerListSection<SectionHeader>? {
        return collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: sectionHeaderID,
            for: indexPath
        ) as? InnerListSection<SectionHeader>
    }

    private func dequeueSectionFooter(_ collectionView: UICollectionView, indexPath: IndexPath) -> InnerListSection<SectionFooter>? {
        return collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: sectionFooterID,
            for: indexPath
        ) as? InnerListSection<SectionFooter>
    }

    private func makeSectionHeader(
        _ collectionView: UICollectionView,
        indexPath: IndexPath,
        dataSource: DataSource<SectionType, ItemType, Cell>
    ) -> UICollectionReusableView? {
        guard let view = dequeueSectionHeader(collectionView, indexPath: indexPath) else { return nil }
        let snapshot = dataSource.snapshot()
        let sectionData = snapshot.sectionIdentifiers[indexPath.section]
        let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
        let content = sectionHeaderContent(sectionData, itemsData)
        view.configure(content: content)
        return view
    }

    private func makeSectionFooter(
        _ collectionView: UICollectionView,
        indexPath: IndexPath,
        dataSource: DataSource<SectionType, ItemType, Cell>
    ) -> UICollectionReusableView? {
        guard let view = dequeueSectionFooter(collectionView, indexPath: indexPath) else { return nil }
        let snapshot = dataSource.snapshot()
        let sectionData = snapshot.sectionIdentifiers[indexPath.section]
        let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
        let content = sectionFooterContent(sectionData, itemsData)
        view.configure(content: content)
        return view
    }
}

final class DataSource<
    SectionType: Hashable,
    ItemType: Hashable,
    Cell
>: UICollectionViewDiffableDataSource<SectionType, ItemType> {
    private let cellContent: (ItemType) -> Cell

    init(
        collectionView: UICollectionView,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionType, ItemType>.CellProvider
    ) {
        self.cellContent = cellContent
        super.init(collectionView: collectionView, cellProvider: cellProvider)
    }
}

private func makeCell<Cell: View, Item: Hashable>(
    _ collectionView: UICollectionView,
    cellID: String,
    indexPath: IndexPath,
    @ViewBuilder cellContent: (Item) -> Cell,
    item: Item
) -> UICollectionViewCell? {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? InnerListCell<Cell> else {
        return nil
    }

    let content = cellContent(item)
    cell.configure(content: content)

    return cell
}
