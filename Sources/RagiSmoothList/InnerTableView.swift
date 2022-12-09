//
//  InnerTableView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import Differentiator
import SwiftUI
import UIKit

final class InnerTableView<
    SectionType: Identifiable & Hashable,
    ItemType: Identifiable & Hashable,
    Cell: View
>: UIViewControllerRepresentable
{
    typealias TableSectionModelType = ListSectionModel<SectionType, ListSectionItemType<ItemType>>
    typealias TableDataType = [TableSectionModelType]
    typealias DiffDataType = [Changeset<TableSectionModelType>]
    typealias UIViewControllerType = UIViewController

    @Binding private var diffData: DiffDataType
    private let cellContent: (ItemType) -> Cell
    @Binding private var needsRefresh: Bool
    private let onLoadMore: () -> Void
    private let onRefresh: () -> Void

    private let cellID = UUID().uuidString
    private var innerViewController: UIViewControllerType?

    init(
        diffData: Binding<DiffDataType>,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        needsRefresh: Binding<Bool>,
        onLoadMore: @escaping () -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self._diffData = diffData
        self.cellContent = cellContent
        self._needsRefresh = needsRefresh
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()

        let tableView = UITableView()
        tableView.dataSource = context.coordinator
        tableView.register(InnerTableViewCell<Cell>.self, forCellReuseIdentifier: cellID)
        viewController.view = tableView

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefreshControlValueChanged(sender:)), for: .valueChanged)
        tableView.refreshControl = refreshControl

        innerViewController = viewController

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if needsRefresh, let uiTableView = uiViewController.view as? UITableView {
            diffData.forEach { changeset in
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

    final class Coordinator: NSObject, UITableViewDataSource {
        private let parent: InnerTableView
        fileprivate var data: TableDataType = []

        init(parent: InnerTableView) {
            self.parent = parent
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

            return cell
        }
    }

    @objc private func onRefreshControlValueChanged(sender: UIRefreshControl) {
        onRefresh()
        sender.endRefreshing()
    }
}
