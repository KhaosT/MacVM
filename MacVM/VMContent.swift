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
    var installed: Bool // set by VMInstance
    var bootFromRecovery: Bool
    
    var hardwareModelData: Data? // determined by host
    var machineIdentifierData: Data?
    
    var cpuCount: Int // allowed to change at startup
    var memorySize: UInt64 // allowed to change at startup
    var diskSize: UInt64 // allowed to change at install

    init(identifier: String,
         installed: Bool = false,
         bootFromRecovery: Bool = false,
         hardwareModelData: Data? = nil,
         machineIdentifierData: Data? = nil,
         cpuCount: Int = 2,
         memorySize: UInt64 = 4 * 1024 * 1024 * 1024,
         diskSize: UInt64 = 32) {
        self.identifier = identifier
        self.installed = installed
        self.bootFromRecovery = bootFromRecovery
        self.hardwareModelData = hardwareModelData
        self.machineIdentifierData = machineIdentifierData
        self.cpuCount = cpuCount
        self.memorySize = memorySize
        self.diskSize = diskSize
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.installed = try container.decode(Bool.self, forKey: .installed)

        do {
            self.bootFromRecovery = try container.decode(Bool.self, forKey: .bootFromRecovery)
        } catch {
            self.bootFromRecovery = false
        }

        self.hardwareModelData = try container.decodeIfPresent(Data.self, forKey: .hardwareModelData)
        self.machineIdentifierData = try container.decodeIfPresent(Data.self, forKey: .machineIdentifierData)
        self.cpuCount = try container.decode(Int.self, forKey: .cpuCount)
        self.memorySize = try container.decode(UInt64.self, forKey: .memorySize)
        self.diskSize = try container.decode(UInt64.self, forKey: .diskSize)
    }
}

extension VMContent {

    static let empty = VMContent(
        identifier: "",
        installed: false,
        bootFromRecovery: false,
        hardwareModelData: nil,
        machineIdentifierData: nil,
        cpuCount: 0,
        memorySize: 0,
        diskSize: 0
    )
}
