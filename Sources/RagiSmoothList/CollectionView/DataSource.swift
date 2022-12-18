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
    ItemType: Hashable
>: UICollectionViewDiffableDataSource<SectionType, ItemType> {
}
