import UIKit

final class ReviewsViewController: UIViewController {
    
    private lazy var reviewsView = makeReviewsView()
    private var viewModel: ReviewsViewModel
    
    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
        
    }
    
    func updateViewModel() {
        viewModel.getReviews()
    }
    
}

// MARK: - Private

private extension ReviewsViewController {
    
    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        addPullRefresh(tableView: reviewsView.tableView)
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        return reviewsView
    }
    
    func addPullRefresh(tableView: UITableView) {
        let pullRefresh = UIRefreshControl()
        pullRefresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = pullRefresh
    }
    
    func setupViewModel() {
        viewModel.onStateChange = { [weak reviewsView] _ in
            reviewsView?.tableView.reloadData()
        }
    }
    
    @objc private func refreshData(_ sender: UIRefreshControl) {
        updateViewModel()
        sender.endRefreshing()
        
    }
}
