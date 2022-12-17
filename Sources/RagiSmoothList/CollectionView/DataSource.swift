//
//  DataSource.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/17.
//

import UIKit
import SwiftUI

final class DataSource<
    SectionType: Hashable,
    ItemType: Hashable,
    Cell: View
>: UICollectionViewDiffableDataSource<SectionType, ItemType> {
    private let cellContent: (ItemType) -> Cell

    init(
        collectionView: UICollectionView,
        @ViewBuilder cellContent: @escaping (ItemType) -> Cell,
        cellProvider: @escaping UICollectionViewDiffableDataSource<SectionType, ItemType>.CellProvider
    ) {
        self.cellContent = cellContent
        super.init(collectionView: collectionView, cellProvider: cellProvider)
    }
}
