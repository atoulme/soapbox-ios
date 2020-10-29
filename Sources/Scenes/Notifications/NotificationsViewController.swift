import NotificationBannerSwift
import UIKit

protocol NotificationsViewControllerOutput {
    func loadNotifications()
}

class NotificationsViewController: UIViewController {
    var output: NotificationsViewControllerOutput!

    private var notifications = [APIClient.Notification]()

    private var collection: UICollectionView!

    private let refresh = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        title = NSLocalizedString("activity", comment: "")

        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.rounded(forTextStyle: .body, weight: .medium),
        ]

        collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout())
        collection.dataSource = self
        collection.delegate = self
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.register(cellWithClass: FollowingNotificationCell.self)
        view.addSubview(collection)

        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.topAnchor),
            collection.leftAnchor.constraint(equalTo: view.leftAnchor),
            collection.rightAnchor.constraint(equalTo: view.rightAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        loadData()
    }

    @objc private func loadData() {
        output.loadNotifications()
    }

    private func layout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(40)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        section.interGroupSpacing = 20

        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension NotificationsViewController: NotificationsPresenterOutput {
    func display(notifications: [APIClient.Notification]) {
        self.notifications = notifications

        DispatchQueue.main.async {
            self.refresh.endRefreshing()
            self.collection.reloadData()
        }
    }

    func displayError() {
        let banner = FloatingNotificationBanner(
            title: NSLocalizedString("something_went_wrong", comment: ""),
            subtitle: NSLocalizedString("please_try_again_later", comment: ""),
            style: .danger
        )
        banner.show(cornerRadius: 10, shadowBlurRadius: 15)
    }
}

extension NotificationsViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return notifications.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let notification = notifications[indexPath.item]

        let cell = collectionView.dequeueReusableCell(withClass: FollowingNotificationCell.self, for: indexPath)
        cell.name.text = notification.from.username
        cell.user = notification.from.id

        cell.image.image = nil
        if notification.from.image != "" {
            cell.image.af.setImage(withURL: Configuration.cdn.appendingPathComponent("/images/" + notification.from.image))
        }

        return cell
    }
}

extension NotificationsViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // @TODO INTERACTOR
        let item = notifications[indexPath.item]

        guard let nav = navigationController as? NavigationViewController else {
            return
        }

        if item.category != "NEW_FOLLOWER" {
            return
        }

        nav.pushViewController(SceneFactory.createProfileViewController(id: item.from.id), animated: true)
    }
}
