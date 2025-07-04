import SwiftUI

struct ActionButton<Style: ButtonStyle>: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let isLoading: Bool
    let style: Style
    
    init(
        icon: String,
        title: String,
        subtitle: String = "",
        isLoading: Bool = false,
        style: Style = Theme.PrimaryButtonStyle(),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isLoading = isLoading
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .opacity(0.8)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .opacity(0.5)
            }
        }
        .buttonStyle(style)
        .disabled(isLoading)
    }
}
