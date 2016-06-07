import ReactiveCocoa
import KsApi
import Result
import Prelude

public protocol CommentDialogViewModelInputs {
  /// Call when the view appears.
  func viewWillAppear()

  /// Call when the view disappears.
  func viewWillDisappear()

  /// Call with the project given to the view.
  func project(project: Project, update: Update?)

  /// Call when the comment body text changes.
  func commentBodyChanged(text: String)

  /// Call when the post comment button is pressed.
  func postButtonPressed()

  /// Call when the cancel button is pressed.
  func cancelButtonPressed()
}

public protocol CommentDialogViewModelOutputs {
  /// Emits a boolean that determines if the post button is enabled.
  var postButtonEnabled: Signal<Bool, NoError> { get }

  /// Emits a boolean that determines if the comment is currently posting.
  var loadingViewIsHidden: Signal<Bool, NoError> { get }

  /// Emits the newly posted comment when the present of this dialog should be notified that posting
  /// was successful.
  var notifyPresenterCommentWasPostedSuccesfully: Signal<Comment, NoError> { get }

  /// Emits when the dialog should notify its presenter that it wants to be dismissed.
  var notifyPresenterDialogWantsDismissal: Signal<(), NoError> { get }

  /// Emits the string to be used as the subtitle of the comment dialog.
  var subtitle: Signal<String, NoError> { get }

  /// Emits a boolean that determines if the keyboard should be shown or not.
  var showKeyboard: Signal<Bool, NoError> { get }
}

public protocol CommentDialogViewModelErrors {
  /// Emits a string error description when there has been an error posting a comment.
  var presentError: Signal<String, NoError> { get }
}

public protocol CommentDialogViewModelType {
  var inputs: CommentDialogViewModelInputs { get }
  var outputs: CommentDialogViewModelOutputs { get }
  var errors: CommentDialogViewModelErrors { get }
}

public final class CommentDialogViewModel: CommentDialogViewModelType, CommentDialogViewModelInputs,
CommentDialogViewModelOutputs, CommentDialogViewModelErrors {

  private let viewWillAppearProperty = MutableProperty(())
  public func viewWillAppear() {
    self.viewWillAppearProperty.value = ()
  }

  private let viewWillDisappearProperty = MutableProperty()
  public func viewWillDisappear() {
    self.viewWillDisappearProperty.value = ()
  }

  private let projectAndUpdateProperty = MutableProperty<(Project, Update?)?>(nil)
  public func project(project: Project, update: Update?) {
    self.projectAndUpdateProperty.value = (project, update)
  }

  private let commentBodyProperty = MutableProperty("")
  public func commentBodyChanged(text: String) {
    self.commentBodyProperty.value = text
  }

  private let postButtonPressedProperty = MutableProperty(())
  public func postButtonPressed() {
    self.postButtonPressedProperty.value = ()
  }

  private let cancelButtonPressedProperty = MutableProperty(())
  public func cancelButtonPressed() {
    self.cancelButtonPressedProperty.value = ()
  }

  public let postButtonEnabled: Signal<Bool, NoError>
  public let loadingViewIsHidden: Signal<Bool, NoError>
  public let notifyPresenterCommentWasPostedSuccesfully: Signal<Comment, NoError>
  public let notifyPresenterDialogWantsDismissal: Signal<(), NoError>
  public let subtitle: Signal<String, NoError>
  public let showKeyboard: Signal<Bool, NoError>

  public let presentError: Signal<String, NoError>

  public var inputs: CommentDialogViewModelInputs { return self }
  public var outputs: CommentDialogViewModelOutputs { return self }
  public var errors: CommentDialogViewModelErrors { return self }

  // swiftlint:disable function_body_length
  public init() {
    let isLoading = MutableProperty(false)

    let project = self.projectAndUpdateProperty.signal.ignoreNil()
      .map { project, _ in project }

    let updateOrProject = self.projectAndUpdateProperty.signal.ignoreNil()
      .map { project, update in
        return update.map(Either.left) ?? Either.right(project)
    }

    self.postButtonEnabled = Signal.merge([
      self.viewWillAppearProperty.signal.take(1).mapConst(false),
      self.commentBodyProperty.signal.map { !$0.isEmpty },
      isLoading.signal.map(isFalse)
      ])
      .skipRepeats()

    let commentPostedEvent = combineLatest(self.commentBodyProperty.signal, updateOrProject)
      .takeWhen(self.postButtonPressedProperty.signal)
      .switchMap { body, updateOrProject in
        postComment(body, toUpdateOrComment: updateOrProject)
          .on(
            started: {
              isLoading.value = true
            },
            terminated: {
              isLoading.value = false
          })
          .materialize()
      }

    self.notifyPresenterCommentWasPostedSuccesfully = commentPostedEvent.values()

    self.loadingViewIsHidden = Signal.merge(
      self.viewWillAppearProperty.signal.mapConst(true),
      isLoading.signal.map(negate)
    )

    self.notifyPresenterDialogWantsDismissal = Signal.merge([
      self.cancelButtonPressedProperty.signal,
      self.notifyPresenterCommentWasPostedSuccesfully.ignoreValues()
      ])

    self.presentError = commentPostedEvent.errors()
      .map { env in
        env.errorMessages.first ??
          localizedString(key: "comments.dialog.generic_error",
            defaultValue: "Sorry, your comment could not be posted.")
    }

    self.subtitle = project
      .takeWhen(self.viewWillAppearProperty.signal)
      .map { $0.name }

    self.showKeyboard = Signal.merge(
      self.viewWillAppearProperty.signal.mapConst(true),
      self.viewWillDisappearProperty.signal.mapConst(false)
    )

    self.projectAndUpdateProperty.signal.ignoreNil()
      .takePairWhen(self.notifyPresenterCommentWasPostedSuccesfully)
      .map { ($0.0, $0.1, $1) }
      .observeNext { project, update, comment in
        if let update = update {
          AppEnvironment.current.koala.trackCommentCreate(comment: comment, update: update, project: project)
        } else {
          AppEnvironment.current.koala.trackCommentCreate(comment: comment, project: project)
        }
    }
  }
  // swiftlint:enable function_body_length
}

private func postComment(body: String, toUpdateOrComment updateOrComment: Either<Update, Project>)
  -> SignalProducer<Comment, ErrorEnvelope> {

    switch updateOrComment {
    case let .left(update):
      return AppEnvironment.current.apiService.postComment(body, toUpdate: update)
    case let .right(project):
      return AppEnvironment.current.apiService.postComment(body, toProject: project)
    }
}
