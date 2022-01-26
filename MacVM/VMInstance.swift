//
//  VMInstance.swift
//  MacVM
//
//  Created by Khaos Tian on 6/28/21.
//

import AVFoundation
import Foundation
import SwiftUI
import Virtualization

class VMInstallationState: ObservableObject {
    
    @Published var isInstalled: Bool
    @Published var isInstalling: Bool
    @Published var progress: Progress?
    
    init(content: VMContent) {
        isInstalling = false
        isInstalled = content.installed
    }
}

class VMInstance: NSObject, VZVirtualMachineDelegate {
    
    private weak var document: VMDocument?
    private let documentURL: URL
    private(set) var virtualMachine: VZVirtualMachine?
    private(set) var installer: VZMacOSInstaller?
        
    var diskImageSize: UInt64 = 0
    
    @Published var isRunning = false
    var isInstalling = false {
        didSet {
            document?.vmInstallationState.isInstalling = isInstalling
        }
    }
    
    init(document: VMDocument,
         documentURL: URL) {
        self.document = document
        self.documentURL = documentURL
    }
    
    func startInstaller(with ipswURL: URL,
                        skipActualInstallation: Bool,
                        completion: @escaping (Bool) -> Void) {
        isInstalling = true
        VZMacOSRestoreImage.load(from: ipswURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.startForInstallation(
                        image: image,
                        skipActualInstallation: skipActualInstallation,
                        completion: completion
                    )
                case .failure(let error):
                    self.isInstalling = false
                    completion(false)
                    NSLog("Error: \(error)")
                }
            }
        }
    }
    
    private func startForInstallation(image: VZMacOSRestoreImage,
                                      skipActualInstallation: Bool,
                                      completion: @escaping (Bool) -> Void) {
        guard let supportedConfig = image.mostFeaturefulSupportedConfiguration else {
            NSLog("No supported config")
            isInstalling = false
            completion(false)
            return
        }
        
        let machineIdentifier = VZMacMachineIdentifier()
        
        document?.content.hardwareModelData = supportedConfig.hardwareModel.dataRepresentation
        document?.content.machineIdentifierData = machineIdentifier.dataRepresentation
        
        let diskURL = documentURL.appendingPathComponent("disk.img")
        
        do {
            let process = Process()
            process.launchPath = "/bin/dd"
            process.arguments = [
                "if=/dev/zero",
                "of=\(diskURL.path)",
                "bs=1024m",
                "seek=\(diskImageSize)",
                "count=0"
            ]
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("Failed to create disk image")
        }
        
        if skipActualInstallation {
            document?.content.installed = true
            isInstalling = false
            completion(true)
            return
        }
        
        guard let configuration = getVMConfiguration(
            hardwareModel: supportedConfig.hardwareModel,
            machineIdentifier: machineIdentifier,
            diskURL: diskURL,
            auxiliaryStorageURL: documentURL.appendingPathComponent("aux.img")
        ) else {
            isInstalling = false
            completion(false)
            return
        }
        
        do {
            try configuration.validate()
            
            let vm = VZVirtualMachine(configuration: configuration, queue: .main)
            vm.delegate = self
            
            let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: image.url)
            installer.install { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        NSLog("Success")
                        self?.document?.content.installed = true
                    case .failure(let error):
                        NSLog("Error: \(error)")
                    }
                    self?.isInstalling = false
                    completion(true)
                }
            }
                        
            self.virtualMachine = vm
            self.installer = installer
            
            document?.vmInstallationState.progress = installer.progress
        } catch {
            NSLog("Error: \(error)")
            isInstalling = false
            completion(false)
        }
    }
    
    func start() {
        guard let hardwareModelData = document?.content.hardwareModelData,
              let machineIdentifierData = document?.content.machineIdentifierData else {
              return
          }
       
        guard let hardwareModel = VZMacHardwareModel(dataRepresentation: hardwareModelData),
              let machineIdentifier = VZMacMachineIdentifier(dataRepresentation: machineIdentifierData) else {
              return
          }
        
        guard let configuration = getVMConfiguration(
            hardwareModel: hardwareModel,
            machineIdentifier: machineIdentifier,
            diskURL: documentURL.appendingPathComponent("disk.img"),
            auxiliaryStorageURL: documentURL.appendingPathComponent("aux.img")
        ) else {
            return
        }
        
        do {
            try configuration.validate()
            
            let vm = VZVirtualMachine(configuration: configuration, queue: .main)
            vm.delegate = self
            
            vm.start { [weak self] result in
                switch result {
                case .success:
                    self?.document?.isRunning = true
                    NSLog("Success")
                case .failure(let error):
                    NSLog("Error: \(error)")
                }
            }
            
            self.virtualMachine = vm
        } catch {
            NSLog("Error: \(error)")
        }
    }
    
    func stop() {
        self.virtualMachine?.stop(completionHandler: { _ in
            self.document?.isRunning = false
        })
    }
    
    private func getVMConfiguration(hardwareModel: VZMacHardwareModel,
                                    machineIdentifier: VZMacMachineIdentifier,
                                    diskURL: URL,
                                    auxiliaryStorageURL: URL) -> VZVirtualMachineConfiguration? {
        guard let content = document?.content else {
            return nil
        }
        
        let bootloader = VZMacOSBootLoader()
        let entropy = VZVirtioEntropyDeviceConfiguration()
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        
        let heightOfToolbar = 98.0
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = NSScreen.screens.count > 0 ? NSScreen.screens.map {
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: Int($0.frame.size.width * $0.backingScaleFactor),
                heightInPixels: Int(($0.frame.size.height - heightOfToolbar) * $0.backingScaleFactor),
                pixelsPerInch: Int($0.backingScaleFactor * 100)
            )
        } : [VZMacGraphicsDisplayConfiguration(
            widthInPixels: 2560,
            heightInPixels: 1600,
            pixelsPerInch: 220
        )]
        
        let keyboard = VZUSBKeyboardConfiguration()
        let pointingDevice = VZUSBScreenCoordinatePointingDeviceConfiguration()
        
        var storages: [VZStorageDeviceConfiguration] = []
        do {
            let attachment = try VZDiskImageStorageDeviceAttachment(
                url: diskURL,
                readOnly: false
            )
            
            let storage = VZVirtioBlockDeviceConfiguration(attachment: attachment)
            storages.append(storage)
        } catch {
            NSLog("Storage Error: \(error)")
        }

        let soundDevice = VZVirtioSoundDeviceConfiguration()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        soundDevice.streams.append(outputStream)

        AVCaptureDevice.requestAccess(for:  .audio) { _ in }
        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()
        soundDevice.streams.append(inputStream)

        let configuration = VZVirtualMachineConfiguration()
        configuration.bootLoader = bootloader
        
        let platform = VZMacPlatformConfiguration()
        platform.hardwareModel = hardwareModel
        platform.machineIdentifier = machineIdentifier
        
        platform.auxiliaryStorage = try? VZMacAuxiliaryStorage(
            creatingStorageAt: auxiliaryStorageURL,
            hardwareModel: hardwareModel,
            options: [.allowOverwrite]
        )
        
        configuration.platform = platform
        
        configuration.cpuCount = content.cpuCount
        configuration.memorySize = content.memorySize
        configuration.entropyDevices = [entropy]
        configuration.networkDevices = [networkDevice]
        configuration.graphicsDevices = [graphics]
        configuration.keyboards = [keyboard]
        configuration.pointingDevices = [pointingDevice]
        configuration.storageDevices = storages
        configuration.audioDevices = [soundDevice]
        return configuration
    }
    
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        document?.isRunning = false
    }
    
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        document?.isRunning = false
    }
}
