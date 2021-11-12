//
//  VMUIView.swift
//  MacVM
//
//  Created by Khaos Tian on 6/29/21.
//

import SwiftUI
import Virtualization

struct VMUIView: NSViewRepresentable {
    
    var virtualMachine: VZVirtualMachine?
    
    func makeNSView(context: Context) -> VZVirtualMachineView {
        let view = VZVirtualMachineView()
        view.capturesSystemKeys = true
        return view
    }
    
    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        nsView.virtualMachine = virtualMachine
        nsView.window?.makeFirstResponder(nsView)
    }
}
