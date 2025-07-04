import SwiftUI

struct ContentCard<Content: View>: View {
    let title: String
    let icon: String?
    let showDivider: Bool
    let content: Content
    
    init(
        title: String,
        icon: String? = nil,
        showDivider: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.showDivider = showDivider
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(Theme.primary)
                }
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            if showDivider {
                Divider()
            }
            
            content
        }
        .cardStyle()
        .transition(.scale.combined(with: .opacity))
    }
}

// Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String = "",
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if let action = action, !actionTitle.isEmpty {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(Theme.SecondaryButtonStyle())
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.secondary)
        .cornerRadius(Theme.cornerRadius)
    }
} 