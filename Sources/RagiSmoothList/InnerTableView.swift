//
//  InnerTableView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import Differentiator
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
    typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, RagiSmoothListSectionItemType<ItemType>>
    typealias ListDataType = [ListSectionModelType]
    typealias DiffDataType = [Changeset<ListSectionModelType>]
    typealias UIViewControllerType = UIViewController
    typealias DeleteCallback = ((section: Int, row: Int, item: ItemType)) -> Void

    @Binding private var diffData: DiffDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionHeaderContent: (SectionType) -> SectionHeader
    private let sectionFooterContent: (SectionType) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    @Binding private var needsRefresh: Bool
    @Binding private var needsScrollToTop: Bool
    private let onLoadMore: () -> Void
    private let onRefresh: () -> Void
    private let onDelete: DeleteCallback

    private let cellID = UUID().uuidString
    private let sectionHeaderID = UUID().uuidString
    private let sectionFooterID = UUID().uuidString

    init(
        diffData: Binding<DiffDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionHeaderContent: @escaping (SectionType) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        needsRefresh: Binding<Bool>,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onDelete: @escaping DeleteCallback,
        needsScrollToTop: Binding<Bool>
    ) {
        self._diffData = diffData
        self.listConfiguration = listConfiguration
        self.sectionHeaderContent = sectionHeaderContent
        self.sectionFooterContent = sectionFooterContent
        self.cellContent = cellContent
        self._needsRefresh = needsRefresh
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
        self.onDelete = onDelete
        self._needsScrollToTop = needsScrollToTop
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()

        let tableView = UITableView()
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.register(InnerTableViewSection<SectionHeader>.self, forHeaderFooterViewReuseIdentifier: sectionHeaderID)
        tableView.register(InnerTableViewSection<SectionFooter>.self, forHeaderFooterViewReuseIdentifier: sectionFooterID)
        tableView.register(InnerTableViewCell<Cell>.self, forCellReuseIdentifier: cellID)
        configureTableView(tableView)
        viewController.view = tableView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.onRefreshControlValueChanged(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if context.coordinator.viewController != uiViewController {
            context.coordinator.viewController = uiViewController
        }

        if needsRefresh {
            updateDataSource(diffData: diffData, context: context)
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

    final class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
        private let parent: InnerTableView
        fileprivate var data: ListDataType = []
        fileprivate var viewController: UIViewControllerType?
        var tableView: UITableView? {
            viewController?.view as? UITableView
        }

        init(parent: InnerTableView) {
            self.parent = parent
        }

        @objc func onRefreshControlValueChanged(sender: UIRefreshControl) {
            parent.onRefresh()
            sender.endRefreshing()
        }

        // MARK: - UITableViewDataSource
        func numberOfSections(in tableView: UITableView) -> Int {
            return data.count
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return data[section].items.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            defer {
                let isLastSection = data.last == data[indexPath.section]
                let isLastItem = data[indexPath.section].items.last == data[indexPath.section].items[indexPath.row]
                if isLastSection && isLastItem {
                    parent.onLoadMore()
                }
            }

            guard let cell = tableView.dequeueReusableCell(withIdentifier: parent.cellID) as? InnerTableViewCell<Cell> else {
                return UITableViewCell()
            }

            let element = data[indexPath.section].items[indexPath.row]
            let content = parent.cellContent(element.value)
            cell.configure(content: content)
            cell.selectionStyle = .none

            return cell
        }

        // MARK: - UITableViewDelegate
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: parent.sectionHeaderID) as? InnerTableViewSection<SectionHeader> else {
                return nil
            }

            let sectionData = data[section]
            let content = parent.sectionHeaderContent(sectionData.model)
            headerView.configure(content: content)

            return headerView
        }

        func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: parent.sectionFooterID) as? InnerTableViewSection<SectionFooter> else {
                return nil
            }

            let sectionData = data[section]
            let content = parent.sectionFooterContent(sectionData.model)
            footerView.configure(content: content)

            return footerView
        }

        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            let sectionData = data[section]
            let content = parent.sectionHeaderContent(sectionData.model)
            return content is EmptyView ? .leastNormalMagnitude : UITableView.automaticDimension
        }

        func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            let sectionData = data[section]
            let content = parent.sectionFooterContent(sectionData.model)
            return content is EmptyView ? .leastNormalMagnitude : UITableView.automaticDimension
        }

        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return parent.listConfiguration?.edit.canRowDelete == true
        }

        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, handler) in
                guard let self = self else {
                    handler(false)
                    return
                }
                self.parent.onDelete((
                    section: indexPath.section,
                    row: indexPath.row,
                    item: self.data[indexPath.section].items[indexPath.row].value
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

    private func updateDataSource(diffData: DiffDataType, context: Context) {
        guard let tableView = context.coordinator.tableView else {
            return
        }

        diffData.forEach { changeset in
            if context.coordinator.data.isEmpty {
                context.coordinator.data = changeset.finalSections
                tableView.reloadData()
                return
            }

            tableView.performBatchUpdates {
                context.coordinator.data = changeset.finalSections

                let animation = listConfiguration?.animation

                // RxDataSource モジュールを使ってないから tableView.batchUpdates() が使えない。
                // 以下のリンク先の本家実装を参考に、最低限のコードで更新処理を実行
                // https://github.com/RxSwiftCommunity/RxDataSources/blob/5.0.2/Sources/RxDataSources/UI+SectionedViewType.swift
                tableView.deleteSections(.init(changeset.deletedSections), with: animation?.deleteSection.uiTableViewRowAnimation ?? .automatic)
                tableView.insertSections(.init(changeset.insertedSections), with: animation?.insertSection.uiTableViewRowAnimation ?? .automatic)
                changeset.movedSections.forEach {
                    tableView.moveSection($0.from, toSection: $0.to)
                }
                tableView.deleteRows(at: .init(changeset.deletedItems.map { $0.indexPath() }), with: animation?.deleteRows.uiTableViewRowAnimation ?? .automatic)
                tableView.insertRows(at: .init(changeset.insertedItems.map { $0.indexPath() }), with: animation?.insertSection.uiTableViewRowAnimation ?? .automatic)
                tableView.reloadRows(at: .init(changeset.updatedItems.map { $0.indexPath() }), with: animation?.updateRows.uiTableViewRowAnimation ?? .automatic)
                changeset.movedItems.forEach {
                    tableView.moveRow(at: $0.from.indexPath(), to: $0.to.indexPath())
                }
            }
        }
    }
}

private extension ItemPath {
    func indexPath() -> IndexPath {
        IndexPath(row: itemIndex, section: sectionIndex)
    }
}
