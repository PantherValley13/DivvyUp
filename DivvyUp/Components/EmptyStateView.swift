import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.spacing * 2)
                    .padding(.vertical, Theme.spacing)
                    .background(Theme.primary)
                    .cornerRadius(Theme.cornerRadius)
            }
        }
        .padding(Theme.spacing * 2)
        .frame(maxWidth: .infinity)
        .background(Theme.secondary)
        .cornerRadius(Theme.cornerRadius)
    }
} 