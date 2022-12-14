//
//  InnerTableViewCell.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI
import UIKit

final class InnerTableViewCell<Content: View>: UITableViewCell {
    private var hostingView = HostingView<Content>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(content: Content) {
        hostingView.configure(content: content)
        hostingView.invalidateIntrinsicContentSize()

        if !subviews.contains(hostingView) {
            contentView.addSubview(hostingView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            hostingView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        }
    }
}
