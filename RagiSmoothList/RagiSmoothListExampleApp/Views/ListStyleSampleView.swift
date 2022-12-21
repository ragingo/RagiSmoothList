//
//  ListStyleSampleView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/20.
//

import RagiSmoothList
import SwiftUI

struct ListStyleSampleView: View {
    @State private var scrollToTop = false

    private static let employees = (0..<100)
        .map {
            Employee(
                id: $0 + 1,
                name: "emp \($0 + 1)",
                hireDate: Date().advanced(by: -Double($0 * 60 * 60 * 24))
            )
        }

    struct Section: Hashable, Identifiable {
        let key: String
        var id: String { key }
    }

    @State var groupedEmployees: [RagiSmoothListSectionModel<Section, Employee>] =
        Dictionary(grouping: employees) { employee in
            employee.id.isMultiple(of: 2) ? "even" : "odd"
        }
        .sorted(by: { lhs, rhs in
            lhs.key > rhs.key
        })
        .map { key, value in
            (section: Section(key: key), items: value)
        }
        .listSectionModels()

    var body: some View {
        VStack {
            Button {
                scrollToTop = true
            } label: {
                Text("\(Image(systemName: "arrow.up.circle")) scroll to top")
            }

            RagiSmoothList(
                data: $groupedEmployees,
                listConfiguration: .init(separator: .init(isVisible: true)),
                sectionHeaderContent: { section, _ in
                    Text(section.key)
                        .font(.title)
                        .frame(maxWidth: .infinity)
                },
                sectionFooterContent: { _, _ in
                    EmptyView()
                },
                cellContent: { employee in
                    Text(employee.name)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                }
            )
            .scrollToTop($scrollToTop)
            .ragiSmoothListStyle(.insetGrouped)
        }
    }
}

struct ListStyleSampleView_Previews: PreviewProvider {
    static var previews: some View {
        ListStyleSampleView()
    }
}
