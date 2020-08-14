//
//  Representable.swift
//  BlogCam
//
//  Created by Ian Leon on 8/14/20.
//

import SwiftUI

/// Simple, generic UIView representable
struct Rep<T: UIView>: UIViewRepresentable {
    
    typealias UIViewType = UIView
    var view: T
    func makeUIView(context: Context) -> UIView { view }
    func updateUIView(_ uiView: UIView, context: Context) { }
}
