//
//  RagiSmoothListConfiguration.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/11.
//

import SwiftUI

public struct RagiSmoothListConfiguration {
    // MARK: - Separator
    public var hasSeparator: Bool = true
    public var separatorInsets: EdgeInsets?
    public var separatorColor: Color?

    // MARK: - Edit
    public var canRowDelete: Bool = false

    // MARK: - Animation
    public var insertSectionAnimation: UITableView.RowAnimation = .automatic
    public var deleteSectionAnimation: UITableView.RowAnimation = .automatic
    public var insertRowsAnimation: UITableView.RowAnimation = .automatic
    public var deleteRowsAnimation: UITableView.RowAnimation = .automatic
    public var moveRowsAnimation: UITableView.RowAnimation = .automatic
    public var updateRowsAnimation: UITableView.RowAnimation = .automatic

    public init(
        hasSeparator: Bool = true,
        separatorInsets: EdgeInsets? = nil,
        separatorColor: Color? = nil,
        canRowDelete: Bool = false,
        insertSectionAnimation: UITableView.RowAnimation = .automatic,
        deleteSectionAnimation: UITableView.RowAnimation = .automatic,
        insertRowsAnimation: UITableView.RowAnimation = .automatic,
        deleteRowsAnimation: UITableView.RowAnimation = .automatic,
        moveRowsAnimation: UITableView.RowAnimation = .automatic,
        updateRowsAnimation: UITableView.RowAnimation = .automatic
    ) {
        self.hasSeparator = hasSeparator
        self.separatorInsets = separatorInsets
        self.separatorColor = separatorColor
        self.canRowDelete = canRowDelete
        self.insertSectionAnimation = insertSectionAnimation
        self.deleteSectionAnimation = deleteSectionAnimation
        self.insertRowsAnimation = insertRowsAnimation
        self.deleteRowsAnimation = deleteRowsAnimation
        self.moveRowsAnimation = moveRowsAnimation
        self.updateRowsAnimation = updateRowsAnimation
    }
}
