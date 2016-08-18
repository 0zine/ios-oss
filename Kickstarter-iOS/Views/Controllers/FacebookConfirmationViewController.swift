import Foundation
import UIKit
import ReactiveExtensions
import ReactiveCocoa
import Library
import Prelude
import FBSDKCoreKit
import MessageUI

internal final class FacebookConfirmationViewController: UIViewController,
  MFMailComposeViewControllerDelegate {
  @IBOutlet weak var confirmationLabel: UILabel!
  @IBOutlet weak var createAccountButton: UIButton!
  @IBOutlet weak var emailLabel: UILabel!
  @IBOutlet weak var helpButton: UIButton!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var loginLabel: UILabel!
  @IBOutlet weak var newsletterLabel: UILabel!
  @IBOutlet weak var newsletterSwitch: UISwitch!

  private let viewModel: FacebookConfirmationViewModelType = FacebookConfirmationViewModel()
  private let helpViewModel = HelpViewModel()

  internal static func configuredWith(facebookUserEmail email: String, facebookAccessToken token: String)
    -> FacebookConfirmationViewController {

      let vc = Storyboard.Login.instantiate(FacebookConfirmationViewController)
      vc.viewModel.inputs.email(email)
      vc.viewModel.inputs.facebookToken(token)
      vc.helpViewModel.inputs.configureWith(helpContext: .facebookConfirmation)
      vc.helpViewModel.inputs.canSendEmail(MFMailComposeViewController.canSendMail())
      return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.viewModel.inputs.viewDidLoad()
  }

  override func bindStyles() {
    self |> baseControllerStyle()

    self.confirmationLabel |> fbConfirmationMessageLabelStyle
    self.createAccountButton |> createNewAccountButtonStyle
    self.emailLabel |> fbConfirmEmailLabelStyle
    self.helpButton |> disclaimerButtonStyle
    self.loginButton |> loginWithEmailButtonStyle
    self.loginLabel |> fbWrongAccountLabelStyle
    self.newsletterLabel |> newsletterLabelStyle
  }

  override func bindViewModel() {
    self.viewModel.outputs.displayEmail
      .observeForUI()
      .observeNext { [weak self] email in
        self?.emailLabel.text = email
    }

    self.viewModel.outputs.sendNewsletters
      .observeForUI()
      .observeNext { [weak self] send in self?.newsletterSwitch.setOn(send, animated: false)
    }

    self.viewModel.outputs.showLogin
      .observeForUI()
      .observeNext { [weak self] _ in self?.goToLoginViewController()
    }

    self.viewModel.outputs.logIntoEnvironment
      .observeNext { [weak self] env in
        AppEnvironment.login(env)
        self?.viewModel.inputs.environmentLoggedIn()
    }

    self.viewModel.outputs.postNotification
      .observeNext { note in
        NSNotificationCenter.defaultCenter().postNotification(note)
    }

    self.viewModel.errors.showSignupError
      .observeForUI()
      .observeNext { [weak self] message in
        self?.presentViewController(UIAlertController.genericError(message), animated: true, completion: nil)
    }

    self.helpViewModel.outputs.showHelpSheet
      .observeForUI()
      .observeNext { [weak self] in
        self?.showHelpSheet(helpTypes: $0)
    }

    self.helpViewModel.outputs.showMailCompose
      .observeForUI()
      .observeNext { [weak self] in
        guard let _self = self else { return }
        let controller = MFMailComposeViewController.support()
        controller.mailComposeDelegate = _self
        _self.presentViewController(controller, animated: true, completion: nil)
    }

    self.helpViewModel.outputs.showNoEmailError
      .observeForUI()
      .observeNext { [weak self] alert in
        self?.presentViewController(alert, animated: true, completion: nil)
    }

    self.helpViewModel.outputs.showWebHelp
      .observeForUI()
      .observeNext { [weak self] helpType in
        self?.goToHelpType(helpType)
    }
  }

  @objc internal func mailComposeController(controller: MFMailComposeViewController,
                                            didFinishWithResult result: MFMailComposeResult,
                                                                error: NSError?) {
    self.helpViewModel.inputs.mailComposeCompletion(result: result)
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  private func goToHelpType(helpType: HelpType) {
    let vc = HelpWebViewController.configuredWith(helpType: helpType)
    self.navigationController?.pushViewController(vc, animated: true)
  }

  private func goToLoginViewController() {
    self.navigationController?.pushViewController(LoginViewController.instantiate(), animated: true)
  }

  private func showHelpSheet(helpTypes helpTypes: [HelpType]) {
    let helpSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

    helpTypes.forEach { helpType in
      helpSheet.addAction(UIAlertAction(title: helpType.title, style: .Default, handler: {
        [weak helpVM = self.helpViewModel] _ in
        helpVM?.inputs.helpTypeButtonTapped(helpType)
      }))
    }

    helpSheet.addAction(UIAlertAction(title: Strings.login_tout_help_sheet_cancel(),
      style: .Cancel,
      handler: { [weak helpVM = self.helpViewModel] _ in
        helpVM?.inputs.cancelHelpSheetButtonTapped()
      }))

    //iPad provision
    helpSheet.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem

    self.presentViewController(helpSheet, animated: true, completion: nil)
  }

  @IBAction private func newsletterSwitchChanged(sender: UISwitch) {
    self.viewModel.inputs.sendNewslettersToggled(sender.on)
  }

  @IBAction private func createAccountButtonPressed(sender: AnyObject) {
    self.viewModel.inputs.createAccountButtonPressed()
  }

  @IBAction private func loginButtonPressed(sender: BorderButton) {
    self.viewModel.inputs.loginButtonPressed()
  }

  @objc private func helpButtonPressed(sender: AnyObject) {
    self.helpViewModel.inputs.showHelpSheetButtonTapped()
  }
}
