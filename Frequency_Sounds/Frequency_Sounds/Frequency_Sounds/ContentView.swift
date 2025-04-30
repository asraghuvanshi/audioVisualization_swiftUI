//
//  ContentView.swift
//  Frequency_Sound
//
//  Created by Amit Raghuvanshi on 30/04/25.
//

import SwiftUI
import AVFoundation

class AudioMonitor: ObservableObject {
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode?
    private var format: AVAudioFormat?

    @Published var powerLevels: [CGFloat] = Array(repeating: 0.5, count: 9)

    init() {
        self.audioEngine = AVAudioEngine()
        self.inputNode = audioEngine.inputNode
        self.format = inputNode?.inputFormat(forBus: 0)
        requestPermissionAndStart()
    }

    func requestPermissionAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    self.startMonitoring()
                }
            } else {
                print("Microphone permission denied")
            }
        }
    }

    func startMonitoring() {
        guard let inputNode = inputNode, let format = format else { return }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            buffer.frameLength = 1024

            guard let channelData = buffer.floatChannelData?[0] else { return }

            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0

            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }

            let meanSquare = sum / Float(frameLength)
            let rms = sqrt(meanSquare)

            let avgPower = 20 * log10(rms)
            let normalizedPower = max(0.2, min(1.0, CGFloat((avgPower + 50) / 50)))

            DispatchQueue.main.async {
                let newLevels = (0..<9).map { _ in CGFloat.random(in: 0.3...normalizedPower) }
                self.powerLevels = newLevels
            }
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
        } catch {
            print("Audio error: \(error.localizedDescription)")
        }
    }

    deinit {
        inputNode?.removeTap(onBus: 0)
        audioEngine.stop()
    }
}

struct SoundWaveView: View {
    @ObservedObject var audioMonitor: AudioMonitor

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<audioMonitor.powerLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.green)
                    .frame(width: 6, height: 40 * audioMonitor.powerLevels[index])
                    .animation(.easeInOut(duration: 0.2), value: audioMonitor.powerLevels[index])
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var audioMonitor = AudioMonitor()

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()
                SoundWaveView(audioMonitor: audioMonitor)
                Spacer()
            }
            .frame(height: 60)

            Spacer()

            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 40))
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
