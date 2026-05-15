import SwiftUI
import WidgetKit

@main
@available(iOS 16.2, *)
struct KaivaWidgetBundle: WidgetBundle {
    var body: some Widget {
        KaivaLiveActivityWidget()
    }
}
