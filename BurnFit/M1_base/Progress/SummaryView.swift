import SwiftUI

// STUB: verrà sostituito dal Membro 4
struct SummaryView: View {
    let summary: SessionSummary
    var onClose: () -> Void
    var body: some View { Button("Fine", action: onClose) }
}
