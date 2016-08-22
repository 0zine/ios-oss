import KsApi
import Library
import Prelude
import UIKit

internal final class UpdateViewController: WebViewController {
  private let viewModel: UpdateViewModelType = UpdateViewModel()
  private let shareViewModel: ShareViewModelType = ShareViewModel()

  internal static func configuredWith(project project: Project, update: Update) -> UpdateViewController {
    let vc = Storyboard.Update.instantiate(UpdateViewController)
    vc.viewModel.inputs.configureWith(project: project, update: update)
    vc.shareViewModel.inputs.configureWith(shareContext: .update(project, update))
    return vc
  }

  internal override func viewDidLoad() {
    super.viewDidLoad()
    self.viewModel.inputs.viewDidLoad()
  }

  internal override func bindStyles() {
    self |> baseControllerStyle()
  }

  internal override func bindViewModel() {
    self.navigationItem.rac.title = self.viewModel.outputs.title

    self.viewModel.outputs.webViewLoadRequest
      .observeForControllerAction()
      .observeNext { [weak self] in self?.webView.loadRequest($0) }

    self.viewModel.outputs.goToComments
      .observeForControllerAction()
      .observeNext { [weak self] in self?.goToComments(forUpdate: $0) }

    self.viewModel.outputs.goToProject
      .observeForControllerAction()
      .observeNext { [weak self] in self?.goTo(project: $0, refTag: $1) }

    self.shareViewModel.outputs.showShareSheet
      .observeForControllerAction()
      .observeNext { [weak self] in self?.showShareSheet($0) }
  }

  internal func webView(webView: WKWebView,
                        decidePolicyForNavigationAction navigationAction: WKNavigationAction,
                        decisionHandler: (WKNavigationActionPolicy) -> Void) {

    decisionHandler(self.viewModel.inputs.decidePolicyFor(navigationAction: navigationAction))
  }

  private func goToComments(forUpdate update: Update) {
    let vc = CommentsViewController.configuredWith(update: update)
    self.navigationController?.pushViewController(vc, animated: true)
  }

  private func goTo(project project: Project, refTag: RefTag?) {
    let vc = ProjectMagazineViewController.configuredWith(projectOrParam: .left(project), refTag: refTag)
    let nav = UINavigationController(rootViewController: vc)
    self.presentViewController(nav, animated: true, completion: nil)
  }

  private func showShareSheet(activityController: UIActivityViewController) {

    activityController.completionWithItemsHandler = { [weak self] in
      self?.shareViewModel.inputs.shareActivityCompletion(activityType: $0,
                                                          completed: $1,
                                                          returnedItems: $2,
                                                          activityError: $3)
    }

    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      activityController.modalPresentationStyle = .Popover
      let popover = activityController.popoverPresentationController
      popover?.permittedArrowDirections = .Any
      popover?.barButtonItem = self.navigationItem.rightBarButtonItem
    }

    self.presentViewController(activityController, animated: true, completion: nil)
  }

  @IBAction private func shareButtonTapped() {
    self.shareViewModel.inputs.shareButtonTapped()
  }
}
