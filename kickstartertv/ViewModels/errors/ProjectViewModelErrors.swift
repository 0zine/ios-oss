import ReactiveCocoa

internal protocol ProjectViewModelErrors {
  /// Emits when user tries to save without being logged in.
  var savingRequiresLogin: Signal<(), NoError> { get }
}
