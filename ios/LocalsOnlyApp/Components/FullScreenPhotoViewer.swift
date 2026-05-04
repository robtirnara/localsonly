import SwiftUI

struct FullScreenPhotoViewer: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(max(0.3, 1.0 - Double(abs(dragOffset.height)) / 400.0))

            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(y: dragOffset.height)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in scale = value }
                                    .onEnded { _ in
                                        withAnimation { scale = max(1.0, min(scale, 3.0)) }
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale <= 1.0 {
                                            dragOffset = value.translation
                                        }
                                    }
                                    .onEnded { value in
                                        if abs(value.translation.height) > 100 {
                                            dismiss()
                                        } else {
                                            withAnimation(.spring(response: 0.3)) {
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                            )
                    default:
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
            }
        }
        .statusBarHidden()
    }
}
