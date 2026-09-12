#if os(macOS)
    import AVFAudio
    import Foundation
    @testable import QenTerraAudioAnalysis
    import Synchronization
    import Testing

    struct PCMBassAnalysisTests {
        @Test("Sustained bass dominates upper mids while silence stays at zero")
        func bassFilterPrefersLowFrequencies() {
            let bassLevel = normalizedBassLevel(
                frequency: 80,
                amplitude: 0.35
            )
            let upperMidLevel = normalizedBassLevel(
                frequency: 1200,
                amplitude: 0.35
            )
            let silenceLevel = normalizedBassLevel(
                frequency: 80,
                amplitude: 0
            )

            #expect(bassLevel > 0.2)
            #expect(bassLevel > upperMidLevel * 2)
            #expect((0 ... 1).contains(bassLevel))
            #expect(silenceLevel == 0)
        }

        @Test("Adaptive normalization keeps quiet and loud masters legible")
        func bassFilterAdaptsToTrackLoudness() {
            let quietLevel = normalizedBassLevel(
                frequency: 80,
                amplitude: 0.055
            )
            let loudLevel = normalizedBassLevel(
                frequency: 80,
                amplitude: 0.35
            )

            #expect(quietLevel > 0.2)
            #expect(abs(quietLevel - loudLevel) < 0.15)
        }

        @Test("Stereo bass energy is invariant to channel polarity")
        func bassFilterCombinesChannelPower() throws {
            let inPhase = try normalizedStereoBassLevel(
                frequency: 80,
                amplitude: 0.35,
                rightPolarity: 1
            )
            let inverted = try normalizedStereoBassLevel(
                frequency: 80,
                amplitude: 0.35,
                rightPolarity: -1
            )
            let upperMid = try normalizedStereoBassLevel(
                frequency: 1200,
                amplitude: 0.35,
                rightPolarity: -1
            )
            let silence = try normalizedStereoBassLevel(
                frequency: 80,
                amplitude: 0,
                rightPolarity: -1
            )

            #expect(inPhase > 0.2)
            #expect(inverted > 0.2)
            #expect(abs(inPhase - inverted) < 0.02)
            #expect(inverted > upperMid * 2)
            #expect(silence == 0)
        }

        @Test("Analyzer reset makes a reused analyzer match a fresh track")
        func bassAnalyzerResetsBetweenTracks() throws {
            let format = try #require(
                AVAudioFormat(
                    standardFormatWithSampleRate: 48000,
                    channels: 1
                )
            )
            let loud = try sineBuffer(
                format: format,
                frequency: 80,
                amplitude: 0.35,
                frameCount: 1024
            )
            let quiet = try sineBuffer(
                format: format,
                frequency: 80,
                amplitude: 0.055,
                frameCount: 1024
            )
            let reusedMeter = PCMBassLevelMeter()
            let reusedAnalyzer = PCMBassAnalyzer(meter: reusedMeter)
            for _ in 0 ..< 240 {
                reusedAnalyzer.process(loud, at: nil)
            }

            reusedAnalyzer.reset()
            reusedAnalyzer.process(quiet, at: nil)

            let freshMeter = PCMBassLevelMeter()
            let freshAnalyzer = PCMBassAnalyzer(meter: freshMeter)
            freshAnalyzer.process(quiet, at: nil)

            #expect(
                abs(reusedMeter.currentBassLevel() - freshMeter.currentBassLevel())
                    < 0.001
            )
        }

        @Test("Detached sendable tap publishes without an actor hop")
        func bassTapIsDetachedAndSendable() async throws {
            let format = try #require(
                AVAudioFormat(
                    standardFormatWithSampleRate: 48000,
                    channels: 1
                )
            )
            let buffer = try sineBuffer(
                format: format,
                frequency: 80,
                amplitude: 0.35,
                frameCount: 4800
            )
            let meter = PCMBassLevelMeter()
            let analyzer = PCMBassAnalyzer(meter: meter)
            let tap: PCMBassTap = makePCMBassTap(analyzer: analyzer)

            await Task.detached {
                tap(
                    buffer,
                    AVAudioTime(sampleTime: 0, atRate: format.sampleRate)
                )
            }.value

            #expect(meter.currentBassLevel() > 0)
        }

        #if DEBUG
            @Test("A reset epoch rejects an already-running tap publication")
            func bassResetFencesInflightPublication() throws {
                let format = try #require(
                    AVAudioFormat(
                        standardFormatWithSampleRate: 48000,
                        channels: 1
                    )
                )
                let buffer = try sineBuffer(
                    format: format,
                    frequency: 80,
                    amplitude: 0.35,
                    frameCount: 4800
                )
                let meter = PCMBassLevelMeter()
                let gate = BassPublicationGate()
                let analyzer = PCMBassAnalyzer(
                    meter: meter,
                    beforePublicationForTesting: { @Sendable in
                        gate.suspendOnce()
                    }
                )
                let tap = makePCMBassTap(analyzer: analyzer)
                let callbackFinished = DispatchSemaphore(value: 0)
                let callbackInput = SendableBassCallbackInput(
                    buffer: buffer,
                    time: AVAudioTime(sampleTime: 0, atRate: format.sampleRate)
                )
                DispatchQueue.global().async {
                    tap(callbackInput.buffer, callbackInput.time)
                    callbackFinished.signal()
                }
                let didReachPublication = waitForSemaphore(
                    gate.reachedPublication,
                    timeout: .now() + 2
                )
                #expect(didReachPublication)

                analyzer.reset()
                analyzer.reset()
                gate.releasePublication.signal()
                #expect(
                    waitForSemaphore(
                        callbackFinished,
                        timeout: .now() + 2
                    )
                )

                #expect(meter.currentBassLevel() == 0)
                analyzer.process(buffer, at: nil)
                #expect(meter.currentBassLevel() > 0)
            }
        #endif

        @Test("Native envelopes interpolate only within finite sample bounds")
        func bassEnvelopeInterpolationIsSafe() {
            let envelope = PlaybackBassEnvelope(
                samplesPerSecond: 2,
                levels: [0, 1, 0.25]
            )
            let empty = PlaybackBassEnvelope(
                samplesPerSecond: 2,
                levels: []
            )

            #expect(envelope.level(at: 0) == 0)
            #expect(envelope.level(at: 0.25) == 0.5)
            #expect(envelope.level(at: 0.5) == 1)
            #expect(envelope.level(at: 1) == 0.25)
            #expect(envelope.level(at: -0.1) == 0)
            #expect(envelope.level(at: .nan) == 0)
            #expect(envelope.level(at: .infinity) == 0)
            #expect(envelope.level(at: 1.001) == 0)
            #expect(empty.level(at: 0) == 0)
        }

        @Test("Native analysis caps reads, analyzed frames, and retained levels")
        func nativeBassAnalysisIsBounded() throws {
            let source = try CountingBassPCMSource(
                sampleRate: 48000,
                channelCount: 2,
                length: 48000 * 60 * 60 * 10,
                frequency: 80
            )
            let policy = PlaybackBassAnalysisPolicy(
                samplesPerSecond: 60,
                readFrameCapacity: 65536,
                maxAnalyzedDuration: 2,
                maxRetainedLevels: 120
            )

            let envelope = try PlaybackBassEnvelopeAnalyzer.analyze(
                source: source,
                policy: policy
            )

            #expect(source.readCount <= 2)
            #expect(source.framePosition == 96000)
            #expect(envelope.levels.count <= policy.maxRetainedLevels)
            #expect(envelope.levels.count == 120)
            #expect(envelope.levels.suffix(30).allSatisfy { $0 > 0.2 })
            #expect(envelope.level(at: 2) == 0)
        }

        @Test("A straddled gapless tap buffer starts the successor fresh")
        func exactGaplessBassBoundary() throws {
            let sampleRate = 48000.0
            let format = try #require(
                AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: sampleRate,
                    channels: 2,
                    interleaved: false
                )
            )
            let combined = try #require(
                AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)
            )
            combined.frameLength = 1024
            let combinedChannels = try #require(combined.floatChannelData)
            for frame in 0 ..< 1024 {
                let frequency = frame < 512 ? 80.0 : 80.0
                let amplitude = frame < 512 ? 0.9 : 0.02
                let sample = Float(
                    amplitude * sin(Double(frame) * 2 * .pi * frequency / sampleRate)
                )
                combinedChannels[0][frame] = sample
                combinedChannels[1][frame] = sample
            }

            let successorOnly = try #require(
                AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)
            )
            successorOnly.frameLength = 512
            let successorChannels = try #require(successorOnly.floatChannelData)
            for frame in 0 ..< 512 {
                successorChannels[0][frame] = combinedChannels[0][frame + 512]
                successorChannels[1][frame] = combinedChannels[1][frame + 512]
            }

            let boundaryMeter = PCMBassLevelMeter()
            let boundaryAnalyzer = PCMBassAnalyzer(meter: boundaryMeter)
            boundaryAnalyzer.scheduleSuccessorBoundary(
                at: 512,
                scheduleGeneration: 1,
                predecessorTicket: 1
            )
            boundaryAnalyzer.process(
                combined,
                at: AVAudioTime(sampleTime: 0, atRate: sampleRate)
            )

            let freshMeter = PCMBassLevelMeter()
            let freshAnalyzer = PCMBassAnalyzer(meter: freshMeter)
            freshAnalyzer.process(
                successorOnly,
                at: AVAudioTime(sampleTime: 512, atRate: sampleRate)
            )

            #expect(
                abs(
                    boundaryMeter.currentBassLevel()
                        - freshMeter.currentBassLevel()
                ) < 0.000_001
            )
        }

        @Test("A stale equal-sample completion cannot consume a rearmed boundary")
        func staleEqualSampleCompletionCannotClearReplacementBoundary() throws {
            let meter = PCMBassLevelMeter()
            let analyzer = PCMBassAnalyzer(meter: meter)

            analyzer.scheduleSuccessorBoundary(
                at: 512,
                scheduleGeneration: 1,
                predecessorTicket: 41
            )
            analyzer.scheduleSuccessorBoundary(
                at: 512,
                scheduleGeneration: 2,
                predecessorTicket: 42
            )
            analyzer.resetAtSuccessorBoundary(
                512,
                scheduleGeneration: 1,
                predecessorTicket: 41
            )

            try assertSuccessorStartsFresh(analyzer: analyzer, meter: meter)
        }

        @Test("Successor adoption gives the following transition new authority")
        func threeTrackBoundaryAuthorityCannotBeClearedByPriorCompletion() throws {
            let meter = PCMBassLevelMeter()
            let analyzer = PCMBassAnalyzer(meter: meter)

            analyzer.scheduleSuccessorBoundary(
                at: 512,
                scheduleGeneration: 7,
                predecessorTicket: 51
            )
            analyzer.resetAtSuccessorBoundary(
                512,
                scheduleGeneration: 7,
                predecessorTicket: 51
            )
            analyzer.scheduleSuccessorBoundary(
                at: 512,
                scheduleGeneration: 7,
                predecessorTicket: 52
            )
            analyzer.resetAtSuccessorBoundary(
                512,
                scheduleGeneration: 7,
                predecessorTicket: 51
            )

            try assertSuccessorStartsFresh(analyzer: analyzer, meter: meter)
        }

        @Test("Public file analysis reads a bounded real WAV and cancels")
        func publicFileAnalysisReadsWaveAndCancels() async throws {
            let directory = FileManager.default.temporaryDirectory.appending(
                path: "Cadence-Native-Bass-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            defer { try? FileManager.default.removeItem(at: directory) }

            let duration = 2.0
            let bassURL = directory.appending(path: "bass.wav")
            let upperMidURL = directory.appending(path: "upper-mid.wav")
            try writeStereoWave(
                to: bassURL,
                frequency: 80,
                duration: duration,
                rightPolarity: -1
            )
            try writeStereoWave(
                to: upperMidURL,
                frequency: 1200,
                duration: duration,
                rightPolarity: -1
            )

            let bass = try PlaybackBassEnvelopeAnalyzer.analyze(url: bassURL)
            let upperMid = try PlaybackBassEnvelopeAnalyzer.analyze(url: upperMidURL)
            let bassTail = bass.levels.suffix(30)
            let upperMidTail = upperMid.levels.suffix(30)
            let bassAverage = bassTail.reduce(0, +) / Float(bassTail.count)
            let upperMidAverage = upperMidTail.reduce(0, +)
                / Float(upperMidTail.count)

            #expect(!bass.levels.isEmpty)
            #expect(
                bass.levels.count
                    <= PlaybackBassAnalysisPolicy.production.maxRetainedLevels
            )
            #expect(bassAverage > 0.2)
            #expect(bassAverage > upperMidAverage * 2)
            #expect(bass.level(at: duration - 1.0 / 60.0) > 0)
            #expect(bass.level(at: duration) == 0)

            let cancelled = Task.detached {
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                return try PlaybackBassEnvelopeAnalyzer.analyze(url: bassURL)
            }
            await #expect(throws: CancellationError.self) {
                try await cancelled.value
            }
        }
    }

    private final class BassPublicationGate: @unchecked Sendable {
        let reachedPublication = DispatchSemaphore(value: 0)
        let releasePublication = DispatchSemaphore(value: 0)

        private let shouldSuspend = Atomic<Bool>(true)

        func suspendOnce() {
            guard shouldSuspend.exchange(
                false,
                ordering: .acquiringAndReleasing
            ) else {
                return
            }
            reachedPublication.signal()
            releasePublication.wait()
        }
    }

    private final class SendableBassCallbackInput: @unchecked Sendable {
        let buffer: AVAudioPCMBuffer
        let time: AVAudioTime

        init(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
            self.buffer = buffer
            self.time = time
        }
    }

    private final class CountingBassPCMSource: PlaybackBassPCMReading {
        let processingFormat: AVAudioFormat
        let length: AVAudioFramePosition
        private(set) var framePosition: AVAudioFramePosition = 0
        private(set) var readCount = 0

        private let frequency: Double

        init(
            sampleRate: Double,
            channelCount: AVAudioChannelCount,
            length: AVAudioFramePosition,
            frequency: Double
        ) throws {
            processingFormat = try #require(
                AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: sampleRate,
                    channels: channelCount,
                    interleaved: false
                )
            )
            self.length = length
            self.frequency = frequency
        }

        func read(
            into buffer: AVAudioPCMBuffer,
            frameCount requestedFrameCount: AVAudioFrameCount
        ) throws {
            readCount += 1
            let available = max(length - framePosition, 0)
            let frameCount = min(
                AVAudioFramePosition(requestedFrameCount),
                available,
                AVAudioFramePosition(buffer.frameCapacity)
            )
            buffer.frameLength = AVAudioFrameCount(frameCount)
            guard frameCount > 0,
                  let channels = buffer.floatChannelData
            else {
                return
            }
            for frame in 0 ..< Int(frameCount) {
                let sourceFrame = framePosition + AVAudioFramePosition(frame)
                let sample = Float(
                    sin(
                        2 * Double.pi * frequency * Double(sourceFrame)
                            / processingFormat.sampleRate
                    )
                ) * 0.35
                for channel in 0 ..< Int(processingFormat.channelCount) {
                    channels[channel][frame] = channel.isMultiple(of: 2)
                        ? sample
                        : -sample
                }
            }
            framePosition += frameCount
        }
    }

    private extension PCMBassAnalysisTests {
        func normalizedBassLevel(
            frequency: Double,
            amplitude: Float
        ) -> Float {
            let sampleRate = 48000.0
            let frameCount = 1024
            var filter = PCMBassEnergyFilter(sampleRate: sampleRate)
            var level: Float = 0
            for chunk in 0 ..< 240 {
                let samples = (0 ..< frameCount).map { frame in
                    let sample = chunk * frameCount + frame
                    return Float(
                        sin(2 * Double.pi * frequency * Double(sample) / sampleRate)
                    ) * amplitude
                }
                level = filter.process(samples: samples)
            }
            return level
        }

        func sineBuffer(
            format: AVAudioFormat,
            frequency: Double,
            amplitude: Float,
            frameCount: AVAudioFrameCount
        ) throws -> AVAudioPCMBuffer {
            let buffer = try #require(
                AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: frameCount
                )
            )
            buffer.frameLength = frameCount
            let samples = try #require(buffer.floatChannelData?[0])
            for frame in 0 ..< Int(frameCount) {
                samples[frame] = Float(
                    sin(
                        2 * Double.pi * frequency * Double(frame)
                            / format.sampleRate
                    )
                ) * amplitude
            }
            return buffer
        }

        func normalizedStereoBassLevel(
            frequency: Double,
            amplitude: Float,
            rightPolarity: Float
        ) throws -> Float {
            let sampleRate = 48000.0
            let frameCount = 4800
            let format = try #require(
                AVAudioFormat(
                    standardFormatWithSampleRate: sampleRate,
                    channels: 2
                )
            )
            let buffer = try #require(
                AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: AVAudioFrameCount(frameCount)
                )
            )
            buffer.frameLength = AVAudioFrameCount(frameCount)
            let channels = try #require(buffer.floatChannelData)
            for frame in 0 ..< frameCount {
                let sample = Float(
                    sin(2 * Double.pi * frequency * Double(frame) / sampleRate)
                ) * amplitude
                channels[0][frame] = sample
                channels[1][frame] = sample * rightPolarity
            }

            var filter = PCMBassEnergyFilter(sampleRate: sampleRate)
            var level: Float = 0
            for _ in 0 ..< 60 {
                level = filter.process(
                    channelData: channels,
                    channelCount: 2,
                    frameCount: frameCount
                )
            }
            return level
        }

        func waitForSemaphore(
            _ semaphore: DispatchSemaphore,
            timeout: DispatchTime
        ) -> Bool {
            semaphore.wait(timeout: timeout) == .success
        }

        func assertSuccessorStartsFresh(
            analyzer: PCMBassAnalyzer,
            meter: PCMBassLevelMeter,
            boundary: AVAudioFramePosition = 512
        ) throws {
            let sampleRate = 48000.0
            let format = try #require(
                AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: sampleRate,
                    channels: 2,
                    interleaved: false
                )
            )
            let combined = try #require(
                AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)
            )
            combined.frameLength = 1024
            let combinedChannels = try #require(combined.floatChannelData)
            for frame in 0 ..< 1024 {
                let amplitude = frame < 512 ? 0.9 : 0.02
                let sample = Float(
                    amplitude * sin(Double(frame) * 2 * .pi * 80 / sampleRate)
                )
                combinedChannels[0][frame] = sample
                combinedChannels[1][frame] = sample
            }
            let successorOnly = try #require(
                AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)
            )
            successorOnly.frameLength = 512
            let successorChannels = try #require(successorOnly.floatChannelData)
            for frame in 0 ..< 512 {
                successorChannels[0][frame] = combinedChannels[0][frame + 512]
                successorChannels[1][frame] = combinedChannels[1][frame + 512]
            }

            analyzer.process(
                combined,
                at: AVAudioTime(
                    sampleTime: boundary - 512,
                    atRate: sampleRate
                )
            )
            let freshMeter = PCMBassLevelMeter()
            let freshAnalyzer = PCMBassAnalyzer(meter: freshMeter)
            freshAnalyzer.process(
                successorOnly,
                at: AVAudioTime(sampleTime: boundary, atRate: sampleRate)
            )

            #expect(
                abs(meter.currentBassLevel() - freshMeter.currentBassLevel())
                    < 0.000_001
            )
        }

        func writeStereoWave(
            to url: URL,
            frequency: Double,
            duration: TimeInterval,
            rightPolarity: Float
        ) throws {
            let sampleRate = 48000.0
            let frameCount = AVAudioFrameCount(duration * sampleRate)
            let format = try #require(
                AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: sampleRate,
                    channels: 2,
                    interleaved: false
                )
            )
            let buffer = try #require(
                AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: frameCount
                )
            )
            buffer.frameLength = frameCount
            let channels = try #require(buffer.floatChannelData)
            for frame in 0 ..< Int(frameCount) {
                let sample = Float(
                    sin(2 * Double.pi * frequency * Double(frame) / sampleRate)
                ) * 0.35
                channels[0][frame] = sample
                channels[1][frame] = sample * rightPolarity
            }
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
        }
    }
#endif
