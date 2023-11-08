//  TextOverlayView.swift

import SwiftUI

struct TextOverlayView: View {
    var text: String

    var body: some View {
        // This will ensure the overlay is only as wide as the text plus padding
        Text(text)
            .foregroundColor(.white)
            .padding(5)
            .background(Color.black.opacity(0.5))
            .cornerRadius(5)
            // This padding ensures the text is at the bottom of the ZStack
            .padding([.bottom], 10)
            // This frame modifier with max width and alignment set to .center
            // ensures the text view is centered horizontally at the bottom
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// Preview for SwiftUI Canvas
struct TextOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a sample string to preview the TextOverlayView
        TextOverlayView(text: "Sample Text")
            .previewLayout(.sizeThatFits) // This makes the preview layout only as big as the view requires
            .padding() // Add some padding around the preview for better visibility
            .background(Color.red) // Give a background color to contrast the text overlay
    }
}
