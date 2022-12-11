//
//  VerySlowStandardListSampleView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/11.
//

import SwiftUI

struct VerySlowStandardListSampleView: View {
    enum ListType: String, CaseIterable {
        case list
        case listWithForEach
        case lazyVStack
    }

    private let employees = (0..<10_000)
        .map {
            Employee(
                id: $0 + 1,
                name: "emp \($0 + 1)",
                hireDate: Date().advanced(by: -Double($0 * 60 * 60 * 24))
            )
        }
    @State private var listType: ListType = .list

    var body: some View {
        VStack {
            Picker("list type", selection: $listType) {
                ForEach(ListType.allCases, id: \.self) { type in
                    Text("\(type.rawValue)")
                }
            }
            .pickerStyle(.segmented)

            switch listType {
            case .list:
                list
            case .listWithForEach:
                listWithForEach
            case .lazyVStack:
                lazyVStack
            }
        }
    }

    private var list: some View {
        List(employees, id: \.id) { employee in
            Button {
            } label: {
                Text("id: \(employee.id)")
            }
        }
        .listStyle(.plain)
        .id(UUID())
    }

    private var listWithForEach: some View {
        List {
            ForEach(employees, id: \.id) { employee in
                Button {
                } label: {
                    Text("id: \(employee.id)")
                }
            }
        }
        .listStyle(.plain)
        .id(UUID())
    }

    private var lazyVStack: some View {
        ScrollView {
            LazyVStack {
                ForEach(employees, id: \.id) { employee in
                    Button {
                    } label: {
                        HStack {
                            Text("id: \(employee.id)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Divider()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct VerySlowStandardListSampleView_Previews: PreviewProvider {
    static var previews: some View {
        VerySlowStandardListSampleView()
    }
}
