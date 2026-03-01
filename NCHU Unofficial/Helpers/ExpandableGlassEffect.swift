//
//  ExpandingGlassEffect.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/2/28.
//

import SwiftUI

struct ExpandableGlassEffect<Content: View, Label: View>: View, Animatable {
    var alighment: Alignment
    var progress: CGFloat
    var labelSize: CGSize = .init(width: 55, height: 55)
    var cornerRadius: CGFloat = 30
    
    @State private var contentSize: CGSize = .zero
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label

    var body: some View {
        GlassEffectContainer {
            let widthDiff = contentSize.width - labelSize.width
            let heightDiff = contentSize.height - labelSize.height
            
            let rWidth = widthDiff * contentOpacity
            let rHeight = heightDiff * contentOpacity
            
            
            ZStack(alignment: alighment) {
                content
                    .blur(radius: 14 * blurProgress)
                    .opacity(contentOpacity)
                    .scaleEffect(contentScale)
                    .onGeometryChange(for: CGSize.self) {
                        $0.size
                    } action: { newValue in
                        contentSize = newValue
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: labelSize.width + rWidth, height: labelSize.height + rHeight)
                
                label
                    .compositingGroup()
                    .blur(radius: 14 * blurProgress)
                    .opacity(1 - labelOpacity)
                    .frame(width: labelSize.width, height: labelSize.height)
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: cornerRadius))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        }
        .scaleEffect(x: 1 - (blurProgress * 0.5), y: 1 - (blurProgress * 0.35), anchor: scaleAnchor)
        .offset(y: offset * blurProgress)
    }
    
    
    var labelOpacity: CGFloat {
        min(progress / 0.35, 1)
    }
    
    var contentOpacity: CGFloat {
        max(progress - 0.35, 0) / 0.65
    }
    
    var contentScale: CGFloat {
        let minAspectScale = min(labelSize.width / contentSize.width, labelSize.height / contentSize.height)
        return minAspectScale + (1 - minAspectScale) * progress
    }
    
    var blurProgress: CGFloat {
        return progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5
    }
    
    var offset: CGFloat {
        switch alighment {
        case .bottom, .bottomLeading, .bottomTrailing: return -75
        case .top, .topLeading, .topTrailing: return 75
        default: return -10
        }
    }
    
    var scaleAnchor: UnitPoint {
        switch alighment {
        case .bottomLeading: .bottomLeading
        case .bottom: .bottom
        case .bottomTrailing: .bottomTrailing
        case .leading: .leading
        case .topLeading: .topLeading
        case .top: .top
        case .topTrailing: .topTrailing
        case .trailing: .trailing
        default: .center
        }
    }
}

