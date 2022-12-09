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

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(content: Content, parentController: UIViewController?) {
        hostingView.set(content: content, parentController: parentController)
        hostingView.invalidateIntrinsicContentSize()

        if !subviews.contains(hostingView) {
            addSubview(hostingView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            hostingView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }
}
