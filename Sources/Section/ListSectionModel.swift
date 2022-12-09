//
//  ListSectionModel.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/09.
//

import Foundation
import Differentiator

public typealias IdentifiableType = Differentiator.IdentifiableType

public struct ListSectionModel<Section: Identifiable & Hashable, ItemType: IdentifiableType & Hashable> {
    public var model: Section
    public var items: [Item]

    public init(model: Section, items: [ItemType]) {
        self.model = model
        self.items = items
    }
}

extension ListSectionModel: AnimatableSectionModelType {
    public typealias Item = ItemType
    public typealias Identity = Section.ID

    public var identity: Section.ID {
        return model.id
    }

    public init(original: ListSectionModel, items: [Item]) {
        self.model = original.model
        self.items = items
    }
}

extension ListSectionModel: Hashable {}
