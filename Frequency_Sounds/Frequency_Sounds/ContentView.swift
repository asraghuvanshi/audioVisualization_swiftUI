//
//  ContentView.swift
//  DemoSwitftUI
//
//  Created by Amit Raghuvanshi on 30/04/25.
//

import SwiftUI
import AVFoundation

class AudioPlayerMonitor: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?

    @Published var powerLevels: [CGFloat] = Array(repeating: 0.5, count: 9)
    @Published var isPlaying: Bool = false

    override init() {
        super.init()
        setupAudio()
    }

    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "Sample", withExtension: "mpeg") else {
            print("Audio file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.numberOfLoops = -1
        } catch {
            print("Audio Player error: \(error.localizedDescription)")
        }
    }

    func togglePlayback() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            stopMetering()
        } else {
            player.play()
            startMetering()
        }

        isPlaying = player.isPlaying
    }

    private func startMetering() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateMeters))
        displayLink?.add(to: .main, forMode: .default)
    }

    private func stopMetering() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateMeters() {
        guard let player = audioPlayer else { return }

        player.updateMeters()
        let averagePower = player.averagePower(forChannel: 0)
        let normalizedPower = max(0.1, min(1.0, CGFloat((averagePower + 60) / 60)))

        let newLevels = (0..<9).map { _ in CGFloat.random(in: 0.3...normalizedPower) }
        self.powerLevels = newLevels
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopMetering()
        isPlaying = false
    }
}

struct SoundWaveView: View {
    @ObservedObject var audioMonitor: AudioPlayerMonitor

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<audioMonitor.powerLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.green)
                    .frame(width: 6, height: 40 * audioMonitor.powerLevels[index])
                    .animation(.easeInOut(duration: 0.2), value: audioMonitor.powerLevels[index])
            }
        }
        .padding(.top, 100)
    }
}

struct ContentView: View {
    @StateObject private var audioMonitor = AudioPlayerMonitor()

    var body: some View {
        VStack {
            Spacer()

            SoundWaveView(audioMonitor: audioMonitor)
                .frame(height: 200)

            Spacer()

            Button(action: {
                audioMonitor.togglePlayback()
            }) {
                Image(systemName: audioMonitor.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
            }
            .padding(.bottom, 60) 
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
