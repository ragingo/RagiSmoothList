//
//  HostingView.swift
//  RagiSmoothList
//
//  Created by ragingo on 2022/12/09.
//

// original: https://github.com/noahsark769/NGSwiftUITableCellSizing/blob/main/NGSwiftUITableCellSizing/HostingCell.swift
// license:  https://github.com/noahsark769/NGSwiftUITableCellSizing/blob/c346e6c/LICENSE
/**
 MIT License

 Copyright (c) 2020 Noah Gilmore

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import SwiftUI
import UIKit

final class HostingView<Content: View>: UIView {
    private let hostingController = UIHostingController<Content?>(rootView: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)
        hostingController.view.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(content: Content, parentController: UIViewController?) {
        hostingController.rootView = content
        hostingController.view.invalidateIntrinsicContentSize()

        let requiresControllerMove = hostingController.parent != parentController
        if requiresControllerMove {
            parentController?.addChild(hostingController)
        }

        if !subviews.contains(hostingController.view) {
            addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            hostingController.view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }

        if requiresControllerMove {
            hostingController.didMove(toParent: parentController)
        }
    }
}