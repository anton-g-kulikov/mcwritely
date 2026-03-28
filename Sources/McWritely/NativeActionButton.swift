import SwiftUI
import AppKit

struct NativeActionButton: NSViewRepresentable {
    let title: String
    let systemImageName: String?
    let isPrimary: Bool
    let minimumHeight: CGFloat
    let fontSize: CGFloat
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: title, target: context.coordinator, action: #selector(Coordinator.performAction))
        button.setButtonType(.momentaryPushIn)
        button.controlSize = .large
        button.image = buttonImage()
        button.imagePosition = .noImage
        button.alignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
        style(button)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.action = action
        button.title = title
        button.image = buttonImage()
        style(button)
    }

    private func buttonImage() -> NSImage? {
        guard let systemImageName, !systemImageName.isEmpty else { return nil }
        let configuration = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .semibold)
        let image = NSImage(
            systemSymbolName: systemImageName,
            accessibilityDescription: title
        )?.withSymbolConfiguration(configuration)
        image?.isTemplate = true
        return image
    }

    private func style(_ button: NSButton) {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let foreground: NSColor = isPrimary ? .white : .secondaryLabelColor
        let attrTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: font,
                .foregroundColor: foreground
            ]
        )
        button.attributedTitle = attrTitle
        button.contentTintColor = foreground

        if isPrimary {
            button.isBordered = false
            button.wantsLayer = true
            button.layer?.cornerRadius = 10
            button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        } else {
            button.isBordered = false
            button.wantsLayer = false
            button.layer?.backgroundColor = nil
        }
    }

    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func performAction() {
            action()
        }
    }
}
