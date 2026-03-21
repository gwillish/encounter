//
//  FeatureSectionsView.swift
//  Encounter
//
//  Renders adversary features grouped by type (Passives, Actions, Reactions)
//  as List sections. Used by AdversaryDetailView and EnvironmentDetailView.
//

import SwiftUI

/// Renders a list of adversary features as grouped `Section` rows.
///
/// Sections are shown only if at least one feature of that type exists.
/// Intended for use inside a `List`.
struct FeatureSectionsView: View {
    let features: [AdversaryFeature]

    var body: some View {
        let passives  = features.filter { $0.featType == .passive }
        let actions   = features.filter { $0.featType == .action }
        let reactions = features.filter { $0.featType == .reaction }

        if !passives.isEmpty {
            Section("Passives") {
                ForEach(passives) { AdversaryFeatureRow(feature: $0) }
            }
        }
        if !actions.isEmpty {
            Section("Actions") {
                ForEach(actions) { AdversaryFeatureRow(feature: $0) }
            }
        }
        if !reactions.isEmpty {
            Section("Reactions") {
                ForEach(reactions) { AdversaryFeatureRow(feature: $0) }
            }
        }
    }
}
