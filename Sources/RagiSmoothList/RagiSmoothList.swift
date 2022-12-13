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
    SectionHeader: View,
    SectionFooter: View,
    Cell: View
>: View
{
    public typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, RagiSmoothListSectionItemType<ItemType>>
    public typealias ListDataType = [ListSectionModelType]
    public typealias DiffDataType = [Changeset<ListSectionModelType>]

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionHeaderContent: (SectionType) -> SectionHeader
    private let sectionFooterContent: (SectionType) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    private let onLoadMore: (() -> Void)?
    private let onRefresh: (() -> Void)?
    private let onDeleted: ((ItemType) -> Void)?

    @State private var needsRefresh = false
    @State private var diffData: DiffDataType = []

    private var needsScrollToTop: Binding<Bool>

    public init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionHeaderContent: @escaping (SectionType) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        onDeleted: ((ItemType) -> Void)? = nil
    ) {
        self._data = data
        self.listConfiguration = listConfiguration
        self.sectionHeaderContent = sectionHeaderContent
        self.sectionFooterContent = sectionFooterContent
        self.cellContent = cellContent
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
        self.onDeleted = onDeleted

        self.needsScrollToTop = .constant(false)
    }

    public var body: some View {
        InnerTableView(
            diffData: $diffData,
            listConfiguration: listConfiguration,
            sectionHeaderContent: sectionHeaderContent,
            sectionFooterContent: sectionFooterContent,
            cellContent: cellContent,
            needsRefresh: $needsRefresh,
            onLoadMore: {
                onLoadMore?()
            },
            onRefresh: {
                onRefresh?()
            },
            onDelete: { section, row, item in
                onDeleted?(item)
            },
            needsScrollToTop: needsScrollToTop
        )
        .onAppear {
            updateDiff(oldData: [], newData: data)
        }
        .onChange(of: data) { [oldData = data] newData in
            updateDiff(oldData: oldData, newData: newData)
        }
    }

    public func scrollToTop(_ request: Binding<Bool>) -> Self {
        var newInstance = self
        newInstance.needsScrollToTop = request
        return newInstance
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
    ) where SectionHeader == EmptyView, SectionFooter == EmptyView {
        self.init(
            data: data,
            listConfiguration: listConfiguration,
            sectionHeaderContent: { _ in EmptyView() },
            sectionFooterContent: { _ in EmptyView() },
            cellContent: cellContent,
            onLoadMore: onLoadMore,
            onRefresh: onRefresh
        )
    }
}
