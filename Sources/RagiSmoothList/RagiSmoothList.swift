//
//  RagiSmoothList.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI

public struct RagiSmoothList<
    SectionType: Identifiable & Hashable,
    ItemType: Identifiable & Hashable,
    SectionHeader: View,
    SectionFooter: View,
    Cell: View
>: View
{
    public typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, ItemType>
    public typealias ListDataType = [ListSectionModelType]

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionHeaderContent: (SectionType, [ItemType]) -> SectionHeader
    private let sectionFooterContent: (SectionType, [ItemType]) -> SectionFooter
    private let cellContent: (ItemType) -> Cell
    private let onLoadMore: (() -> Void)?
    private let onRefresh: (() -> Void)?
    private let onDeleted: (((sectionIndex: Int, itemIndex: Int, section: SectionType, item: ItemType)) -> Void)?

    @State private var needsRefresh = false

    private var needsScrollToTop: Binding<Bool>

    public init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionHeaderContent: @escaping (SectionType, [ItemType]) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType, [ItemType]) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        onDeleted: (((sectionIndex: Int, itemIndex: Int, section: SectionType, item: ItemType)) -> Void)? = nil
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
            data: $data,
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
            onDelete: { sectionIndex, itemIndex, section, item in
                onDeleted?((sectionIndex: sectionIndex, itemIndex: itemIndex, section: section, item: item))
            },
            needsScrollToTop: needsScrollToTop
        )
        .onAppear {
            needsRefresh = true
        }
        .onChange(of: data) { _ in
            needsRefresh = true
        }
    }

    public func scrollToTop(_ request: Binding<Bool>) -> Self {
        var newInstance = self
        newInstance.needsScrollToTop = request
        return newInstance
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
            sectionHeaderContent: { _, _ in EmptyView() },
            sectionFooterContent: { _, _ in EmptyView() },
            cellContent: cellContent,
            onLoadMore: onLoadMore,
            onRefresh: onRefresh
        )
    }
}
