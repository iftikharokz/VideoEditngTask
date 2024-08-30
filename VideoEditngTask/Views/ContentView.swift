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
//    let vv = VideoComposer()
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
            }
            .padding()
            if viewModel.isProcessing {
                LoadingView()
            }
        }
        .navigationTitle("Video Editor")
    }
}
