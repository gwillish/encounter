import DHModels

extension Condition {
  var sfSymbol: String {
    switch self {
    case .hidden: return "eye.slash.fill"
    case .restrained: return "link.circle.fill"
    case .vulnerable: return "shield.slash.fill"
    case .custom: return "questionmark.circle.fill"
    }
  }
}
