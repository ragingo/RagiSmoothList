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
    let hireDate: Date
}

extension Employee: Identifiable {}

extension Employee: Hashable {}
