//
//  LoadingView.swift
//  VideoEditngTask
//
//  Created by mac on 30/08/2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack{
                Text("Loading...")
                    .foregroundColor(.black)
                    .font(.largeTitle)
                    .padding(.bottom,10)
                Text("It may take some time.")
                    .foregroundColor(.black)
                    .font(.subheadline)
                    .padding(.bottom,40)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.green))
                    .scaleEffect(3)
            }
            .frame(width:UIScreen.main.bounds.width*0.6 ,height: UIScreen.main.bounds.height*0.4)
            .background(Color.white)
            .cornerRadius(30)
           
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}

#Preview {
    LoadingView()
}
