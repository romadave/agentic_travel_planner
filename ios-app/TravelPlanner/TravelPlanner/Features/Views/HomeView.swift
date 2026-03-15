//
//  ContentView.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/15/26.
//

import SwiftUI

struct HomeView: View {
    @State private var enteredText: String = "Start typing here.."
    var body: some View {
        VStack {
            Text("AI Trip Planner").font(.largeTitle)
            Text("Plan unforgettable trips with this AI planner").font(.subheadline)
        }
        .padding()
        VStack {
            TextEditor(text: $enteredText)
                .padding()
                .font(.body)
            Spacer()
            Button(action: { print("Search tapped") }) {
                Label("Next", systemImage: "magnifyingglass")
            }
                }
                .padding() // Add padding for content spacing inside the box
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 3)
                )
                .padding()
                .multilineTextAlignment(.leading)
    }
}

#Preview {
    HomeView()
}
