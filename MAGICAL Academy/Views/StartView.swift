import SwiftUI

struct StartView: View {
    @Binding var selectedStage: Int

    // State for controlling the animation
    @State private var showFinalImage = false
    @State private var scale: CGFloat = 0.01
    @State private var rotationAngle: Double = 0.0

    var body: some View {
        ZStack {
            // Black background for initial animation
            if !showFinalImage {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .gesture(TapGesture().onEnded {
                        advanceStage()
                    })
            }

            // Final image that appears after animation
            if showFinalImage {
                GeometryReader { geometry in
                    Color.black // Add a black background for the final image
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            Image("Logo") // Replace with your image name
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .gesture(TapGesture().onEnded {
                                    advanceStage()
                                })
                        )
                }
            } else {
                // Wand image that scales up and rotates
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2)) {
                            scale = 1.0 // Scale up
                            rotationAngle = 360.0 // Rotate 360 degrees
                        }
                        // Use a timer to advance the stage after 10 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            advanceStage()
                        }
                    }
            }
        }
    }

    private func advanceStage() {
        withAnimation {
            selectedStage = 1 // Move to the next stage
        }
    }
}


struct ContentView: View {
    @State private var selectedStage: Int = 0

    var body: some View {
        StartView(selectedStage: $selectedStage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
