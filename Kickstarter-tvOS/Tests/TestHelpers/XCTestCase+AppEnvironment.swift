import XCTest
@testable import Kickstarter_tvOS
import AVFoundation
import class Foundation.NSLocale
import class Foundation.NSTimeZone
import protocol Library.HockeyManagerType
import protocol KsApi.ServiceType
import protocol ReactiveCocoa.DateSchedulerType
import struct Library.Environment
import struct Library.AppEnvironment
import protocol Library.CurrentUserType
import enum Library.Language
import struct Library.LaunchedCountries
import protocol Library.NSBundleType
import protocol Library.AssetImageGeneratorType

extension XCTestCase {

  /**
   Pushes an environment onto the stack, executes a closure, and then pops the environment from the stack.
  */
  func withEnvironment(env: Environment, @noescape body: () -> ()) {
    AppEnvironment.pushEnvironment(env)
    body()
    AppEnvironment.popEnvironment()
  }

  /**
   Pushes an environment onto the stack, executes a closure, and then pops the environment from the stack.
   */
  func withEnvironment(
    apiService apiService: ServiceType = AppEnvironment.current.apiService,
    currentUser: CurrentUserType = AppEnvironment.current.currentUser,
    language: Language = AppEnvironment.current.language,
    locale: NSLocale = AppEnvironment.current.locale,
    timeZone: NSTimeZone = AppEnvironment.current.timeZone,
    countryCode: String = AppEnvironment.current.countryCode,
    launchedCountries: LaunchedCountries = AppEnvironment.current.launchedCountries,
    debounceScheduler: DateSchedulerType = AppEnvironment.current.debounceScheduler,
    mainBundle: NSBundleType = AppEnvironment.current.mainBundle,
    assetImageGeneratorType: AssetImageGeneratorType.Type = AppEnvironment.current.assetImageGeneratorType,
    hockeyManager: HockeyManagerType = AppEnvironment.current.hockeyManager,
    @noescape body: () -> ()) {

      withEnvironment(
        Environment(
          apiService: apiService,
          currentUser: currentUser,
          language: language,
          locale: locale,
          timeZone: timeZone,
          countryCode: countryCode,
          launchedCountries: launchedCountries,
          debounceScheduler: debounceScheduler,
          mainBundle: mainBundle,
          assetImageGeneratorType: assetImageGeneratorType,
          hockeyManager: hockeyManager
        ),
        body: body
      )
  }
}
