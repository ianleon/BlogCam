//
//  Icon.swift
//  BlogCam
//
//  Created by Ian Leon on 6/24/22.
//

import SwiftUI

struct Icon: View {
    let systemImageName: String
    let accessibilityLabel: String
    let action: () -> Void
    
    init(
        label accessibilityLabel: String,
        _ systemImageName: String = "a",
        action: @escaping () -> Void = { }
    ) {
        self.systemImageName = systemImageName
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    fileprivate func icon() -> some View {
        Image(systemName: systemImageName)
            .font(.system(size: 36))
    }
    
    var body: some View {
        Button(action: action, label: icon)
            .accessibilityLabel(accessibilityLabel)
    }
}
