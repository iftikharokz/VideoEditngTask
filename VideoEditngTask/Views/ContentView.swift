//
//  ContentView.swift
//  VideoEditngTask
//
//  Created by mac on 29/08/2024.
//

import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel : VideoEditorViewModel
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if let url = viewModel.url {
                    NavigationLink(destination: VideoPlayerView(videoURL: url), isActive: $viewModel.playVideo) {
                        EmptyView()
                    }
                }
                CustomButtonView(title: "Merge 2nd Audio with 1st Video") {
                    viewModel.mergeVideos(sourceVideo: "video1", audioVideo: "video2")
                }
                CustomButtonView(title: "Merge 1st Audio with 2nd Video") {
                    viewModel.mergeVideos(sourceVideo: "video2", audioVideo: "video1")
                }
                CustomButtonView(title: "Add Audio to 3rd Video") {
                    viewModel.mergeAudioToVideo(audio: "audio", video: "video3")
                }
                CustomButtonView(title: "Create Animation from Images") {
                    viewModel.createAnimatedVideo()
                }
                CustomButtonView(title: "Overlay Animation") {
                    let url = getResourceURL(named: "video1", withExtension: "mp4")
                    let imageURLs = [
                        getResourceURL(named: "image1", withExtension: "jpg")!,
                        getResourceURL(named: "image2", withExtension: "jpg")!,
                        getResourceURL(named: "image3", withExtension: "jpg")!
                    ]
                    let date = Date()
                    let outputURL = documentsDirectoryURL().appendingPathComponent("\(date.timeIntervalSince1970)mergedVideo.mp4")
                    overlayImagesOnVideo(videoURL: url!, imageURLs: imageURLs, duration: CMTime(seconds: 10, preferredTimescale: 600), outputURL: outputURL) { result in
                        switch result {
                        case .success(let url):
                            viewModel.url = url
                            viewModel.playVideo = true
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                        viewModel.isProcessing = false
                    }
                }
            }
            .padding()
            if viewModel.isProcessing {
                LoadingView()
            }
        }
        .navigationTitle("Video Editor")
    }
    func documentsDirectoryURL() -> URL {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private func getResourceURL(named name: String, withExtension ext: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    func overlayImagesOnVideo(videoURL: URL, imageURLs: [URL], duration: CMTime, outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: videoURL)
        
        // Ensure the video track exists
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "OverlayErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])))
            return
        }
        
        let videoSize = videoTrack.naturalSize
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height
        ]
        
        // Create AVAssetWriter
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(.failure(NSError(domain: "OverlayErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create asset writer"])))
            return
        }
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height
        ])
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Create AVAssetReader
        guard let reader = try? AVAssetReader(asset: asset) else {
            completion(.failure(NSError(domain: "OverlayErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create asset reader"])))
            return
        }
        
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB
        ])
        
        // Add the output before starting reading
        if reader.canAdd(readerOutput) {
            reader.add(readerOutput)
        } else {
            completion(.failure(NSError(domain: "OverlayErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to add reader output"])))
            return
        }
        
        // Start reading
        if reader.startReading() == false {
            completion(.failure(NSError(domain: "OverlayErrorDomain", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to start reading"])))
            return
        }
        
        // Queue for processing frames
        let mediaQueue = DispatchQueue(label: "mediaInputQueue")

        writerInput.requestMediaDataWhenReady(on: mediaQueue) {
            let fps: Int32 = 30
            let frameDuration = CMTime(value: 1, timescale: fps)
            let totalFrames = Int(duration.seconds * Double(fps))
            var frameCount: Int64 = 0
            var appendSucceeded = true
            var currentImageIndex = 0
            let imageDuration = CMTime(seconds: duration.seconds / Double(imageURLs.count), preferredTimescale: fps)
            
            while appendSucceeded && frameCount < Int64(totalFrames) {
                if writerInput.isReadyForMoreMediaData {
                    autoreleasepool {
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer(), let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                            CVPixelBufferLockBaseAddress(pixelBuffer, [])
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                                    width: Int(videoSize.width),
                                                    height: Int(videoSize.height),
                                                    bitsPerComponent: 8,
                                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                    space: rgbColorSpace,
                                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            
                            context?.clear(CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height))
                            
                            // Overlay the current image
                            let image = UIImage(contentsOfFile: imageURLs[currentImageIndex].path)!
                            let imageSize = image.size
                            let aspectRatio = min(videoSize.width / imageSize.width, videoSize.height / imageSize.height)
                            let newSize = CGSize(width: imageSize.width * aspectRatio, height: imageSize.height * aspectRatio)
                            let x = (videoSize.width - newSize.width) / 2
                            let y = (videoSize.height - newSize.height) / 2
                            context?.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            
                            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                            
                            let presentationTime = CMTime(value: frameCount, timescale: fps)
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                            frameCount += 1
                            
                            if CMTimeCompare(presentationTime, imageDuration) >= 0 {
                                currentImageIndex = (currentImageIndex + 1) % imageURLs.count
                            }
                        } else {
                            appendSucceeded = false
                        }
                    }
                }
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                if writer.status == .completed {
                    completion(.success(outputURL))
                } else {
                    completion(.failure(writer.error ?? NSError(domain: "OverlayErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                }
            }
        }
    }


}
