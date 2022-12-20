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
>: View {
    public typealias ListSectionModelType = RagiSmoothListSectionModel<SectionType, ItemType>
    public typealias ListDataType = [ListSectionModelType]
    // swiftlint:disable:next line_length
    public typealias RowDeletedCallback = ((sectionIndex: Int, itemIndex: Int, section: SectionType, item: ItemType)) -> Void

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionHeaderContent: (SectionType, [ItemType]) -> SectionHeader
    private let sectionFooterContent: (SectionType, [ItemType]) -> SectionFooter
    private let cellContent: (ItemType) -> Cell

    @State private var needsRefresh = false

    private var needsScrollToTop: Binding<Bool>
    private var onLoadMore: (() -> Void)?
    private var onRefresh: (() -> Void)?
    private var onRowDeleted: RowDeletedCallback?
    private var searchable: (bindableText: Binding<String>?, placeholder: String)?

    public init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionHeaderContent: @escaping (SectionType, [ItemType]) -> SectionHeader,
        @ViewBuilder sectionFooterContent: @escaping (SectionType, [ItemType]) -> SectionFooter,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell
    ) {
        self._data = data
        self.listConfiguration = listConfiguration
        self.sectionHeaderContent = sectionHeaderContent
        self.sectionFooterContent = sectionFooterContent
        self.cellContent = cellContent

        self.needsScrollToTop = .constant(false)
    }

    public var body: some View {
        InnerList(
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
            onRowDeleted: { sectionIndex, itemIndex, section, item in
                onRowDeleted?((sectionIndex: sectionIndex, itemIndex: itemIndex, section: section, item: item))
            },
            searchable: searchable,
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

    // iOS 15 未満のサポートを切ったら、以下のページの方法で独自 View の refreshable 対応ができる
    // https://developer.apple.com/documentation/swiftui/refreshaction
    public func refreshable(_ action: @escaping () -> Void) -> Self {
        var newInstance = self
        newInstance.onRefresh = action
        return newInstance
    }

    public func onLoadMore(_ action: @escaping () -> Void) -> Self {
        var newInstance = self
        newInstance.onLoadMore = action
        return newInstance
    }

    public func onRowDeleted(_ action: @escaping RowDeletedCallback) -> Self {
        var newInstance = self
        newInstance.onRowDeleted = action
        return newInstance
    }

    public func searchable(text: Binding<String>, placeholder: String = "") -> Self {
        var newInstance = self
        newInstance.searchable = (bindableText: text, placeholder: placeholder)
        return newInstance
    }
}

public extension RagiSmoothList {
    init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell
    ) where SectionHeader == EmptyView, SectionFooter == EmptyView {
        self.init(
            data: data,
            listConfiguration: listConfiguration,
            sectionHeaderContent: { _, _ in EmptyView() },
            sectionFooterContent: { _, _ in EmptyView() },
            cellContent: cellContent
        )
    }
}
