import Library
import Models
import Library
import Foundation
import Library
import ReactiveCocoa
import Result

internal protocol ActivityFriendBackingViewModelInputs {
  func activity(activity: Activity)
}

internal protocol ActivityFriendBackingViewModelOutputs {
  var friendImageURL: Signal<NSURL?, NoError> { get }
  var friendTitle: Signal<String, NoError> { get }
  var projectName: Signal<String, NoError> { get }
  var creatorName: Signal<String, NoError> { get }
  var projectImageURL: Signal<NSURL?, NoError> { get }
}

internal protocol ActivityFriendBackingViewModelType {
  var inputs: ActivityFriendBackingViewModelInputs { get }
  var outputs: ActivityFriendBackingViewModelOutputs { get }
}

internal final class ActivityFriendBackingViewModel: ActivityFriendBackingViewModelType,
ActivityFriendBackingViewModelInputs, ActivityFriendBackingViewModelOutputs {

  internal init() {
    let activity = self.activityProperty.signal.ignoreNil()

    self.friendImageURL = activity
      .map { ($0.user?.avatar.medium).flatMap(NSURL.init) }


    self.friendTitle = activity
      .map { activity in
        guard let category = activity.project?.category else { return "" }

        return localizedString(
          key: "activity.friend_backed_\(localizedSlug(forCategory: category))_project",
          defaultValue: "%{friend_name} backed a %{category} project.",
          substitutions: [
            "friend_name": activity.user?.name ?? "",
            "category": activity.project?.category.root?.name ?? ""
          ]
        )
    }

    self.projectName = activity.map { $0.project?.name ?? "" }

    self.projectImageURL = activity.map { ($0.project?.photo.med).flatMap(NSURL.init) }

    self.creatorName = activity.map { $0.project?.creator.name ?? "" }
  }

  private let activityProperty = MutableProperty<Activity?>(nil)
  internal func activity(activity: Activity) {
    self.activityProperty.value = activity
  }

  internal let friendImageURL: Signal<NSURL?, NoError>
  internal let friendTitle: Signal<String, NoError>
  internal let projectName: Signal<String, NoError>
  internal let projectImageURL: Signal<NSURL?, NoError>
  internal let creatorName: Signal<String, NoError>

  internal var inputs: ActivityFriendBackingViewModelInputs { return self }
  internal var outputs: ActivityFriendBackingViewModelOutputs { return self }
}

// swiftlint:disable cyclomatic_complexity
private func localizedSlug(forCategory category: Models.Category) -> String {
  switch category.rootId ?? 0 {
  case 1:
    return "art"
  case 3:
    return "comics"
  case 6:
    return "crafts"
  case 7:
    return "dance"
  case 9:
    return "design"
  case 11:
    return "fashion"
  case 10:
    return "film"
  case 12:
    return "food"
  case 13:
    return "games"
  case 14:
    return "journalism"
  case 15:
    return "music"
  case 18:
    return "photography"
  case 16:
    return "publishing"
  case 17:
    return "tech"
  case 26:
    return "theater"
  default:
    return ""
  }
}
// swiftlint:enable cyclomatic_complexity
