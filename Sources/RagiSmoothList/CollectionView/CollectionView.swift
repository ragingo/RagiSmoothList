//
//  CollectionView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/17.
//

import UIKit
import SwiftUI

final class CollectionView<
    SectionType: Hashable,
    ItemType: Hashable,
    SectionHeader: View,
    SectionFooter: View,
    Cell: View
> {
    typealias SupplementaryViewProvider = UICollectionViewDiffableDataSource<SectionType, ItemType>.SupplementaryViewProvider
    typealias SwipeActionProvider = UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider

    private(set) var dataSource: DataSource<SectionType, ItemType>
    private let sectionHeaderContent: (SectionType, [ItemType]) -> SectionHeader
    private let sectionFooterContent: (SectionType, [ItemType]) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    private let onRefresh: () -> Void

    private let uiCollectionView: UICollectionView
    private let sectionHeaderID = UUID().uuidString
    private let sectionFooterID = UUID().uuidString
    private var layoutListConfiguration: UICollectionLayoutListConfiguration

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
        self.onRefresh = onRefresh

        let layoutListConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        self.layoutListConfiguration = layoutListConfiguration

        let cellID = UUID().uuidString
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: Self.createLayout(layoutListConfiguration: layoutListConfiguration)
        )

        uiCollectionView = collectionView
        uiCollectionView.register(InnerListCell<Cell>.self, forCellWithReuseIdentifier: cellID)
        uiCollectionView.register(InnerListSection<SectionHeader>.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionHeaderID)
        uiCollectionView.register(InnerListSection<SectionFooter>.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: sectionFooterID)

        self.dataSource = DataSource(
            collectionView: uiCollectionView,
            cellProvider: { collectionView, indexPath, item -> UICollectionViewCell? in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? InnerListCell<Cell> else {
                    return nil
                }

                let isLastSection = collectionView.numberOfSections == indexPath.section + 1
                let isLastItem = collectionView.numberOfItems(inSection: indexPath.section) == indexPath.row + 1
                if isLastSection && isLastItem {
                    onLoadMore()
                }

                let content = cellContent(item)
                cell.configure(content: content)
                return cell}
        )

        self.dataSource.supplementaryViewProvider = supplementaryViewProvider()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefreshControlValueChanged(sender:)), for: .valueChanged)
        uiCollectionView.refreshControl = refreshControl

        onInitialized(uiCollectionView)
    }

    private static func createLayout(layoutListConfiguration: UICollectionLayoutListConfiguration) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            return NSCollectionLayoutSection.list(using: layoutListConfiguration, layoutEnvironment: layoutEnvironment)
        }
        return layout
    }

    func updateLayout(listConfiguration: RagiSmoothListConfiguration?) {
        Self.configureStyles(listConfiguration: listConfiguration, layoutListConfiguration: &layoutListConfiguration)
        uiCollectionView.collectionViewLayout = Self.createLayout(layoutListConfiguration: layoutListConfiguration)
    }

    public enum SwipeStartEdge {
        case leading
        case trailing
    }

    func swipeActions(edge: SwipeStartEdge, allowFullSwipe: Bool = true, actions: @escaping (IndexPath) -> [UIContextualAction]) {
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

    private static func configureStyles(listConfiguration: RagiSmoothListConfiguration?, layoutListConfiguration: inout UICollectionLayoutListConfiguration) {
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

    @objc private func onRefreshControlValueChanged(sender: UIRefreshControl) {
        onRefresh()
        sender.endRefreshing()
    }
}

// MARK: - Section Header/Footer
private extension CollectionView {
    func supplementaryViewProvider() -> SupplementaryViewProvider? {
        let provider: SupplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
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

    func makeSectionHeader(
        indexPath: IndexPath
    ) -> UICollectionReusableView? {
        let view = uiCollectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: sectionHeaderID,
            for: indexPath) as? InnerListSection<SectionHeader>

        guard let view else { return nil }

        let snapshot = dataSource.snapshot()
        let sectionData = snapshot.sectionIdentifiers[indexPath.section]
        let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
        let content = sectionHeaderContent(sectionData, itemsData)
        view.configure(content: content)

        return view
    }

    func makeSectionFooter(
        indexPath: IndexPath
    ) -> UICollectionReusableView? {
        let view = uiCollectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: sectionFooterID,
            for: indexPath) as? InnerListSection<SectionFooter>

        guard let view else { return nil }

        let snapshot = dataSource.snapshot()
        let sectionData = snapshot.sectionIdentifiers[indexPath.section]
        let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
        let content = sectionFooterContent(sectionData, itemsData)
        view.configure(content: content)

        return view
    }
}
