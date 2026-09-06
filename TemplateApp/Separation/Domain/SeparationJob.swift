import Foundation

struct AudioSelection: Sendable, Equatable {
    let url: URL
    let duration: Double
    let sampleRate: Double
    let channels: Int
    var description: String {
        String(format: "%d:%02d · %.0f kHz · %@", Int(duration) / 60, Int(duration) % 60,
               sampleRate / 1000, channels == 1 ? "Mono" : "Stereo")
    }
}

enum SeparationStage: String, Sendable {
    case preparing, loadingModel, separating, writing, committing, cancelling
    var title: String {
        switch self {
        case .preparing: "Preparing audio…"
        case .loadingModel: "Loading the model…"
        case .separating: "Separating your stems…"
        case .writing: "Writing 24-bit WAV files…"
        case .committing: "Finishing…"
        case .cancelling: "Cancelling…"
        }
    }
}

struct SeparationFailure: Error, LocalizedError, Sendable {
    let message: String
    var errorDescription: String? { message }
    static let cancelled = SeparationFailure(message: "Separation cancelled. Your original audio is unchanged.")
    static let invalidAudio = SeparationFailure(message: "Choose a readable WAV, AIFF, MP3, or unprotected M4A file with one or two channels and up to 20 minutes of audio.")
}

struct PreparedAudio: Sendable { let url: URL; let frames: Int }
struct WorkerStem: Decodable, Sendable { let name: String; let file: String; let byteCount: Int }
struct WorkerEvent: Decodable, Sendable {
    let protocolVersion: Int
    let type: String
    let jobID: String?
    let sequence: Int?
    let stage: String?
    let completedUnits: Int?
    let totalUnits: Int?
    let frames: Int?
    let channels: Int?
    let sampleRate: Int?
    let sampleType: String?
    let layout: String?
    let stems: [WorkerStem]?
    let code: String?
}
