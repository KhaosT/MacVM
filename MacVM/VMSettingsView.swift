//
//  VMSettingsView.swift
//  MacVM
//
//  Created by Frank Lefebvre on 01/05/2022.
//

import SwiftUI

struct VMSettingsView: View {
    @Binding var content: VMContent
    
    @State private var memorySize: UInt64
    @State private var diskSize: String
    @State private var bootFromRecovery: Bool
    
    private static let memoryUnit: UInt64 = 1024 * 1024 * 1024
    
    init(content: Binding<VMContent>) {
        self._content = content
        self.memorySize = content.memorySize.wrappedValue / Self.memoryUnit
        self.diskSize = "\(content.diskSize.wrappedValue)"
        self.bootFromRecovery = content.bootFromRecovery.wrappedValue
    }

    private let availableMemoryOptions: [UInt64] = {
        let availableMemory = ProcessInfo.processInfo.physicalMemory
        
        var availableOptions: [UInt64] = []
        var memorySize: UInt64 = 2
        
        while memorySize * memoryUnit <= availableMemory {
            availableOptions.append(memorySize)
            memorySize += 2
        }
        
        return availableOptions
    }()
    
    var body: some View {
        Form {
            Section {
                Picker("CPU Count", selection: $content.cpuCount) {
                    ForEach(1...ProcessInfo.processInfo.processorCount, id: \.self) { count in
                        Text("\(count)")
                    }
                }
                Picker("Memory Size", selection: $memorySize) {
                    ForEach(availableMemoryOptions, id: \.self) { size in
                        Text("\(size) GB")
                    }
                }
                TextField("Disk Size (GB)", text: $diskSize)
                    .disabled(content.installed)
#if swift(>=5.7)
                if #available(macOS 13.0, *) {
                    Toggle("Boot from Recovery", isOn: $bootFromRecovery)
                        .toggleStyle(.checkbox)
                }
#endif
            }
        }
        .onChange(of: memorySize) { newValue in
            content.memorySize = UInt64(newValue) * 1024 * 1024 * 1024
        }
        .onChange(of: diskSize) { newValue in
            if let intValue = UInt64(newValue) {
                content.diskSize = intValue
            }
        }
        .onChange(of: bootFromRecovery) { newValue in
            content.bootFromRecovery = newValue
        }
    }
}
