import DHModels
import Foundation

extension [Adversary] {
  // Stateless AND-predicate: each non-nil/non-empty argument narrows the result.
  // Parent views own the filter state and call this to derive the displayed list.
  nonisolated func filtered(searchText: String, tier: Int?, type: AdversaryType?) -> [Adversary] {
    filter { adversary in
      let matchesSearch =
        searchText.isEmpty
        || adversary.name.localizedStandardContains(searchText)
      let matchesTier = tier == nil || adversary.tier == tier
      let matchesType = type == nil || adversary.role == type
      return matchesSearch && matchesTier && matchesType
    }
  }
}
