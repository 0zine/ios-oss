import XCTest
@testable import Kickstarter_iOS
@testable import ReactiveCocoa
@testable import ReactiveExtensions_TestHelpers
@testable import KsApi
@testable import KsApi_TestHelpers
@testable import Result
@testable import Library

final class ResetPasswordViewModelTests: TestCase {
  var vm: ResetPasswordViewModelType = ResetPasswordViewModel()

  let formIsValid = TestObserver<Bool, NoError>()
  let showResetSuccess = TestObserver<String, NoError>()
  let returnToLogin = TestObserver<(), NoError>()
  let showError = TestObserver<String, NoError>()
  let setEmailInitial = TestObserver<String, NoError>()

  override func setUp() {
    super.setUp()

    vm.outputs.formIsValid.observe(formIsValid.observer)
    vm.outputs.showResetSuccess.observe(showResetSuccess.observer)
    vm.outputs.returnToLogin.observe(returnToLogin.observer)
    vm.outputs.setEmailInitial.observe(setEmailInitial.observer)
    vm.errors.showError.observe(showError.observer)
  }

  func testViewWillAppear() {
    vm.inputs.viewWillAppear()

    XCTAssertEqual(["Forgot Password View"], trackingClient.events)
  }

  func testFormIsValid() {
    formIsValid.assertDidNotEmitValue("Form is valid did not emit any values")

    vm.inputs.viewDidLoad()

    formIsValid.assertDidNotEmitValue("Form is valid did not emit any values")

    vm.inputs.viewWillAppear()

    formIsValid.assertDidNotEmitValue("Form is valid did not emit any values")

    vm.inputs.emailChanged("bad")

    formIsValid.assertValues([false])

    vm.inputs.emailChanged("gina@kickstarter.com")

    formIsValid.assertValues([false, true])
  }

  func testFormIsValid_BeforeViewDidLoad() {
    formIsValid.assertDidNotEmitValue("Form is valid did not emit any values")

    vm.inputs.emailChanged("hello@goodemail.biz")

    formIsValid.assertValues([true])

    vm.inputs.viewDidLoad()

    formIsValid.assertValues([true])
  }

  func testEmailSetOnce_WithInitialValue() {
    vm.inputs.emailChanged("nativesquad@kickstarter.com")

    setEmailInitial.assertValueCount(0, "Initial email does not emit")

    vm.inputs.viewDidLoad()

    setEmailInitial.assertValues(["nativesquad@kickstarter.com"])

    vm.inputs.viewDidLoad()

    setEmailInitial.assertValues(["nativesquad@kickstarter.com"])
  }

  func testEmailNotSet_WithoutInitialValue() {
    setEmailInitial.assertValueCount(0, "Initial email does not emit")

    vm.inputs.viewDidLoad()
    vm.inputs.viewWillAppear()

    setEmailInitial.assertValueCount(0, "Initial email does not emit")

    vm.inputs.emailChanged("nativesquad@kickstarter.com")

    setEmailInitial.assertValueCount(0, "Initial email does not emit")
  }

  func testResetSuccess() {
    vm.inputs.viewWillAppear()
    vm.inputs.emailChanged("lisa@kickstarter.com")
    vm.inputs.resetButtonPressed()

    showResetSuccess.assertValues(["We've sent an email to lisa@kickstarter.com with instructions to reset your password."])
    XCTAssertEqual(["Forgot Password View", "Forgot Password Requested"], trackingClient.events)
  }

  func testResetConfirmation() {
    vm.inputs.viewWillAppear()
    vm.inputs.confirmResetButtonPressed()

    returnToLogin.assertValueCount(1, "Shows login after confirming message receipt")
  }

  func testResetFail_WithUnknownEmail() {
    let error = ErrorEnvelope(
      errorMessages: ["The resource you are looking for does not exist."],
      ksrCode: nil,
      httpCode: 404,
      exception: nil
    )

    withEnvironment(apiService: MockService(resetPasswordError: error)) {
      vm.inputs.viewWillAppear()
      vm.inputs.emailChanged("bad@email")
      vm.inputs.resetButtonPressed()

      showError.assertValues(["Sorry, we don't know that email address. Try again?"],
                             "Error alert is shown on bad request")
    }
  }

  func testResetFail_WithNon404Error() {
    let error = ErrorEnvelope(
      errorMessages: ["Zoinks!"],
      ksrCode: nil,
      httpCode: 400,
      exception: nil
    )

    withEnvironment(apiService: MockService(resetPasswordError: error)) {
      vm.inputs.viewWillAppear()
      vm.inputs.emailChanged("unicorns@sparkles.tv")
      vm.inputs.resetButtonPressed()

      showError.assertValues(["Something went wrong."], "Error alert is shown on bad request")
    }
  }
}
