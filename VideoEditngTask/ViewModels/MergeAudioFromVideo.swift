//
//  MergeAudioFromVideo.swift
//  VideoEditngTask
//
//  Created by mac on 29/08/2024.
//

import Foundation
import SwiftUI
import AVFoundation

class MergeAudioFromVideo {
    
    func mergeAudioFromVideo(sourceVideoURL: URL, audioVideoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let date = Date()
        let outputURL = documentsDirectoryURL().appendingPathComponent("\(date.timeIntervalSince1970)mergedVideo.mp4")
        
        let outputDirectoryURL = outputURL.deletingLastPathComponent()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        let sourceVideoAsset = AVAsset(url: sourceVideoURL)
        let audioVideoAsset = AVAsset(url: audioVideoURL)
        
        let composition = AVMutableComposition()
        
        guard let sourceVideoTrack = sourceVideoAsset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "MergeErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Source video track not found"])))
            return
        }
        
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: sourceVideoAsset.duration), of: sourceVideoTrack, at: .zero)
        } catch {
            completion(.failure(error))
            return
        }
        
        guard let audioTrack = audioVideoAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(NSError(domain: "MergeErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio track not found"])))
            return
        }
        
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: sourceVideoAsset.duration), of: audioTrack, at: .zero)
        } catch {
            completion(.failure(error))
            return
        }
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
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
                    completion(.failure(NSError(domain: "MergeErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown export status"])))
                }
            }
        }
    }
    func documentsDirectoryURL() -> URL {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
