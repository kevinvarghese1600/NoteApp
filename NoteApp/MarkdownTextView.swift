import SwiftUI
import UIKit

struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        DispatchQueue.main.async {
            textView.becomeFirstResponder()
        }
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        context.coordinator.format(textView: uiView)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextView
        private var workItem: DispatchWorkItem?

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            scheduleFormatting(textView)
        }

        private func scheduleFormatting(_ textView: UITextView) {
            workItem?.cancel()
            let item = DispatchWorkItem { [weak textView] in
                guard let tv = textView else { return }
                let formatted = MarkdownParser.parse(tv.text)
                DispatchQueue.main.async {
                    let selected = tv.selectedRange
                    tv.attributedText = formatted
                    tv.selectedRange = selected
                }
            }
            workItem = item
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1, execute: item)
        }

        func format(textView: UITextView) {
            let formatted = MarkdownParser.parse(textView.text)
            textView.attributedText = formatted
        }
    }
}
