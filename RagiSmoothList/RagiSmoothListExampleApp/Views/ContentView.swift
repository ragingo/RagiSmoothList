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
                NavigationLink(
                    destination: {
                        SampleView()
                            .navigationTitle("SampleView")
                    },
                    label: {
                        Image(systemName: "tablecells")
                            .resizable()
                            .frame(width: 50)
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("SampleView")
                                .font(.title2)
                            Text("RagiSmoothList 動作確認用画面")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                )
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
