//
//  P.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/16/26.
//

import SwiftUI

struct PrimaryButton<Content:View> : View {
    let content : Content
    let action: () -> Void
    let buttonClicked: Bool
    
    init(action: @escaping () -> Void,
         @ViewBuilder content: () -> Content, buttonClicked: Bool) {
            self.action = action
            self.content = content()
            self.buttonClicked = buttonClicked
    }
    
    var body : some View {
        Button (action: action){
            content
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 142/255, green: 58/255, blue: 255/255),
                            Color(red: 206/255, green: 61/255, blue: 240/255)
                ],
                        startPoint: .leading,
                        endPoint: .trailing))
                .clipShape(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .shadow(color: Color.purple.opacity(0.22), radius: 10, x:0, y:6)
        }
        .buttonStyle(.plain)
        .disabled(buttonClicked)
    }
}

