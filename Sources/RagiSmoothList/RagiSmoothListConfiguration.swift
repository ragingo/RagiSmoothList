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
        public var deleteButtonBackgroundColor: Color?
        public var deleteButtonImage: UIImage?

        public init(
            deleteButtonBackgroundColor: Color? = nil,
            deleteButtonImage: UIImage? = nil
        ) {
            self.deleteButtonBackgroundColor = deleteButtonBackgroundColor
            self.deleteButtonImage = deleteButtonImage
        }
    }
}

// MARK: - Animation
extension RagiSmoothListConfiguration {
    public struct Animation {
        public enum Mode: String, CaseIterable {
            case fade
            case right
            case left
            case top
            case bottom
            case none
            case middle
            case automatic

            var uiTableViewRowAnimation: UITableView.RowAnimation {
                switch self {
                case .fade:
                    return .fade
                case .right:
                    return .right
                case .left:
                    return .left
                case .top:
                    return .top
                case .bottom:
                    return .bottom
                case .none:
                    return .none
                case .middle:
                    return .middle
                case .automatic:
                    return .automatic
                }
            }
        }

        public var insertSection: Mode
        public var deleteSection: Mode
        public var insertRows: Mode
        public var deleteRows: Mode
        public var updateRows: Mode

        public init(
            insertSection: Mode = .automatic,
            deleteSection: Mode = .automatic,
            insertRows: Mode = .automatic,
            deleteRows: Mode = .automatic,
            updateRows: Mode = .automatic
        ) {
            self.insertSection = insertSection
            self.deleteSection = deleteSection
            self.insertRows = insertRows
            self.deleteRows = deleteRows
            self.updateRows = updateRows
        }
    }
}
