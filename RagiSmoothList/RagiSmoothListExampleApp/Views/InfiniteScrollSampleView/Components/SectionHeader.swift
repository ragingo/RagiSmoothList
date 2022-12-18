//
//  SectionHeader.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/14.
//

import SwiftUI

extension InfiniteScrollSampleView {
    struct SectionHeader: View {
        let hireYear: String

        var body: some View {
            Button {
            } label: {
                HStack {
                    calendarIcon
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.purple)
                    Text("hire year: \(hireYear)")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .background(Color(red: 176 / 255, green: 237 / 255, blue: 148 / 255))
            }
        }

        private let calendarIcon = Image(systemName: "calendar")
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollSampleView.SectionHeader(hireYear: "2022")
    }
}
