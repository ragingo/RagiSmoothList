//
//  Employee.swift
//  RagiSmoothListExampleApp
//
//  Created by ragingo on 2022/12/08.
//

import Foundation

struct Employee {
    let id: Int
    let name: String
}

extension Employee: Identifiable {}

extension Employee: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
