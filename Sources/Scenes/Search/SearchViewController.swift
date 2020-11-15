import AlamofireImage
import NotificationBannerSwift
import UIKit

protocol SearchViewControllerOutput {
    func search(_ keyword: String)
}

class SearchViewController: ViewController {
    var output: SearchViewControllerOutput!

    private var collection: UICollectionView!

    private var searchBar: TextField!

    private let presenter = SearchCollectionPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background
        title = NSLocalizedString("search", comment: "")

        collection = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .clear
        collection.keyboardDismissMode = .onDrag

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(endRefresh), for: .valueChanged)
        collection.refreshControl = refresh

        collection.register(cellWithClass: UserCell.self)
        collection.register(cellWithClass: GroupSearchCell.self)
        collection.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: CollectionViewSectionTitle.self)
        collection.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: CollectionViewSectionViewMore.self)

        output.search("*")

        view.addSubview(collection)

        searchBar = TextField(frame: .zero, theme: .normal)
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.addTarget(self, action: #selector(updateSearchResults), for: .editingChanged)
        searchBar.clearButtonMode = .whileEditing
        searchBar.returnKeyType = .done
        searchBar.placeholder = NSLocalizedString("search_for_friends", comment: "")
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            searchBar.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            searchBar.heightAnchor.constraint(equalToConstant: 48),
        ])

        NSLayoutConstraint.activate([
            collection.leftAnchor.constraint(equalTo: view.leftAnchor),
            collection.rightAnchor.constraint(equalTo: view.rightAnchor),
            collection.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int, _: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            switch self.presenter.sectionType(for: sectionIndex) {
            case .groupList:
                return self.groupSection()
            case .userList:
                return self.userSection()
            }
        }

        layout.configuration = UICollectionViewCompositionalLayoutConfiguration()
        layout.configuration.interSectionSpacing = 20

        return layout
    }

    private func userSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1))
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)

        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(88))

        let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: layoutGroupSize, subitem: layoutItem, count: 1)

        layoutGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        layoutGroup.interItemSpacing = .fixed(0)

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        layoutSection.interGroupSpacing = 0

        layoutSection.boundarySupplementaryItems = [createSectionHeader(), createSectionFooter(height: 105 + 38)]

        return layoutSection
    }

    private func groupSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1))
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)

        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(88))

        let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: layoutGroupSize, subitem: layoutItem, count: 1)

        layoutGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        layoutGroup.interItemSpacing = .fixed(0)

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        layoutSection.interGroupSpacing = 0

        layoutSection.boundarySupplementaryItems = [createSectionHeader(), createSectionFooter()]

        return layoutSection
    }

    private func createSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    private func createSectionFooter(height: CGFloat = 58) -> NSCollectionLayoutBoundarySupplementaryItem {
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(height)),
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
    }

    @objc private func endRefresh() {
        collection.refreshControl?.endRefreshing()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    // @TODO probably needs to be in the interactor?
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        view.endEditing(true)

        switch presenter.sectionType(for: indexPath.section) {
        case .userList:
            let user = presenter.item(for: IndexPath(item: indexPath.item, section: indexPath.section), ofType: APIClient.User.self)
            navigationController?.pushViewController(SceneFactory.createProfileViewController(id: user.id), animated: true)
        case .groupList:
            let group = presenter.item(for: IndexPath(item: indexPath.item, section: indexPath.section), ofType: APIClient.Group.self)
            navigationController?.pushViewController(SceneFactory.createGroupViewController(id: group.id), animated: true)
        }
    }
}

extension SearchViewController: UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int {
        return presenter.numberOfSections
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection index: Int) -> Int {
        return presenter.numberOfItems(for: index)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch presenter.sectionType(for: indexPath.section) {
        case .groupList:
            let cell = collectionView.dequeueReusableCell(withClass: GroupSearchCell.self, for: indexPath)
            presenter.configure(item: cell, for: indexPath)
            return cell
        case .userList:
            let cell = collectionView.dequeueReusableCell(withClass: UserCell.self, for: indexPath)
            presenter.configure(item: cell, for: indexPath)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: CollectionViewSectionViewMore.self, for: indexPath)

            switch presenter.sectionType(for: indexPath.section) {
            case .groupList:
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(showMoreGroups))
                cell.view.addGestureRecognizer(recognizer)
            case .userList:
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(showMoreUsers))
                cell.view.addGestureRecognizer(recognizer)
            }

            return cell
        }

        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: CollectionViewSectionTitle.self, for: indexPath)
        cell.label.font = .rounded(forTextStyle: .title2, weight: .bold)
        cell.label.text = presenter.sectionTitle(for: indexPath.section)
        return cell
    }

    @objc private func showMoreGroups() {
        var text = "*"
        if let input = searchBar.text, input != "" {
            text = input
        }

        let view = SceneFactory.createSearchResultsViewController(type: .groups, keyword: text)
        navigationController?.pushViewController(view, animated: true)
    }

    @objc private func showMoreUsers() {
        var text = "*"
        if let input = searchBar.text, input != "" {
            text = input
        }

        let view = SceneFactory.createSearchResultsViewController(type: .users, keyword: text)
        navigationController?.pushViewController(view, animated: true)
    }
}

extension SearchViewController: SearchPresenterOutput {
    func display(users: [APIClient.User]) {
        presenter.set(users: users)

        DispatchQueue.main.async {
            self.collection.refreshControl?.endRefreshing()
            self.collection.reloadData()
        }
    }

    func display(groups: [APIClient.Group]) {
        presenter.set(groups: groups)

        DispatchQueue.main.async {
            self.collection.refreshControl?.endRefreshing()
            self.collection.reloadData()
        }
    }

    func displaySearchError() {
        collection.refreshControl?.endRefreshing()
    }
}

extension SearchViewController: UITextFieldDelegate {
    @objc private func updateSearchResults() {
        var text = "*"
        if let input = searchBar.text, input != "" {
            text = input
        }

        collection.refreshControl?.beginRefreshing()
        output.search(text)
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
