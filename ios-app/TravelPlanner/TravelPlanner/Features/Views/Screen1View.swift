//
//  Screen1View.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/16/26.
//

import SwiftUI

struct Screen1View: View {
    @State private var tripPrompt: String = ""
    var body: some View {
        ZStack {
            Color(red: 248/255, green:243/255, blue:248/255)
                .ignoresSafeArea()
            
            VStack {
                Spacer(minLength: 30)
                
                mainCard
                
                Spacer()
            }
            .padding(.horizontal,20)
        }
    }
    
    // main card
    private var mainCard: some View {
        VStack (spacing: 0){
            headerSection
            promptSection.padding(.top, 36)
            Spacer(minLength: 120)
            PrimaryButton {
                print("Trip Prompt : \(tripPrompt)")
            } content: {
                Text("Start Planning")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }.padding(.horizontal, 28)
            Divider()
                .padding(.horizontal, 28)
                .padding(.top, 24)

            voiceSection
                .padding(.top, 18)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
                .frame(height: 700)
                .background(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Color(red: 244/255, green: 236/255, blue: 247/255))
                )
                .shadow(color: Color.purple.opacity(0.08), radius: 20, x: 0, y: 8)
    }

    // creates the header section
    private var headerSection : some View {
        VStack(spacing:16) {
            Text("AI Travel\n Planner")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.purple.opacity(0.95))
                .padding(.top, 56)
            
            Text("Plan unforgettable trips\nwith an AI travel assistant")
                            .font(.system(size: 16, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.black.opacity(0.65))
                            .lineSpacing(4)
        }.padding(.horizontal,20)
    }

    //
    private var promptSection: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10){
                Text("Where would you like to go?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.6))
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $tripPrompt)
                        .font(.system(size: 17))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 4) // small inset to match placeholder
                        .frame(minHeight: 140) // give it some height
                    
                    if tripPrompt.isEmpty {
                        Text("Or describe your trip")
                            .font(.system(size: 17))
                            .foregroundColor(Color.black.opacity(0.3))
                            .padding(.top, 8)
                            .padding(.leading, 8)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1))
                )
            }.padding(.horizontal,16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 200,alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.55)))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.purple.opacity(0.10), lineWidth: 1))
        }.padding(.horizontal, 20)
    }
    
    private var voiceSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.purple.opacity(0.5))

            Text("Or speak your trip")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.purple.opacity(0.65))
        }
    }
}

#Preview {
    Screen1View()
}
