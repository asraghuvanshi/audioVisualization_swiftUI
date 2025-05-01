//
//  ContentView.swift
//  DemoSwitftUI
//
//  Created by Amit on 30/04/25.
//

import SwiftUI
import AVFoundation

class AudioPlayerMonitor: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?

    @Published var powerLevels: [CGFloat] = Array(repeating: 0.5, count: 9)
    @Published var isPlaying: Bool = false
    @Published var currentTrackIndex: Int = 0
    @Published var trackNames: [String] = ["Sample", "Sample1", "Sample2"] // Without extension

    var currentTrackName: String {
        trackNames[currentTrackIndex]
    }

    override init() {
        super.init()
        setupAudio()
    }

    private func setupAudio() {
        let track = trackNames[currentTrackIndex]
        guard let url = Bundle.main.url(forResource: track, withExtension: "mpeg") else {
            print("Audio file \(track).mpeg not found")
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

    func playTrack(at index: Int) {
        stopPlayback()

        currentTrackIndex = (index + trackNames.count) % trackNames.count // wrap around
        setupAudio()
        togglePlayback() // starts playback
    }

    func nextTrack() {
        playTrack(at: currentTrackIndex + 1)
    }

    func previousTrack() {
        playTrack(at: currentTrackIndex - 1)
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        stopMetering()
        isPlaying = false
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
        let normalizedPower = max(0.05, min(1.0, CGFloat((averagePower + 60) / 60)))

        let newLevels = (0..<9).map { _ in
            let multiplier = CGFloat.random(in: 0.6...1.4)
            return min(1.0, normalizedPower * multiplier)
        }

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
        HStack(spacing: 6) {
            ForEach(0..<audioMonitor.powerLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.green, Color.yellow]), startPoint: .bottom, endPoint: .top))
                    .frame(width: 8, height: 100 * audioMonitor.powerLevels[index])
                    .animation(.easeInOut(duration: 0.15), value: audioMonitor.powerLevels[index])
            }
        }
        .padding(.vertical, 50)
    }
}

struct ContentView: View {
    @StateObject private var audioMonitor = AudioPlayerMonitor()

    var body: some View {
        VStack {
            Text("Now Playing: \(audioMonitor.currentTrackName)")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.top)

            Spacer()

            SoundWaveView(audioMonitor: audioMonitor)
                .frame(height: 200)

            Spacer()

            HStack(spacing: 40) {
                Button(action: {
                    audioMonitor.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }

                Button(action: {
                    audioMonitor.togglePlayback()
                }) {
                    Image(systemName: audioMonitor.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.green)
                }

                Button(action: {
                    audioMonitor.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
