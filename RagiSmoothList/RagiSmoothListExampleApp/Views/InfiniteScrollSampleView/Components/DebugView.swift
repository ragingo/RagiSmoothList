//
//  DebugView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/14.
//

import SwiftUI

extension InfiniteScrollSampleView {
    struct DebugView: View {
        @State private var isExpanded = false
        @Binding var forceFirstLoadError: Bool
        @Binding var forceMoreLoadError: Bool

        var body: some View {
            Expander(
                isExpanded: $isExpanded,
                header: { isExpanded in
                    ExpanderHeader(
                        isExpanded: isExpanded,
                        label: {
                            Text("\(Image(systemName: "gearshape.fill")) Debug Menu")
                        },
                        toggleIcon: {
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                        }
                    )
                    .padding()
                },
                content: { _ in
                    VStack {
                        Toggle("初回データ取得時にエラー", isOn: $forceFirstLoadError)
                            .fixedSize()
                        Toggle("追加データ取得時にエラー", isOn: $forceMoreLoadError)
                            .fixedSize()
                    }
                    .padding()
                }
            )
            .background(Color.blue.opacity(0.3))
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    struct PreviewView: View {
        @State private var forceFirstLoadError = false
        @State private var forceMoreLoadError = false

        var body: some View {
            InfiniteScrollSampleView.DebugView(
                forceFirstLoadError: $forceFirstLoadError,
                forceMoreLoadError: $forceMoreLoadError
            )
        }
    }
    static var previews: some View {
        VStack {
            PreviewView()
            Spacer()
        }
    }
}
