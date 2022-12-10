//
//  ContentView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/08.
//

import SwiftUI
import RagiSmoothList

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                makeLink(
                    destination: { InfiniteScrollSampleView() },
                    description: "無限スクロール 動作確認用画面",
                    iconColor: .red
                )
                makeLink(
                    destination: { SimpleListSampleView() },
                    description: "シンプルなリストの動作確認用画面",
                    iconColor: .green
                )
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarTitleDisplayMode(.inline)
    }

    private let tableCellIcon: some View = Image(systemName: "tablecells")
        .resizable()
        .frame(width: 50)

    @ViewBuilder
    private func makeLink<Destination: View>(
        @ViewBuilder destination: @escaping () -> Destination,
        description: String,
        iconColor: Color
    ) -> some View {
        let title = String(describing: Destination.self)

        NavigationLink(
            destination: {
                destination()
                    .navigationTitle(title)
            },
            label: {
                tableCellIcon
                    .foregroundColor(iconColor)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title2)

                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

