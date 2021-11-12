//
//  VMInstallView.swift
//  MacVM
//
//  Created by Khaos Tian on 6/28/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct VMInstallView: View {
    
    var fileURL: URL?
    var document: VMDocument
    
    @Environment(\.undoManager) var undoManager
    @ObservedObject var state: VMInstallationState
        
    @State var cpuCount: Int = 2
    @State var memorySize: Int = 2
    @State var diskSize: String = "32"
    
    @State var presentFileSelector = false
    @State var skipInstallation = false
    @State var ipswURL: URL?
    
    let availableMemoryOptions: [Int] = {
        let baseUnit = 1024 * 1024 * 1024 // GB
        let availableMemory = Int(ProcessInfo.processInfo.physicalMemory)
        
        var availableOptions: [Int] = []
        var memorySize = 2
        
        while memorySize * baseUnit <= availableMemory {
            availableOptions.append(memorySize)
            memorySize += 2
        }
        
        return availableOptions
    }()
    
    var body: some View {
        if let fileURL = fileURL {
            if let ipswURL = ipswURL {
                VStack {
                    if state.isInstalling, let progress = state.progress {
                        ProgressView(progress)
                    } else {
                        Button("Install") {
                            document.createVMInstance(with: fileURL)
                            document.vmInstance?.diskImageSize = document.content.diskSize
                            document.vmInstance?.startInstaller(
                                with: ipswURL,
                                skipActualInstallation: skipInstallation,
                                completion: { _ in
                                    save()
                                }
                            )
                        }
                        .disabled(state.isInstalling)
                    }
                }
                .padding()
            } else {
                VStack {
                    Button("Select IPSW and Continue") {
                        presentFileSelector = true
                    }.fileImporter(
                        isPresented: $presentFileSelector,
                        allowedContentTypes: [
                            UTType(filenameExtension: "ipsw") ?? .data
                        ],
                        onCompletion: { result in
                            switch result {
                            case .success(let url):
                                ipswURL = url
                                if skipInstallation {
                                    document.createVMInstance(with: fileURL)
                                    document.vmInstance?.diskImageSize = document.content.diskSize
                                    document.vmInstance?.startInstaller(
                                        with: url,
                                        skipActualInstallation: skipInstallation,
                                        completion: { _ in
                                            save()
                                        }
                                    )
                                }
                            case .failure(let error):
                                print(error)
                            }
                        }
                    )
                }
                .padding()
            }
        } else {
            Form {
                Section {
                    Picker("CPU Count", selection: $cpuCount) {
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
                }
                
                Section {
                    Text("Save to continue...")
                }
            }
            .padding()
            .onChange(of: cpuCount) { newValue in
                document.content.cpuCount = newValue
                save()
            }
            .onChange(of: memorySize) { newValue in
                document.content.memorySize = UInt64(newValue) * 1024 * 1024 * 1024
                save()
            }
            .onChange(of: diskSize) { newValue in
                document.content.diskSize = UInt64(newValue) ?? 32
                save()
            }
        }
    }
    
    func save() {
        undoManager?.registerUndo(withTarget: document, handler: { _ in })
    }
}
