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
    let size: CGFloat
    
    enum Sizes: CGFloat {
        case normal = 36
    }
    
    init(
        label accessibilityLabel: String,
        _ systemImageName: String = "a",
        _ size: Sizes = .normal,
        action: @escaping () -> Void = { }
        
    ) {
        self.systemImageName = systemImageName
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.size = size.rawValue
    }
    
    func icon() -> some View {
        Image(systemName: systemImageName)
            .font(.system(size: size))
    }
    
    var body: some View {
        Button(action: action, label: icon)
            .accessibilityLabel(accessibilityLabel)
    }
}
