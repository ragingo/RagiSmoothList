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
    public typealias ListSectionModelType = ListSectionModel<SectionType, ListSectionItemType<ItemType>>
    public typealias ListDataType = [ListSectionModelType]
    public typealias DiffDataType = [Changeset<ListSectionModelType>]

    @Binding private var data: ListDataType
    private let listConfiguration: RagiSmoothListConfiguration?
    private let sectionContent: (SectionType) -> Section
    private let cellContent: (ItemType) -> Cell
    private let onLoadMore: (() -> Void)?
    private let onRefresh: (() -> Void)?

    @State private var needsRefresh = false
    @State private var diffData: DiffDataType = []

    public init(
        data: Binding<ListDataType>,
        listConfiguration: RagiSmoothListConfiguration? = nil,
        @ViewBuilder sectionContent: @escaping (SectionType) -> Section,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        onLoadMore: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil
    ) {
        self._data = data
        self.listConfiguration = listConfiguration
        self.sectionContent = sectionContent
        self.cellContent = cellContent
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
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
            }
        )
        .onAppear {
            let diffData = try? Diff.differencesForSectionedView(
                initialSections: [],
                finalSections: data
            )
            self.diffData = diffData ?? []
            needsRefresh = true
        }
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

public struct RagiSmoothListConfiguration {
    public var hasSeparator: Bool = true
    public var separatorInsets: EdgeInsets?
    public var separatorColor: Color?

    public init(hasSeparator: Bool = true, separatorInsets: EdgeInsets? = nil, separatorColor: Color? = nil) {
        self.hasSeparator = hasSeparator
        self.separatorInsets = separatorInsets
        self.separatorColor = separatorColor
    }
}

public struct RagiSmoothListEmptySection: Hashable, Identifiable {
    public let id = 0
    public init() {}
}
