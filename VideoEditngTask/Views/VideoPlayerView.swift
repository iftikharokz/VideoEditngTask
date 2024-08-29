//
//  VideoPlayerView.swift
//  VideoEditngTask
//
//  Created by mac on 30/08/2024.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}

#Preview {
    VideoPlayerView(videoURL: URL(string: "https://www.google.com/")!)
}
