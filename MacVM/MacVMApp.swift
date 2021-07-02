//
//  MacVMApp.swift
//  MacVM
//
//  Created by Khaos Tian on 6/28/21.
//

import SwiftUI

@main
struct MacVMApp: App {
    var body: some Scene {
        DocumentGroup {
            VMDocument()
        } editor: { configuration in
            VMView(
                document: configuration.document,
                fileURL: configuration.fileURL
            )
        }

    }
}
