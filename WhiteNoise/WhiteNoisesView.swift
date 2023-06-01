//
//  SoundsView.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import SwiftUI

struct WhiteNoisesView: View {

    @ObservedObject var viewModel: WhiteNoisesViewModel

    @State private var showPicker = false

    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.soundsViewModels) { viewModel in
                    SoundView(viewModel: viewModel)
                    Divider()
                }
            }
            .padding()

            HStack {
                HStack {
                    Spacer()

                    Button(action: {
                        if self.viewModel.isPlaying {
                            self.viewModel.pauseSounds()
                        } else {
                            self.viewModel.playSounds()
                        }
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle" : "play.circle")
                            .resizable()
                            .frame(width: 36, height: 36)
                    }
                    .padding(8)
                }

                HStack {
                    Button(action: {
                        self.showPicker = true
                    }) {
                        Image(systemName: "timer.circle")
                            .resizable()
                            .frame(width: 36, height: 36)
                    }
                    .padding(8)
                    .popover(isPresented: $showPicker, arrowEdge: .top) {
                        VStack {
                            Picker(selection: $viewModel.selectedMinutes, label: Text("Minutes")) {
                                ForEach(1..<61) { minute in
                                    Text("in \(minute) min")
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(WheelPickerStyle())

                            Button(action: {
                                showPicker = false
                            }) {
                                Text("Done")
                            }
                            .padding()
                        }
                        .background(Color.secondary)
                    }

                    if viewModel.timerRemainingSeconds > 0 {
                        Spacer()
                        Text("\(viewModel.timerRemainingSeconds)")
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
        }
    }
}
