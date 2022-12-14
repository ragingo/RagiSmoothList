//
//  InnerTableViewSection.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/09.
//

import SwiftUI
import UIKit

final class InnerTableViewSection<Content: View>: UITableViewHeaderFooterView {
    private var hostingView = HostingView<Content>()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(content: Content) {
        hostingView.configure(content: content)
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
