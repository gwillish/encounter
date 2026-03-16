//
//  ContentView.swift
//  Encounter
//
//  Created by Joe Heck on 3/14/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            EncounterLibraryView()
        } detail: {
            Text("Select an encounter")
                .foregroundStyle(.secondary)
        }
        #else
        NavigationStack {
            EncounterLibraryView()
        }
        #endif
    }
}

#Preview {
    ContentView()
        .environment(EncounterStore(directory: .temporaryDirectory))
}
