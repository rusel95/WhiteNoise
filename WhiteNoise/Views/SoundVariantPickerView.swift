//
//  SoundVariantPickerView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 2025-07-26.
//

import SwiftUI

struct SoundVariantPickerView: View {
    @Binding var selectedVariant: Sound.SoundVariant
    @Binding var isPresented: Bool
    let soundName: String
    let variants: [Sound.SoundVariant]
    
    @State private var tempSelection: Sound.SoundVariant
    
    init(selectedVariant: Binding<Sound.SoundVariant>, isPresented: Binding<Bool>, soundName: String, variants: [Sound.SoundVariant]) {
        self._selectedVariant = selectedVariant
        self._isPresented = isPresented
        self.soundName = soundName
        self.variants = variants
        self._tempSelection = State(initialValue: selectedVariant.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 16) {
                // Header with sound name
                VStack(spacing: 4) {
                    Text(soundName.capitalized)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Select variant")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 20)
                
                // Native Picker
                Picker("Variant", selection: $tempSelection) {
                    ForEach(variants, id: \.self) { variant in
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(variant.name)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                        .tag(variant)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)
                .clipped()
                .colorScheme(.dark)
                .onChange(of: tempSelection) { _, _ in
                    // Haptic feedback
                    #if os(iOS)
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                    #endif
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    // Cancel button
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 80, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    // Select button
                    Button(action: {
                        // Apply selection
                        selectedVariant = tempSelection
                        
                        // Haptic feedback
                        #if os(iOS)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        #endif
                        
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        Text("Select")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(red: 0.1, green: 0.4, blue: 0.5))
                            )
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(width: 260)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .overlay(
                // Decorative sound wave at the top
                VStack {
                    HStack(spacing: 3) {
                        ForEach(0..<7) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.1, green: 0.4, blue: 0.5).opacity(0.6),
                                        Color(red: 0.05, green: 0.3, blue: 0.4).opacity(0.4)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 3, height: CGFloat.random(in: 8...20))
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: tempSelection
                                )
                        }
                    }
                    .padding(.top, -8)
                    
                    Spacer()
                }
            )
            .scaleEffect(isPresented ? 1 : 0.9)
            .opacity(isPresented ? 1 : 0)
        }
    }
}

struct SoundVariantPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            SoundVariantPickerView(
                selectedVariant: .constant(Sound.SoundVariant(name: "Soft Rain", filename: "soft_rain")),
                isPresented: .constant(true),
                soundName: "Rain",
                variants: [
                    Sound.SoundVariant(name: "Soft Rain", filename: "soft_rain"),
                    Sound.SoundVariant(name: "Heavy Rain", filename: "heavy_rain"),
                    Sound.SoundVariant(name: "Rain on Leaves", filename: "rain_leaves")
                ]
            )
        }
    }
}