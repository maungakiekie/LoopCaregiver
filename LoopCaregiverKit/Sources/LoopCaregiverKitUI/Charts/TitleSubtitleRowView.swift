//
//  TitleSubtitleRowView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 7/25/24.
//

import SwiftUI

public struct TitleSubtitleRowView: View {
    public let title: String
    public let subtitle: String
    
    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .bold()
                .font(.subheadline)
            Spacer()
            Text(subtitle)
                .foregroundColor(.gray)
                .bold()
                .font(.subheadline)
        }
    }
}

#Preview {
    TitleSubtitleRowView(title: "My Title", subtitle: "My Subtitle")
}
