//
//  CustomButtonView.swift
//  VideoEditngTask
//
//  Created by mac on 30/08/2024.
//

import SwiftUI

struct CustomButtonView: View {
    @EnvironmentObject var viewModel : VideoEditorViewModel
    let title : String
    let action: () -> Void
    var body: some View {
        Button(action: {
            viewModel.isProcessing = true
            action()
        }) {
            Text(title)
                .padding()
                .frame(width:UIScreen.main.bounds.width*0.75 ,height: 60)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
        }
    }
}
