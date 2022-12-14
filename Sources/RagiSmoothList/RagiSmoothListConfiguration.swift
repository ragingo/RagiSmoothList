//
//  RagiSmoothListConfiguration.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/11.
//

import SwiftUI

public struct RagiSmoothListConfiguration {
    public var separator: Separator
    public var edit: Edit
    public var animation: Animation

    public init(
        separator: Separator = .init(),
        edit: Edit = .init(),
        animation: Animation = .init()
    ) {
        self.separator = separator
        self.edit = edit
        self.animation = animation
    }
}

// MARK: - Separator
extension RagiSmoothListConfiguration {
    public struct Separator {
        public var isVisible: Bool
        public var insets: EdgeInsets?
        public var color: Color?

        public init(isVisible: Bool = true, insets: EdgeInsets? = nil, color: Color? = nil) {
            self.isVisible = isVisible
            self.insets = insets
            self.color = color
        }
    }
}

// MARK: - Edit
extension RagiSmoothListConfiguration {
    public struct Edit {
        public var canRowDelete: Bool
        public var deleteButtonBackgroundColor: Color?
        public var deleteButtonImage: UIImage?

        public init(
            canRowDelete: Bool = false,
            deleteButtonBackgroundColor: Color? = nil,
            deleteButtonImage: UIImage? = nil
        ) {
            self.canRowDelete = canRowDelete
            self.deleteButtonBackgroundColor = deleteButtonBackgroundColor
            self.deleteButtonImage = deleteButtonImage
        }
    }
}

// MARK: - Animation
extension RagiSmoothListConfiguration {
    public struct Animation {
        public var insertSection: UITableView.RowAnimation
        public var deleteSection: UITableView.RowAnimation
        public var insertRows: UITableView.RowAnimation
        public var deleteRows: UITableView.RowAnimation
        public var updateRows: UITableView.RowAnimation

        public init(
            insertSection: UITableView.RowAnimation = .automatic,
            deleteSection: UITableView.RowAnimation = .automatic,
            insertRows: UITableView.RowAnimation = .automatic,
            deleteRows: UITableView.RowAnimation = .automatic,
            updateRows: UITableView.RowAnimation = .automatic
        ) {
            self.insertSection = insertSection
            self.deleteSection = deleteSection
            self.insertRows = insertRows
            self.deleteRows = deleteRows
            self.updateRows = updateRows
        }
    }
}
