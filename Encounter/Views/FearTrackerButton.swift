//
//  FearTrackerButton.swift
//  Encounter
//
//  Toolbar button showing the current Fear pool (flame icon + count).
//  Tapping opens a compact popover with +1 / −1 / −2 / −3 controls.
//

import DHKit
import DHModels
import SwiftUI

struct FearTrackerButton: View {
  let session: EncounterSession
  @State private var showPopover = false
  @State private var customFearText = ""

  var body: some View {
    Button {
      showPopover.toggle()
    } label: {
      Label("\(session.fearPool)", systemImage: "flame.fill")
        .monospacedDigit()
    }
    .tint(.orange)
    .accessibilityIdentifier("runner.fear-tracker")
    .popover(isPresented: $showPopover) {
      VStack(spacing: 12) {
        Text("Fear")
          .font(.headline)
        Text("\(session.fearPool)")
          .font(.largeTitle)
          .fontWeight(.bold)
          .monospacedDigit()
          .foregroundStyle(.orange)
        HStack(spacing: 8) {
          Button("+1") { session.incrementFear(by: 1) }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("runner.fear.increment")
          Button("−1") { session.spendFear(by: 1) }
            .buttonStyle(.bordered)
            .disabled(session.fearPool < 1)
            .accessibilityIdentifier("runner.fear.spend-1")
          Button("−2") { session.spendFear(by: 2) }
            .buttonStyle(.bordered)
            .disabled(session.fearPool < 2)
            .accessibilityIdentifier("runner.fear.spend-2")
          Button("−3") { session.spendFear(by: 3) }
            .buttonStyle(.bordered)
            .disabled(session.fearPool < 3)
            .accessibilityIdentifier("runner.fear.spend-3")
        }

        Divider()

        HStack(spacing: 8) {
          TextField("Set to…", text: $customFearText)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
              .keyboardType(.numberPad)
            #endif
            .frame(width: 80)
            .accessibilityIdentifier("runner.fear.custom-field")
            .onSubmit { commitCustomFear() }
          Button("Set") { commitCustomFear() }
            .buttonStyle(.bordered)
            .disabled(Int(customFearText) == nil)
            .accessibilityIdentifier("runner.fear.custom-set")
        }
      }
      .padding()
      .frame(minWidth: 180)
      .presentationCompactAdaptation(.popover)
    }
  }

  private func commitCustomFear() {
    guard let value = Int(customFearText), value >= 0 else { return }
    session.fearPool = value
    customFearText = ""
  }
}

#Preview {
  let compendium = Compendium()
  let session = EncounterSession(name: "Test", fearPool: 3)
  return NavigationStack {
    Text("Runner")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          FearTrackerButton(session: session)
        }
      }
  }
  .environment(compendium)
}
