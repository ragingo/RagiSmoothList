//
//  EmployeeCell.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/14.
//

import SwiftUI
import RagiSmoothList

extension InfiniteScrollSampleView {
    struct EmployeeCell: View {
        struct CellButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .background(configuration.isPressed ? Color.yellow : nil)
            }
        }

        let employee: Employee
        let action: () -> Void

        var body: some View {
            RagiSmoothListButtonCell(
                label: {
                    HStack(spacing: 16) {
                        Text("id: \(String(employee.id))")
                            .font(.title3)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.orange)
                            )

                        VStack(alignment: .leading) {
                            Text("\(employee.name)")
                                .font(.title2)
                            Text("hire date: \(employee.hireDate, formatter: Self.dateFormatter)")
                                .font(.subheadline)
                        }

                        Spacer()

                        checkMarkIcon
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                            .opacity(employee.id % 5 == 0 ? 1.0 : 0.0)
                    }
                    .padding()
                    .contentShape(Rectangle())
                },
                action: action
            )
            .buttonStyle(CellButtonStyle())
        }

        private let checkMarkIcon = Image(systemName: "checkmark.circle.fill")

        private static var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter
        }()
    }
}

struct EmployeeCell_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollSampleView.EmployeeCell(
            employee: .init(id: 1, name: "emp 1", hireDate: Date()), action: {}
        )
    }
}
