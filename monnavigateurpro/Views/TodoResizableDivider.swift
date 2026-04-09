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
            // Visible divider line
            Rectangle()
                .fill(Color(.separatorColor))
                .frame(width: 1)

            // Drag handle (wider invisible hit area)
            Rectangle()
                .fill(Color.clear)
                .frame(width: handleWidth)
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHovering = hovering
                    if hovering || isDragging {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            isDragging = true
                            // Dragging left = increase width, dragging right = decrease
                            let newWidth = width - value.translation.width
                            width = min(max(newWidth, minWidth), maxWidth)
                        }
                        .onEnded { _ in
                            isDragging = false
                            if !isHovering {
                                NSCursor.pop()
                            }
                        }
                )

            // Visual grip indicator on hover/drag
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
