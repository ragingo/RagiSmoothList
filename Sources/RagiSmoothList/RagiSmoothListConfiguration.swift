//
//  RagiSmoothListConfiguration.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/11.
//

import SwiftUI

public struct RagiSmoothListConfiguration {
    public var hasSeparator: Bool = true
    public var separatorInsets: EdgeInsets?
    public var separatorColor: Color?
    public var canRowDelete: Bool = false

    public init(
        hasSeparator: Bool = true,
        separatorInsets: EdgeInsets? = nil,
        separatorColor: Color? = nil,
        canRowDelete: Bool = false
    ) {
        self.hasSeparator = hasSeparator
        self.separatorInsets = separatorInsets
        self.separatorColor = separatorColor
        self.canRowDelete = canRowDelete
    }
}
