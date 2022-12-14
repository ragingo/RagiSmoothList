//
//  SectionFooter.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/14.
//

import SwiftUI

extension InfiniteScrollSampleView {
    struct SectionFooter: View {
        let subtotal: Int

        var body: some View {
            HStack {
                Text("subtotal: \(subtotal)")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.2))
        }
    }
}

struct SectionFooter_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollSampleView.SectionFooter(subtotal: 100)
    }
}
