//
//  CollectionView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/17.
//

import SwiftUI
import UIKit

final class CollectionViewHolder<
    SectionType: Hashable,
    ItemType: Hashable,
    SectionHeader: View,
    SectionFooter: View,
    Cell: View
> {
    // swiftlint:disable:next line_length
    typealias SupplementaryViewProvider = UICollectionViewDiffableDataSource<SectionType, ItemType>.SupplementaryViewProvider
    typealias SwipeActionProvider = UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider
    typealias DataSourceType = DataSource<SectionType, ItemType>

    private(set) lazy var dataSource: DataSourceType = createDataSource()
    private let sectionHeaderContent: (SectionType, [ItemType]) -> SectionHeader
    private let sectionFooterContent: (SectionType, [ItemType]) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    private let onLoadMore: () -> Void
    private let onRefresh: () -> Void

    private let uiCollectionView: CustomCollectionView<Cell, SectionHeader, SectionFooter>
    private var layoutListConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)

    init(
        @ViewBuilder sectionHeaderContent: @escaping (SectionType, [ItemType]) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType, [ItemType]) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onInitialized: @escaping (UICollectionView) -> Void
    ) {
        self.sectionHeaderContent = sectionHeaderContent
        self.sectionFooterContent = sectionFooterContent
        self.cellContent = cellContent
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh

        uiCollectionView = .init(onRefresh: onRefresh)

        self.dataSource.supplementaryViewProvider = supplementaryViewProvider()

        onInitialized(uiCollectionView)
    }

    private func createDataSource() -> DataSourceType {
        DataSource(
            collectionView: uiCollectionView,
            cellProvider: { [weak self] collectionView, indexPath, item -> UICollectionViewCell? in
                guard let self else { return nil }

                guard let cell = self.uiCollectionView.dequeueCell(for: indexPath) else {
                    return nil
                }

                let isLastSection = collectionView.numberOfSections == indexPath.section + 1
                let isLastItem = collectionView.numberOfItems(inSection: indexPath.section) == indexPath.row + 1
                if isLastSection && isLastItem {
                    self.onLoadMore()
                }

                let content = self.cellContent(item)
                cell.configure(content: content)
                return cell
            }
        )
    }

    private static func createLayout(
        layoutListConfiguration: UICollectionLayoutListConfiguration
    ) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
            return NSCollectionLayoutSection.list(using: layoutListConfiguration, layoutEnvironment: layoutEnvironment)
        }
        return layout
    }

    func updateLayout(listStyle: any RagiSmoothListStyle, listConfiguration: RagiSmoothListConfiguration?) {
        let appearance: UICollectionLayoutListConfiguration.Appearance
        switch listStyle {
        case is PlainListStyle:
            appearance = .plain
        case is GroupedListStyle:
            appearance = .grouped
        case is InsetListStyle:
            appearance = .insetGrouped // MEMO: UICollectionView に .inset は存在しない
        case is InsetGroupedListStyle:
            appearance = .insetGrouped
        case is SidebarListStyle:
            appearance = .sidebar
        case is DefaultListStyle:
            appearance = .plain
        default:
            appearance = .plain
        }
        self.layoutListConfiguration = UICollectionLayoutListConfiguration(appearance: appearance)

        let oldConfiguration = self.layoutListConfiguration
        // MEMO: もっといい方法あるかも？
        self.layoutListConfiguration.leadingSwipeActionsConfigurationProvider =
            oldConfiguration.leadingSwipeActionsConfigurationProvider
        self.layoutListConfiguration.trailingSwipeActionsConfigurationProvider =
            oldConfiguration.trailingSwipeActionsConfigurationProvider
        Self.configureStyles(listConfiguration: listConfiguration, layoutListConfiguration: &layoutListConfiguration)
        uiCollectionView.collectionViewLayout = Self.createLayout(layoutListConfiguration: layoutListConfiguration)
    }

    public enum SwipeStartEdge {
        case leading
        case trailing
    }

    func swipeActions(
        edge: SwipeStartEdge,
        allowFullSwipe: Bool = true,
        actions: @escaping (IndexPath) -> [UIContextualAction]
    ) {
        let provider: SwipeActionProvider = { indexPath -> UISwipeActionsConfiguration? in
            UISwipeActionsConfiguration(actions: actions(indexPath))
        }

        switch edge {
        case .leading:
            layoutListConfiguration.leadingSwipeActionsConfigurationProvider = provider

        case .trailing:
            layoutListConfiguration.trailingSwipeActionsConfigurationProvider = provider
        }

        let layout = Self.createLayout(layoutListConfiguration: layoutListConfiguration)
        uiCollectionView.collectionViewLayout = layout
    }

    func scrollToTop(animated: Bool = true) {
        uiCollectionView.setContentOffset(.zero, animated: animated)
    }

    private static func configureStyles(
        listConfiguration: RagiSmoothListConfiguration?,
        layoutListConfiguration: inout UICollectionLayoutListConfiguration
    ) {
        layoutListConfiguration.headerMode = SectionHeader.self is EmptyView.Type ? .none : .supplementary
        layoutListConfiguration.footerMode = SectionFooter.self is EmptyView.Type ? .none : .supplementary

        if #available(iOS 15.0, *) {
            layoutListConfiguration.headerTopPadding = 0
        }

        guard let listConfiguration else { return }

        layoutListConfiguration.showsSeparators = listConfiguration.separator.isVisible

        if let separatorColor = listConfiguration.separator.color {
            if #available(iOS 14.5, *) {
                layoutListConfiguration.separatorConfiguration.color = UIColor(separatorColor)
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
                layoutListConfiguration.separatorConfiguration.topSeparatorInsets = insets
                layoutListConfiguration.separatorConfiguration.bottomSeparatorInsets = insets
            }
        }
    }
}

// MARK: - Section Header/Footer
private extension CollectionViewHolder {
    func supplementaryViewProvider() -> SupplementaryViewProvider? {
        let provider: SupplementaryViewProvider = { [weak self] _, elementKind, indexPath in
            guard let self else { return nil }

            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return self.makeSectionHeader(indexPath: indexPath)
            case UICollectionView.elementKindSectionFooter:
                return self.makeSectionFooter(indexPath: indexPath)
            default:
                return nil
            }
        }
        return provider
    }

    func makeSectionHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        guard let view = uiCollectionView.dequeueSectionHeader(for: indexPath) else {
            return nil
        }

        let snapshot = dataSource.snapshot()
        let sectionData = snapshot.sectionIdentifiers[indexPath.section]
        let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
        let content = sectionHeaderContent(sectionData, itemsData)
        view.configure(content: content)

        return view
    }

    func makeSectionFooter(indexPath: IndexPath) -> UICollectionReusableView? {
        guard let view = uiCollectionView.dequeueSectionFooter(for: indexPath) else {
            return nil
        }

        let snapshot = dataSource.snapshot()
        let sectionData = snapshot.sectionIdentifiers[indexPath.section]
        let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
        let content = sectionFooterContent(sectionData, itemsData)
        view.configure(content: content)

        return view
    }
}
