//
//  RagiSmoothList.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import Differentiator
import SwiftUI

public struct RagiSmoothList<
    SectionType: Identifiable & Hashable,
    ItemType: Identifiable & Hashable,
    Section: View,
    Cell: View
>: View
{
    public typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, RagiSmoothListSectionItemType<ItemType>>
    public typealias ListDataType = [ListSectionModelType]
    public typealias DiffDataType = [Changeset<ListSectionModelType>]

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionContent: (SectionType) -> Section
    private let cellContent: (ItemType) -> Cell
    private let onLoadMore: (() -> Void)?
    private let onRefresh: (() -> Void)?
    private let onDeleting: ((ItemType) -> Void)?
    private let onDeleted: ((ItemType) -> Void)?

    @State private var needsRefresh = false
    @State private var diffData: DiffDataType = []

    public init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionContent: @escaping (SectionType) -> Section,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        onDeleting: ((ItemType) -> Void)? = nil,
        onDeleted: ((ItemType) -> Void)? = nil
    ) {
        self._data = data
        self.listConfiguration = listConfiguration
        self.sectionContent = sectionContent
        self.cellContent = cellContent
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
        self.onDeleting = onDeleting
        self.onDeleted = onDeleted
    }

    public var body: some View {
        InnerTableView(
            diffData: $diffData,
            listConfiguration: listConfiguration,
            sectionContent: sectionContent,
            cellContent: cellContent,
            needsRefresh: $needsRefresh,
            onLoadMore: {
                onLoadMore?()
            },
            onRefresh: {
                onRefresh?()
            },
            onDelete: { [oldData = data] section, row, item in
                onDeleting?(item)
                let removedItem = data[section].items.remove(at: row)
                assert(removedItem.value == item)
                onDeleted?(item)

                updateDiff(oldData: oldData, newData: data)
            }
        )
        .onAppear {
            updateDiff(oldData: [], newData: data)
        }
        .onChange(of: data) { [oldData = data] newData in
            updateDiff(oldData: oldData, newData: newData)
        }
    }

    private func updateDiff(oldData: ListDataType, newData: ListDataType) {
        // 参考の実装
        // https://github.com/RxSwiftCommunity/RxDataSources/blob/5.0.2/Sources/RxDataSources/RxTableViewSectionedAnimatedDataSource.swift#L97
        guard let diffData = try? Diff.differencesForSectionedView(
            initialSections: oldData,
            finalSections: newData
        ) else {
            return
        }

        self.diffData = diffData
        needsRefresh = true
    }
}

extension RagiSmoothList {
    public init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil
    ) where SectionType == RagiSmoothListEmptySection, Section == EmptyView {
        self.init(
            data: data,
            listConfiguration: listConfiguration,
            sectionContent: { _ in EmptyView() },
            cellContent: cellContent,
            onLoadMore: onLoadMore,
            onRefresh: onRefresh
        )
    }
}
