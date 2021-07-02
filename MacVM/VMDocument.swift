//
//  VMDocument.swift
//  MacVM
//
//  Created by Khaos Tian on 6/28/21.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    
    static let macOSVM = UTType(exportedAs: "org.oltica.vm.macos")
}

final class VMDocument: ReferenceFileDocument {
    
    typealias Snapshot = VMContent
    
    @Published var content: VMContent
    @Published var diskURL: URL?
    @Published var auxStorageURL: URL?
    
    @Published var vmInstance: VMInstance?
    @Published var vmInstallationState: VMInstallationState
    
    @Published var isRunning = false
    
    static var readableContentTypes: [UTType] { [.macOSVM] }
    
    func snapshot(contentType: UTType) throws -> VMContent {
        return content
    }
    
    init() {
        let content = VMContent(identifier: UUID().uuidString)
        self.content = content
        vmInstallationState = VMInstallationState(content: content)
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let metadata = configuration.file.fileWrappers?[FileWrapperIdentifier.metadata.rawValue]?.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let content = try JSONDecoder().decode(VMContent.self, from: metadata)
        self.content = content
        vmInstallationState = VMInstallationState(content: content)
    }
    
    func fileWrapper(snapshot: VMContent, configuration: WriteConfiguration) throws -> FileWrapper {
        
        let metadata = try JSONEncoder().encode(snapshot)
        let newMetadata = FileWrapper(regularFileWithContents: metadata)
        newMetadata.preferredFilename = FileWrapperIdentifier.metadata.rawValue

        if let existingFile = configuration.existingFile {
            if let metadataFileWrapper = existingFile.fileWrappers?[FileWrapperIdentifier.metadata.rawValue] {
                existingFile.removeFileWrapper(metadataFileWrapper)
            }
            existingFile.addFileWrapper(newMetadata)
            return existingFile
        }
        

        let fileWrapper = FileWrapper(
            directoryWithFileWrappers: [
                FileWrapperIdentifier.metadata.rawValue: newMetadata
            ]
        )
        return fileWrapper
    }
    
    func createVMInstance(with documentURL: URL) {
        guard vmInstance == nil else {
            return
        }
        
        vmInstance = VMInstance(document: self, documentURL: documentURL)
    }
    
    enum FileWrapperIdentifier: String {
        case metadata
    }
}
