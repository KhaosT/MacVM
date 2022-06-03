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
        
    @State private var presentFileSelector = false
    @State private var skipInstallation = false
    @State private var ipswURL: URL?
    
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
            VStack {
                VMSettingsView(content: $document.content)
                Text("Save to continue...")
            }
            .padding()
        }
    }
    
    func save() {
        undoManager?.registerUndo(withTarget: document, handler: { _ in })
    }
}
