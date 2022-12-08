//
//  ListSectionType.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import Differentiator

public struct ListSectionType<T: Identifiable & Hashable>: IdentifiableType, Equatable {
    public typealias Identity = T
    public let value: T
    public var id: T.ID { value.id }
    public var identity: T { value }

    public init(value: T) {
        self.value = value
    }
}
