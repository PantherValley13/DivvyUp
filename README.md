# DivvyUp - Smart Bill Splitting App

DivvyUp is an iOS app that makes splitting bills with friends easy and accurate. Using advanced receipt scanning technology and an intuitive interface, DivvyUp helps you fairly divide expenses among participants.

## Features

- 📸 **Smart Receipt Scanning**: Quickly scan receipts using your device's camera with VisionKit integration
- 🔍 **Intelligent Text Recognition**: Automatically extracts items and prices from scanned receipts
- 👥 **Easy Item Assignment**: Drag and drop interface for assigning items to participants
- 💰 **Tax & Tip Handling**: Automatically calculates and splits tax and tip proportionally
- 🎨 **Modern UI/UX**: Beautiful, intuitive interface with smooth animations and gestures
- 📊 **Real-time Calculations**: Instantly see how costs are split as you make assignments

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository:

```bash
git clone https://github.com/YourUsername/DivvyUp.git
```

2. Open `DivvyUp.xcodeproj` in Xcode

3. Build and run the project

## Usage

1. **Scan Receipt**

   - Launch DivvyUp
   - Tap "Scan Receipt"
   - Point your camera at the receipt
   - Confirm the scan

2. **Add Participants**

   - Tap "Split Bill"
   - Use the "+" button to add participants
   - Choose names and colors for each participant

3. **Assign Items**

   - Drag items from the unassigned section to participants
   - Items can be reassigned by dragging to different participants
   - Tap an assigned item to unassign it

4. **Add Tax & Tip**

   - Tap "Add Tax & Tip"
   - Enter tax percentage
   - Enter tip percentage
   - View the updated total and per-person amounts

5. **Review & Share**
   - Review the final split on the summary screen
   - Each person's total includes their share of tax and tip
   - Start over for a new bill by tapping "Start Over"

## Architecture

DivvyUp follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: `Bill`, `BillItem`, `Participant`
- **Views**: `BillScannerView`, `ItemAssignmentView`, `ContentCard`, `EmptyStateView`
- **ViewModels**: `BillViewModel`

Key technologies used:

- SwiftUI for the user interface
- VisionKit for receipt scanning
- Combine for reactive programming

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple's VisionKit for text recognition
- SwiftUI for the modern UI framework
- The open-source community for inspiration and best practices
