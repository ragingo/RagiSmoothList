//
//  InnerTableView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI
import UIKit

struct InnerTableView<
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

        let tableView = UITableView()
        tableView.delegate = context.coordinator
        tableView.register(InnerTableViewSection<SectionHeader>.self, forHeaderFooterViewReuseIdentifier: sectionHeaderID)
        tableView.register(InnerTableViewSection<SectionFooter>.self, forHeaderFooterViewReuseIdentifier: sectionFooterID)
        tableView.register(InnerTableViewCell<Cell>.self, forCellReuseIdentifier: cellID)
        configureTableView(tableView)
        viewController.view = tableView

        context.coordinator.tableView = tableView
        context.coordinator.dataSource = DataSource(
            tableView: tableView,
            cellContent: cellContent,
            cellProvider: { tableView, indexPath, item -> UITableViewCell? in
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

                return makeCell(tableView, cellID: cellID, indexPath: indexPath, cellContent: cellContent, item: item)
            })
        if let animationMode = listConfiguration?.animation.mode {
            context.coordinator.dataSource?.defaultRowAnimation = animationMode.uiTableViewRowAnimation
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.onRefreshControlValueChanged(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if needsRefresh {
            if let dataSource = context.coordinator.dataSource {
                var snapshot = NSDiffableDataSourceSnapshot<SectionType, ItemType>()
                snapshot.appendSections(data.map { $0.section })

                data.forEach { section in
                    snapshot.appendItems(section.items, toSection: section.section)
                }
                let isInitialApply = dataSource.snapshot().sectionIdentifiers.isEmpty
                dataSource.apply(snapshot, animatingDifferences: !isInitialApply)
            }
            Task {
                needsRefresh = false
            }
        }

        if needsScrollToTop, let tableView = context.coordinator.tableView {
            tableView.setContentOffset(.zero, animated: true)
            Task {
                needsScrollToTop = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITableViewDelegate {
        private let parent: InnerTableView
        fileprivate var dataSource: DataSource<SectionType, ItemType, Cell>?
        fileprivate var tableView: UITableView?

        init(parent: InnerTableView) {
            self.parent = parent
        }

        @objc func onRefreshControlValueChanged(sender: UIRefreshControl) {
            parent.onRefresh()
            sender.endRefreshing()
        }

        // MARK: - UITableViewDelegate
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            guard let dataSource else { return nil }
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: parent.sectionHeaderID) as? InnerTableViewSection<SectionHeader> else {
                return nil
            }

            let snapshot = dataSource.snapshot()
            let sectionData = snapshot.sectionIdentifiers[section]
            let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
            let content = parent.sectionHeaderContent(sectionData, itemsData)
            headerView.configure(content: content)

            return headerView
        }

        func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            guard let dataSource else { return nil }
            guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: parent.sectionFooterID) as? InnerTableViewSection<SectionFooter> else {
                return nil
            }

            let snapshot = dataSource.snapshot()
            let sectionData = snapshot.sectionIdentifiers[section]
            let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
            let content = parent.sectionFooterContent(sectionData, itemsData)
            footerView.configure(content: content)

            return footerView
        }

        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            guard let dataSource else { return .leastNormalMagnitude }
            let snapshot = dataSource.snapshot()
            let sectionData = snapshot.sectionIdentifiers[section]
            let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
            let content = parent.sectionHeaderContent(sectionData, itemsData)

            return content is EmptyView ? .leastNormalMagnitude : UITableView.automaticDimension
        }

        func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            guard let dataSource else { return .leastNormalMagnitude }

            let snapshot = dataSource.snapshot()
            let sectionData = snapshot.sectionIdentifiers[section]
            let itemsData = snapshot.itemIdentifiers(inSection: sectionData)
            let content = parent.sectionFooterContent(sectionData, itemsData)

            return content is EmptyView ? .leastNormalMagnitude : UITableView.automaticDimension
        }

        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            guard let dataSource else { return nil }
            let snapshot = dataSource.snapshot()
            let sectionData = snapshot.sectionIdentifiers[indexPath.section]

            let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, handler) in
                guard let self else {
                    handler(false)
                    return
                }
                self.parent.onRowDeleted((
                    sectionIndex: indexPath.section,
                    itemIndex: indexPath.row,
                    section: sectionData,
                    item: snapshot.itemIdentifiers(inSection: sectionData)[indexPath.row]
                ))
                handler(true)
            }

            if let backgroundColor = parent.listConfiguration?.edit.deleteButtonBackgroundColor {
                action.backgroundColor = UIColor(backgroundColor)
            }
            action.image = parent.listConfiguration?.edit.deleteButtonImage

            return UISwipeActionsConfiguration(actions: [action])
        }
    }

    private func configureTableView(_ tableView: UITableView) {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        guard let listConfiguration else { return }

        tableView.separatorStyle = listConfiguration.separator.isVisible ? .singleLine : .none

        if let separatorColor = listConfiguration.separator.color {
            tableView.separatorColor = UIColor(separatorColor)
        }
        if let separatorInsets = listConfiguration.separator.insets {
            tableView.separatorInset = UIEdgeInsets(top: separatorInsets.top, left: separatorInsets.leading, bottom: separatorInsets.bottom, right: separatorInsets.trailing)
        }
    }
}

final class DataSource<
    SectionType: Hashable,
    ItemType: Hashable,
    Cell
>: UITableViewDiffableDataSource<SectionType, ItemType> {
    private let cellContent: (ItemType) -> Cell

    init(
        tableView: UITableView,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        cellProvider: @escaping UITableViewDiffableDataSource<SectionType, ItemType>.CellProvider
    ) {
        self.cellContent = cellContent
        super.init(tableView: tableView, cellProvider: cellProvider)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let snapshot = snapshot()
        let section = snapshot.sectionIdentifiers[indexPath.section]
        let item = snapshot.itemIdentifiers(inSection: section)[indexPath.row]
        if let editable = item as? RagiSmoothListCellEditable {
            return editable.canEdit
        }
        return false
    }
}

private func makeCell<Cell: View, Item: Hashable>(
    _ tableView: UITableView,
    cellID: String,
    indexPath: IndexPath,
    @ViewBuilder cellContent: (Item) -> Cell,
    item: Item
) -> UITableViewCell? {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? InnerTableViewCell<Cell> else {
        return nil
    }

    let content = cellContent(item)
    cell.configure(content: content)
    cell.selectionStyle = .none

    return cell
}
