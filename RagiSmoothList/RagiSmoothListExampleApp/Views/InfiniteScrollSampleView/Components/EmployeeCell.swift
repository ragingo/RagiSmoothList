//
//  EmployeeCell.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/14.
//

import RagiSmoothList
import SwiftUI

extension InfiniteScrollSampleView {
    struct EmployeeCell: View {
        struct CellButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .background(configuration.isPressed ? Color.yellow : nil)
            }
        }

        let employee: EditableEmployee
        let action: () -> Void
        private let randomText = String(repeating: UUID().uuidString, count: Int.random(in: 1...5))

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
                            Text("random text:")
                            Text("=== START ===")
                            Text(randomText)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            Text("=== END ===")
                        }

                        Spacer()

                        VStack {
                            Text("deletable")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(2)
                                .border(.red)
                                .frame(minHeight: 0, maxHeight: employee.canEdit ? nil : 0)
                                .clipped()
                        }
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
        let emp1 = EditableEmployee(employee: .init(id: 1, name: "emp 1", hireDate: Date()), canEdit: true)
        let emp2 = EditableEmployee(employee: .init(id: 2, name: "emp 2", hireDate: Date()))

        VStack {
            InfiniteScrollSampleView.EmployeeCell(employee: emp1, action: {})
                .border(.gray)

            InfiniteScrollSampleView.EmployeeCell(employee: emp2, action: {})
                .border(.gray)
        }
    }
}
