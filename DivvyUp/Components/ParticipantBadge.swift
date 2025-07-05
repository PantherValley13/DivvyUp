import SwiftUI

struct ParticipantBadge: View {
    let participant: Participant
    var size: CGFloat = 32
    
    var body: some View {
        Circle()
            .fill(participant.color)
            .frame(width: size, height: size)
            .overlay(
                Text(participant.name.prefix(1).uppercased())
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.4, weight: .medium))
            )
            .shadow(color: participant.color.opacity(0.3), radius: 3, x: 0, y: 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: participant.id)
    }
}

#Preview {
    HStack {
        ParticipantBadge(
            participant: Participant(name: "John", colorName: "blue")
        )
        
        ParticipantBadge(
            participant: Participant(name: "Sarah", colorName: "red"),
            size: 48
        )
        
        ParticipantBadge(
            participant: Participant(name: "Mike", colorName: "green"),
            size: 24
        )
    }
    .padding()
} 