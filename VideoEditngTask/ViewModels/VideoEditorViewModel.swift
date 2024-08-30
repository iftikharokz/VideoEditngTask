//
//  VideoEditorViewModel.swift
//  VideoEditngTask
//
//  Created by mac on 30/08/2024.
//

import AVKit

class VideoEditorViewModel: ObservableObject {
    @Published var url: URL?
    @Published var isProcessing = false
    @Published var playVideo = false
    
    private var mergeAudioFromVideo = MergeAudioFromVideo()
    private var addAudioVM = AddCustomAudioToVideo()
    private var createVideoFromImages = CreateVideoFromImages()
    
    func mergeVideos(sourceVideo: String, audioVideo: String) {
        let video1URL = getResourceURL(named: sourceVideo, withExtension: "mp4")
        let video2URL = getResourceURL(named: audioVideo, withExtension: "mp4")
        if let url1 = video1URL, let url2 = video2URL {
            DispatchQueue.global(qos: .background).async {
                self.mergeAudioFromVideo.mergeAudioFromVideo(sourceVideoURL: url1, audioVideoURL: url2) { result in
                    self.handleResult(result)
                }
            }
        }
    }
    
    func mergeAudioToVideo(audio: String, video: String) {
        let audioURL = getResourceURL(named: audio, withExtension: "mp3")
        let videoURL = getResourceURL(named: video, withExtension: "mp4")
        if let audioURL = audioURL, let videoURL = videoURL {
            DispatchQueue.global(qos: .background).async {
                self.addAudioVM.addMP3ToVideo(videoURL: videoURL, audioURL: audioURL) { result in
                    self.handleResult(result)
                }
            }
        }
    }
    
    func createAnimatedVideo() {
        let imageURLs = [
            getResourceURL(named: "image1", withExtension: "jpg")!,
            getResourceURL(named: "image2", withExtension: "jpg")!,
            getResourceURL(named: "image3", withExtension: "jpg")!
        ]
        DispatchQueue.global(qos: .background).async {
            self.createVideoFromImages.makeVideoOfUIImages(imageURLs: imageURLs) { result in
                self.handleResult(result)
            }
        }
    }
    
    private func handleResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            self.url = url
            self.playVideo = true
        case .failure(let error):
            print("Error: \(error.localizedDescription)")
        }
        self.isProcessing = false
    }
    
    private func getResourceURL(named name: String, withExtension ext: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: ext)
    }
}
