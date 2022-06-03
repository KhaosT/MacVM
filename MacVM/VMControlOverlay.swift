//
//  VMControlOverlay.swift
//  MacVM
//
//  Created by Frank Lefebvre on 30/04/2022.
//

import SwiftUI

struct VMControlOverlay: View {
    @ObservedObject var document: VMDocument
    var fileURL: URL
    @State private var presentSettings = false
    @State private var documentContent = VMContent.empty
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        HStack(spacing: 40) {
            Button(action: {
                document.createVMInstance(with: fileURL)
                document.vmInstance?.start()
            }) {
                Image(systemName: "play.circle")
                    .font(.system(size: 96, weight: .regular, design: .rounded))
            }
            .buttonStyle(.borderless)
            Button(action: {
                documentContent = document.content
                presentSettings = true
            }) {
                Image(systemName: "gear.circle")
                    .font(.system(size: 96, weight: .regular, design: .rounded))
            }
            .buttonStyle(.borderless)
        }
        .padding(30)
        .background {
            Color.gray
                .cornerRadius(30)
        }
        .sheet(isPresented: $presentSettings) {
            VStack {
                VMSettingsView(content: $document.content)
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        document.content = documentContent // restore previous settings
                        presentSettings = false // or use @Environment(\.presentationMode)
                    }) {
                        Text("Cancel")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    Button(action: {
                        save()
                        presentSettings = false
                    }) {
                        Text("OK")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top)
            }
            .padding()
            .fixedSize()
        }
    }
    
    func save() {
        undoManager?.registerUndo(withTarget: document, handler: { _ in })
    }
}
