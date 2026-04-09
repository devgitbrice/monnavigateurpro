import SwiftUI

struct TodoResizableDivider: View {
    @Binding var width: CGFloat
    @State private var isHovering = false
    @State private var isDragging = false

    private let minWidth: CGFloat = 200
    private let maxWidth: CGFloat = 600
    private let handleWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.platformSeparator)
                .frame(width: 1)

            Rectangle()
                .fill(Color.clear)
                .frame(width: handleWidth)
                .contentShape(Rectangle())
                #if os(macOS)
                .onHover { hovering in
                    isHovering = hovering
                    if hovering || isDragging {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                #endif
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            isDragging = true
                            let newWidth = width - value.translation.width
                            width = min(max(newWidth, minWidth), maxWidth)
                        }
                        .onEnded { _ in
                            isDragging = false
                            #if os(macOS)
                            if !isHovering {
                                NSCursor.pop()
                            }
                            #endif
                        }
                )

            if isHovering || isDragging {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(isDragging ? 0.7 : 0.4))
                    .frame(width: 4, height: 40)
                    .overlay(
                        VStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(.white.opacity(0.8))
                                    .frame(width: 2.5, height: 2.5)
                            }
                        }
                    )
            }
        }
        .frame(width: handleWidth)
    }
}
