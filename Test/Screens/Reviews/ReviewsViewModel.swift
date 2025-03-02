import UIKit

enum ReviewsCellType {
    case review(TableCellConfig)
    case numberOfReviews(Int)
    
    var reuseId: String {
        switch self {
        case .review(let config):
            return config.reuseId
        case .numberOfReviews:
            return "number_of_reviews"
        }
    }
}
/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {
    
    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    
    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder
    private var cellTypes: [ReviewsCellType] = []
    
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
        cellTypes = self.state.items.map { .review($0) }
        cellTypes.append(.numberOfReviews(state.items.count))
    }
    
    func updateCellTypes() {
        cellTypes = state.items.map { .review($0) }
        cellTypes.append(.numberOfReviews(state.items.count))
    }
}

// MARK: - Internal

extension ReviewsViewModel {
    
    typealias State = ReviewsViewModelState
    
    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }
    
}

// MARK: - Private

private extension ReviewsViewModel {
    
    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            state.items += reviews.items.map(makeReviewItem)
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count
            
        } catch {
            state.shouldLoad = true
        }
        
        updateCellTypes()
        onStateChange?(state)
    }
    
    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        
        updateCellTypes()
        onStateChange?(state)
    }
}

// MARK: - Items

private extension ReviewsViewModel {
    
    typealias ReviewItem = ReviewCellConfig
    
    func makeReviewItem(_ review: Review) -> ReviewItem {
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let fullNameString = (review.first_name + " " + review.last_name)
        let fullName = fullNameString.attributed(font: .boldSystemFont(ofSize: 15))
        let ratingImage = RatingRenderer().ratingImage(review.rating)
        let avatarImage = UIImage(named: "l5w5aIHioYc")
        let avatarUrl = review.avatar_url
        var photoImages = review.photos
        
        
        
        let item = ReviewItem(
            reviewText: reviewText,
            created: created, fullName: fullName, ratingImage: ratingImage, avatarImage: avatarImage, avatarUrl: avatarUrl, photoNames: photoImages) { [weak self] id in
                guard let self = self else { return }
                self.showMoreReview(with: id)
            }
        
        
        return item
    }
    
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellType = cellTypes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType.reuseId, for: indexPath)
        
        switch cellType {
        case .review(let config):
            config.update(cell: cell)
        case .numberOfReviews(let count):
            cell.textLabel?.text = String(count) + " отзывов"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.attributedText = cell.textLabel?.text?.attributed(font: .numberOfReviews, color: .numberOfReviews)
        }
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellType = cellTypes[indexPath.row]
        switch cellType {
        case .review(let config):
            return config.height(with: tableView.bounds.size)
        case .numberOfReviews:
            return 40
        }
    }
    
    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }
    
    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }
    
}
