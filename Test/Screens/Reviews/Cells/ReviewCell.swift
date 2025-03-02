import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {
    
    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)
    
    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    
    let fullName: NSAttributedString
    let ratingImage: UIImage
    let avatarImage: UIImage?
    let avatarUrl: String
    let photoNames: [String]?
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    
    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()
    
}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {
    
    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.avatarImageView.loadImage(urlString: avatarUrl, placeholder: avatarImage)
        cell.nameLabel.attributedText = fullName
        cell.ratingImageView.image = ratingImage
        cell.config = self
        cell.photoImageViews.isEmpty ? cell.setupPhotos() : cell.updatePhotos()
        guard let photoNames = photoNames else { return }
        for index in 0..<photoNames.count {
            cell.photoImageViews[index].image = UIImage(named: photoNames[index])
        }
        
    }
    
    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
    
}

// MARK: - Private

private extension ReviewCellConfig {
    
    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)
    
}

// MARK: - Cell

final class ReviewCell: UITableViewCell {
    
    fileprivate var config: Config?
    
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let nameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let avatarImageView = UIImageView()
    fileprivate var photoImageViews = [UIImageView]()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        avatarImageView.frame = layout.avatarImageViewFrame
        ratingImageView.frame = layout.ratingImageViewFrame
        nameLabel.frame = layout.nameLabelFrame
        
        for (index, frame) in layout.photoImageViewsFrames.enumerated() {
            if index < photoImageViews.count {
                photoImageViews[index].frame = frame
            }
        }
    }
}

// MARK: - Private

private extension ReviewCell {
    
    func setupCell() {
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
        setupAvatar()
        setupRating()
        setupName()
    }
    
    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }
    
    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        showMoreButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
    }
    
    func setupAvatar() {
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = ReviewCellLayout.avatarCornerRadius
        contentView.addSubview(avatarImageView)
    }
    
    func setupRating() {
        contentView.addSubview(ratingImageView)
    }
    
    func setupName() {
        contentView.addSubview(nameLabel)
    }
    
    func setupPhotos() {
        guard let config = config else { return }
        
        if let photoNames = config.photoNames {
            for photoName in photoNames {
                let imageView = UIImageView()
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = ReviewCellLayout.photoCornerRadius
                imageView.image = UIImage(named: photoName)
                photoImageViews.append(imageView)
            }
        }
        
        photoImageViews.forEach { contentView.addSubview($0) }
    }
    
    func updatePhotos() {
        guard let config = config else { return }
        photoImageViews.forEach { $0.removeFromSuperview() }
        photoImageViews.removeAll()
        
        if let photoNames = config.photoNames {
            for photoName in photoNames {
                let imageView = UIImageView()
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = ReviewCellLayout.photoCornerRadius
                imageView.image = UIImage(named: photoName)
                photoImageViews.append(imageView)
            }
        }
        
        photoImageViews.forEach { contentView.addSubview($0) }
    }
    
    @objc func buttonTouchDown(_ sender: UIButton) {
        guard let id = config?.id else { return }
        
        config?.onTapShowMore(id)
    }
    
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {
    
    // MARK: - Размеры
    
    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let ratingSize = CGSize(width: 84, height: 16)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0
    
    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()
    
    // MARK: - Фреймы
    
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    private(set) var avatarImageViewFrame: CGRect = .zero
    private(set) var ratingImageViewFrame: CGRect = .zero
    private(set) var nameLabelFrame: CGRect = .zero
    private(set) var ratingImageViewsFrame: CGRect = .zero
    private(set) var photoImageViewsFrames: [CGRect] = []
    
    
    
    // MARK: - Отступы
    
    /// Отступы от краёв ячейки до её содержимого.
    fileprivate let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    /// Горизонтальный отступ от аватара до имени пользователя.
    fileprivate let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    fileprivate let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    fileprivate let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    fileprivate let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    fileprivate let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    fileprivate let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    fileprivate let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    fileprivate let showMoreToCreatedSpacing = 6.0
    
    
    
    // MARK: - Расчёт фреймов и высоты ячейки
    
    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right
        
        var maxY = insets.top
        var maxX = insets.left
        var showShowMoreButton = false
        
        avatarImageViewFrame = CGRect(
            origin: CGPoint(x: insets.left, y: maxY),
            size: CGSize(width: ReviewCellLayout.avatarSize.width, height: ReviewCellLayout.avatarSize.height)
        )
        maxX = avatarImageViewFrame.maxX + avatarToUsernameSpacing
        
        let currentNameHeight = (config.fullName.font()?.lineHeight ?? .zero)
        nameLabelFrame = CGRect(
            origin: CGPoint(x: maxX, y: maxY),
            size: CGSize(width: width, height: currentNameHeight)
        )
        maxY = nameLabelFrame.maxY + usernameToRatingSpacing
        
        ratingImageViewFrame = CGRect(
            origin: CGPoint(x: maxX, y: maxY),
            size: CGSize(width: ReviewCellLayout.ratingSize.width, height: ReviewCellLayout.ratingSize.height)
        )
        maxY = ratingImageViewFrame.maxY + (config.photoNames != nil ? ratingToTextSpacing : ratingToPhotosSpacing)
        
        if let photoImageViews = config.photoNames, !photoImageViews.isEmpty {
            var currentX = maxX
            for _ in photoImageViews {
                let photoFrame = CGRect(
                    origin: CGPoint(x: currentX, y: maxY),
                    size: ReviewCellLayout.photoSize
                )
                photoImageViewsFrames.append(photoFrame)
                currentX += ReviewCellLayout.photoSize.width + photosSpacing
            }
            
            maxY += ReviewCellLayout.photoSize.height + photosToTextSpacing
        }
        
        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight
            
            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: maxX, y: maxY),
                size: config.reviewText.boundingRect(width: width - maxX - insets.right, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }
        
        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: maxX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }
        
        createdLabelFrame = CGRect(
            origin: CGPoint(x: maxX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )
        
        return createdLabelFrame.maxY + insets.bottom
    }
    
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
