//
//  CreateVideoFromImages.swift
//  VideoEditngTask
//
//  Created by mac on 29/08/2024.
//

import SwiftUI
import AVFoundation

class CreateVideoFromImages {

    func makeVideoOfUIImages(imageURLs: [URL], completion: @escaping (Result<URL, Error>) -> Void) {
        let outputSize = CGSize(width: 1920 * 0.5, height: 1080)
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            completion(.failure(NSError(domain: "VideoCreationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document directory error"])))
            return
        }
        let videoOutputURL = documentDirectory.appendingPathComponent("OutputVideo.mp4")
        
        // Remove existing file if exists
        if fileManager.fileExists(atPath: videoOutputURL.path) {
            do {
                try fileManager.removeItem(at: videoOutputURL)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        // Setup AVAssetWriter
        guard let videoWriter = try? AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4) else {
            completion(.failure(NSError(domain: "VideoCreationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "AVAssetWriter error"])))
            return
        }
        
        let fps: Int32 = 25
        let frameDuration = CMTime(value: 1, timescale: fps)
        let totalDuration = CMTime(seconds: 10, preferredTimescale: fps)
        let numberOfFrames = Int(CMTimeGetSeconds(totalDuration) * Double(fps))
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: outputSize.width,
            AVVideoHeightKey: outputSize.height
        ]
        
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: .video) else {
            completion(.failure(NSError(domain: "VideoCreationError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot apply output settings"])))
            return
        }
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: outputSize.width,
            kCVPixelBufferHeightKey as String: outputSize.height
        ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        
        // Start writing
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let mediaQueue = DispatchQueue(label: "mediaInputQueue")
        
        videoWriterInput.requestMediaDataWhenReady(on: mediaQueue) {
            var appendSucceeded = true
            var frameCount: Int64 = 0
            
            let imageDuration = CMTime(seconds: 10 / Double(imageURLs.count), preferredTimescale: fps)
            
            while appendSucceeded && frameCount < numberOfFrames {
                if videoWriterInput.isReadyForMoreMediaData {
                    autoreleasepool {
                        let currentImageIndex = Int(frameCount) / Int(CMTimeGetSeconds(imageDuration) * Double(fps))
                        guard currentImageIndex < imageURLs.count else {
                            appendSucceeded = false
                            return
                        }
                        
                        let imageURL = imageURLs[currentImageIndex]
                        guard let imageData = try? Data(contentsOf: imageURL),
                              let image = UIImage(data: imageData) else {
                            completion(.failure(NSError(domain: "VideoCreationError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to load image at \(imageURL)"])))
                            return
                        }
                        
                        // Create pixel buffer
                        var pixelBuffer: CVPixelBuffer?
                        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        
                        guard let pixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                            return
                        }
                        
                        CVPixelBufferLockBaseAddress(pixelBuffer, [])
                        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
                        
                        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
                        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                        let context = CGContext(data: baseAddress, width: Int(outputSize.width), height: Int(outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                        
                        context?.clear(CGRect(origin: .zero, size: outputSize))
                        
                        let horizontalRatio = outputSize.width / image.size.width
                        let verticalRatio = outputSize.height / image.size.height
                        let aspectRatio = min(horizontalRatio, verticalRatio)
                        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
                        let x = (outputSize.width - newSize.width) / 2
                        let y = (outputSize.height - newSize.height) / 2
                        
                        context?.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                        
                        let presentationTime = CMTimeAdd(CMTimeMultiply(frameDuration, multiplier: Int32(frameCount)), .zero)
                        appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        frameCount += 1
                    }
                }
            }
            
            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                if videoWriter.status == .completed {
                    completion(.success(videoOutputURL))
                } else {
                    completion(.failure(videoWriter.error ?? NSError(domain: "VideoCreationError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
                }
            }
        }
    }
    private func documentsDirectoryURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
