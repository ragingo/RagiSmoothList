//
//  SimpleListSampleView.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/10.
//

import SwiftUI
import RagiSmoothList

struct SimpleListSampleView: View {
    struct CellButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed ? Color.orange : nil)
        }
    }

    @State private var employees: [RagiSmoothListSectionModel<RagiSmoothListEmptySection, RagiSmoothListSectionItemType<Employee>>] = [
        .init(
            model: .init(),
            items: (0..<10_000)
                .map {
                    Employee(id: $0 + 1, name: "emp \($0 + 1)", hireDate: Date().advanced(by: -Double($0 * 60 * 60 * 24)))
                }
                .map {
                    RagiSmoothListSectionItemType(value: $0)
                }
        )
    ]

    var body: some View {
        RagiSmoothList(
            data: $employees,
            listConfiguration: .init(hasSeparator: false),
            cellContent: { employee in
                Button(
                    action: {},
                    label: {
                        HStack {
                            Text("id: \(String(employee.id))")
                                .font(.title)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(.green)
                                )

                            VStack(alignment: .leading) {
                                Text("\(employee.name)")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)

                                Text("hire date: \(employee.hireDate, style: .date)")
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.yellow.opacity(0.2))
                    }
                )
                .buttonStyle(CellButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        )
    }
}

struct SimpleListSampleView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleListSampleView()
    }
}
