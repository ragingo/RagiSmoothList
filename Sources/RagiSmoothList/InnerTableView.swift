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
    Section: View,
    Cell: View
>: UIViewControllerRepresentable
{
    typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, RagiSmoothListSectionItemType<ItemType>>
    typealias ListDataType = [ListSectionModelType]
    typealias DiffDataType = [Changeset<ListSectionModelType>]
    typealias UIViewControllerType = UIViewController

    @Binding private var diffData: DiffDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionContent: (SectionType) -> Section
    private let cellContent: (ItemType) -> Cell
    @Binding private var needsRefresh: Bool
    private let onLoadMore: () -> Void
    private let onRefresh: () -> Void

    private let cellID = UUID().uuidString
    private let sectionID = UUID().uuidString
    @State private var innerViewController: UIViewControllerType?

    init(
        diffData: Binding<DiffDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionContent: @escaping (SectionType) -> Section,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        needsRefresh: Binding<Bool>,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self._diffData = diffData
        self.listConfiguration = listConfiguration
        self.sectionContent = sectionContent
        self.cellContent = cellContent
        self._needsRefresh = needsRefresh
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()

        let tableView = UITableView()
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.register(InnerTableViewSection<Section>.self, forHeaderFooterViewReuseIdentifier: sectionID)
        tableView.register(InnerTableViewCell<Cell>.self, forCellReuseIdentifier: cellID)
        configureTableView(tableView)
        viewController.view = tableView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(context.coordinator.onRefreshControlValueChanged(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl

        Task {
            innerViewController = viewController
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if needsRefresh, let uiTableView = uiViewController.view as? UITableView {
            diffData.forEach { changeset in
                if changeset.originalSections.isEmpty {
                    context.coordinator.data = changeset.finalSections
                    uiTableView.reloadData()
                    return
                }

                uiTableView.performBatchUpdates {
                    context.coordinator.data = changeset.finalSections

                    // RxDataSource モジュールを使ってないから tableView.batchUpdates() が使えない。
                    // 以下のリンク先の本家実装を参考に、最低限のコードで更新処理を実行
                    // https://github.com/RxSwiftCommunity/RxDataSources/blob/5.0.2/Sources/RxDataSources/UI+SectionedViewType.swift
                    uiTableView.deleteSections(.init(changeset.deletedSections), with: .automatic)
                    uiTableView.insertSections(.init(changeset.insertedSections), with: .automatic)
                    changeset.movedSections.forEach {
                        uiTableView.moveSection($0.from, toSection: $0.to)
                    }
                    uiTableView.deleteRows(at: .init(changeset.deletedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }), with: .automatic)
                    uiTableView.insertRows(at: .init(changeset.insertedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }), with: .automatic)
                    uiTableView.reloadRows(at: .init(changeset.updatedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }), with: .automatic)
                    changeset.movedItems.forEach {
                        uiTableView.moveRow(at: IndexPath(row: $0.from.itemIndex, section: $0.from.sectionIndex), to: IndexPath(row: $0.to.itemIndex, section: $0.to.sectionIndex))
                    }
                }
            }

            Task {
                needsRefresh = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
        private let parent: InnerTableView
        fileprivate var data: ListDataType = []

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
            cell.set(content: content, parentController: parent.innerViewController)
            cell.selectionStyle = .none

            return cell
        }

        // MARK: - UITableViewDelegate
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: parent.sectionID) as? InnerTableViewSection<Section> else {
                return nil
            }

            let sectionData = data[section]
            let content = parent.sectionContent(sectionData.model)
            headerView.set(content: content, parentController: parent.innerViewController)

            return headerView
        }

        func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            let sectionData = data[section]
            let content = parent.sectionContent(sectionData.model)
            return content is EmptyView ? .leastNormalMagnitude : -1
        }
    }

    private func configureTableView(_ tableView: UITableView) {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        guard let listConfiguration else { return }

        tableView.separatorStyle = listConfiguration.hasSeparator ? .singleLine : .none

        if let separatorColor = listConfiguration.separatorColor {
            tableView.separatorColor = UIColor(separatorColor)
        }
        if let separatorInsets = listConfiguration.separatorInsets {
            tableView.separatorInset = UIEdgeInsets(top: separatorInsets.top, left: separatorInsets.leading, bottom: separatorInsets.bottom, right: separatorInsets.trailing)
        }
    }
}
