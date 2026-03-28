//
//  AboutView.swift
//  Encounter
//

import SwiftUI

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
  }

  private var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 4) {
            Text("Encounter")
              .font(.headline)
            Text("Version \(appVersion) (\(buildNumber))")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }

        Section("Attribution") {
          Text(
            "This product includes materials from the Daggerheart System Reference Document 1.0, © Critical Role, LLC. under the terms of the Darrington Press Community Gaming (DPCGL) License."
          )
          .font(.footnote)

          Link(
            "More information at daggerheart.com",
            destination: URL(string: "https://www.daggerheart.com")!
          )
          .font(.footnote)

          Link(
            "DPCGL license text at darringtonpress.com/license",
            destination: URL(string: "https://darringtonpress.com/license/")!
          )
          .font(.footnote)
        }

        Section("Disclaimer") {
          Text(
            "This app is not affiliated with, endorsed by, or sponsored by Darrington Press, LLC or Critical Role, LLC. Daggerheart is a trademark of Critical Role, LLC."
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("About")
      #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
          }
        }
      #endif
    }
  }
}

#Preview {
  AboutView()
}
