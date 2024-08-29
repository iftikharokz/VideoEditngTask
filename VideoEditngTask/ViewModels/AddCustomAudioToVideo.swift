//
//  AddCustomAudioToVideoVM.swift
//  VideoEditngTask
//
//  Created by mac on 29/08/2024.
//

import Foundation
import AVFoundation

class AddCustomAudioToVideo{
    
    func addMP3ToVideo(videoURL: URL, audioURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)
        let date = Date()
        let outputURL = documentsDirectoryURL().appendingPathComponent("\(date.timeIntervalSince1970)mergedVideo.mp4")
        
        let composition = AVMutableComposition()
        
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "MergeErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Video track not found"])))
            return
        }
        
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
        } catch {
            completion(.failure(error))
            return
        }
        
        guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(NSError(domain: "MergeErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio track not found"])))
            return
        }
        
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            let audioDuration = min(audioAsset.duration, videoAsset.duration)
            try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration), of: audioTrack, at: .zero)
        } catch {
            completion(.failure(error))
            return
        }
        
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                completion(.success(outputURL))
            case .failed, .cancelled:
                if let error = exportSession?.error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "MergeErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown export error"])))
                }
            default:
                break
            }
        }
    }
    func documentsDirectoryURL() -> URL {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
