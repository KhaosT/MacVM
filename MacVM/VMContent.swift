//
//  VMContent.swift
//  MacVM
//
//  Created by Khaos Tian on 6/28/21.
//

import Foundation
import Virtualization

struct VMContent: Codable {
    
    let identifier: String // set by VMDocument at creation
    var installed: Bool = false // set by VMInstance
    
    var hardwareModelData: Data? // determined by host
    var machineIdentifierData: Data?
    
    var cpuCount: Int = 2 // allowed to change at startup
    var memorySize: UInt64 = 4 * 1024 * 1024 * 1024 // allowed to change at startup
    var diskSize: UInt64 = 32 // allowed to change at install
}

extension VMContent {
    static let empty = VMContent(identifier: "", installed: false, hardwareModelData: nil, machineIdentifierData: nil, cpuCount: 0, memorySize: 0, diskSize: 0)
}
