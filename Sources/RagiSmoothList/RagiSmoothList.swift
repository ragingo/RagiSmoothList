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
    Cell: View
>: View
{
    public typealias ListSectionModelType = ListSectionModel<SectionType, ListSectionItemType<ItemType>>
    public typealias ListDataType = [ListSectionModelType]
    public typealias DiffDataType = [Changeset<ListSectionModelType>]

    @Binding private var data: ListDataType
    private let cellContent: (ItemType) -> Cell
    private let onLoadMore: (() -> Void)?
    private let onRefresh: (() -> Void)?

    @State private var needsRefresh = false
    @State private var diffData: DiffDataType = []

    public init(
        data: Binding<ListDataType>,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil
    ) {
        self._data = data
        self.cellContent = cellContent
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
    }

    public var body: some View {
        InnerTableView(
            diffData: $diffData,
            cellContent: cellContent,
            needsRefresh: $needsRefresh,
            onLoadMore: {
                onLoadMore?()
            },
            onRefresh: {
                onRefresh?()
            }
        )
        .onChange(of: data) { [oldData = data] newData in
            // 参考の実装
            // https://github.com/RxSwiftCommunity/RxDataSources/blob/5.0.2/Sources/RxDataSources/RxTableViewSectionedAnimatedDataSource.swift#L97
            let diffData = try? Diff.differencesForSectionedView(
                initialSections: oldData,
                finalSections: newData
            )
            self.diffData = diffData ?? []
            needsRefresh = true
        }
    }
}
