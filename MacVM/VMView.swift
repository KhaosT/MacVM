//
//  VMView.swift
//  MacVM
//
//  Created by Khaos Tian on 6/28/21.
//

import SwiftUI

struct VMView: View {
    
    @ObservedObject var document: VMDocument
    var fileURL: URL?
    
    /// - Tag: ToggleAction
    var body: some View {
        Group {
            if let fileURL = fileURL {
                if document.content.installed {
                    VMUIView(virtualMachine: document.vmInstance?.virtualMachine)
                        .overlay {
                            if !document.isRunning {
                                VMControlOverlay(document: document, fileURL: fileURL)
                            }
                        }
                } else {
                    VMInstallView(
                        fileURL: fileURL,
                        document: document,
                        state: document.vmInstallationState
                    )
                }
            } else {
                VMInstallView(
                    fileURL: fileURL,
                    document: document,
                    state: document.vmInstallationState
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
