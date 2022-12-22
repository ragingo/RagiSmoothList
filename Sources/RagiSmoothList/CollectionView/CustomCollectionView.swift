//
//  CustomCollectionView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/22.
//

import SwiftUI
import UIKit

final class CustomCollectionView<
    Cell: View,
    SectionHeader: View,
    SectionFooter: View
>: UICollectionView {
    let cellID = UUID().uuidString
    let sectionHeaderID = UUID().uuidString
    let sectionFooterID = UUID().uuidString

    private let onRefresh: () -> Void

    init(onRefresh: @escaping () -> Void) {
        self.onRefresh = onRefresh
        super.init(frame: .zero, collectionViewLayout: .init())

        keyboardDismissMode = .onDragWithAccessory

        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onRefreshControlValueChanged(sender:)), for: .valueChanged)

        // cell, section header, section footer
        register(InnerListCell<Cell>.self, forCellWithReuseIdentifier: cellID)
        register(
            InnerListSection<SectionHeader>.self,
            forSupplementaryViewOfKind: Self.elementKindSectionHeader,
            withReuseIdentifier: sectionHeaderID
        )
        register(
            InnerListSection<SectionFooter>.self,
            forSupplementaryViewOfKind: Self.elementKindSectionFooter,
            withReuseIdentifier: sectionFooterID
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func dequeueCell(for indexPath: IndexPath) -> InnerListCell<Cell>? {
        dequeueReusableCell(
            withReuseIdentifier: cellID,
            for: indexPath
        ) as? InnerListCell<Cell>
    }

    func dequeueSectionHeader(for indexPath: IndexPath) -> InnerListSection<SectionHeader>? {
        dequeueReusableSupplementaryView(
            ofKind: Self.elementKindSectionHeader,
            withReuseIdentifier: sectionHeaderID,
            for: indexPath
        ) as? InnerListSection<SectionHeader>
    }

    func dequeueSectionFooter(for indexPath: IndexPath) -> InnerListSection<SectionFooter>? {
        dequeueReusableSupplementaryView(
            ofKind: Self.elementKindSectionFooter,
            withReuseIdentifier: sectionFooterID,
            for: indexPath
        ) as? InnerListSection<SectionFooter>
    }

    @objc
    private func onRefreshControlValueChanged(sender: UIRefreshControl) {
        onRefresh()
        sender.endRefreshing()
    }
}
