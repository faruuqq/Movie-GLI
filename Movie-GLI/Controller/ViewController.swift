//
//  ViewController.swift
//  Movie-GLI
//
//  Created by Muhammad Faruuq Qayyum on 14/01/21.
//

import UIKit
import SDWebImage
import Alamofire

class ViewController: UICollectionViewController {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Results>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Results>
    
    let searchController: UISearchController = {
        let search = UISearchController()
        search.searchBar.placeholder = "Search movie"
        return search
    }()
    
    enum BaseUrl {
        case discoverMovie, searchMovie
    }
    
    private var dataSource: DataSource!
    private var fetchingMore = false
    private var pageNumber = 1
    var item: [Results] = []
    var selectedItem: Results?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "IMDB Movie"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.delegate = self
        configureDataSource()
        applySnapshot(item: item)
        initialData()
    }

}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        discoverMovies(url: .searchMovie, query: searchBar.searchTextField.text, page: nil) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                return
            case .success(let data):
                self.item = []
                data.results.forEach { (item) in
                    let newItem = Results(id: item.id, title: item.title, image: item.image, overview: item.overview, youtube: nil, imageLandscape: item.imageLandscape, content: nil)
                    self.item.append(newItem)
                    self.applySnapshot(item: self.item)
                }
            }
        }
        searchController.isActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        discoverMovies(url: .searchMovie, query: searchBar.searchTextField.text, page: nil) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                return
            case .success(let data):
                self.item = []
                data.results.forEach { (item) in
                    let newItem = Results(id: item.id, title: item.title, image: item.image, overview: item.overview, youtube: nil, imageLandscape: item.imageLandscape, content: nil)
                    self.item.append(newItem)
                    self.applySnapshot(item: self.item)
                }
            }
        }
    }
    
}

extension ViewController {
    
    fileprivate func configureDataSource() {
        collectionView.register(UINib(nibName: "HomeCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        collectionView.collectionViewLayout = createLayout()
        
        dataSource = DataSource(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! HomeCell
            let imageUrl = "https://image.tmdb.org/t/p/w300\(item.image ?? "")"
            cell.moviePoster.sd_setImage(with: URL(string: imageUrl), completed: nil)
            cell.movieTitle.text = item.title
            return cell
        })
        
    }
    
    fileprivate func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            let contentSize = layoutEnvironment.container.effectiveContentSize
            let columns = contentSize.width > 800 ? 3 : 2
            let spacing = CGFloat(10)
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(300))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            group.interItemSpacing = .fixed(spacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            return section
        }
        return layout
    }
    
    fileprivate func applySnapshot(item: [Results]) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(item)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func discoverMovies(url: BaseUrl, query: String?, page: Int?, completion: @escaping (Result<Root, Error>) ->()) {
        let headers: HTTPHeaders = ["Accept": "application/json"]
        let baseUrl = "https://api.themoviedb.org/3"
        var getUrl: String?
        var parameters: [String: String]?
        
        switch url {
        case .discoverMovie:
            getUrl = "/discover/movie?sort_by=popularity.desc"
            parameters = ["api_key" : "88a8b9b29d2fd7cd6c976f0b79c01ca3",
                          "page" : "\(page ?? 1)"]
        case .searchMovie:
            getUrl = "/search/movie"
            parameters = [
                "api_key" : "88a8b9b29d2fd7cd6c976f0b79c01ca3",
                "query" : query!,
                "page" : "\(page ?? 1)"
            ]
        }
        
        AF.request(baseUrl + getUrl!, parameters: parameters, headers: headers).responseDecodable(of: Root.self) { (result) in
            if let error = result.error {
                completion(.failure(error))
            }
            print(result.response!.statusCode)
            guard result.response!.statusCode == 200 else { return }
            completion(.success(result.value!))
        }
    }
    
    fileprivate func initialData() {
        discoverMovies(url: .discoverMovie, query: nil, page: nil) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                self.item = []
                data.results.forEach { (item) in
                    let newItem = Results(id: item.id, title: item.title, image: item.image, overview: item.overview, youtube: nil, imageLandscape: item.imageLandscape, content: nil)
                    self.item.append(newItem)
                    self.applySnapshot(item: self.item)
                }
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if offsetY > contentHeight - scrollView.frame.height * 1.5 {
            if !fetchingMore {
                beginBatchFetch()
            } else {
                print("stopping")
            }
        }
    }
    
    func beginBatchFetch() {
        fetchingMore = true
        print("fetching begin")
        pageNumber += 1
        discoverMovies(url: .discoverMovie, query: nil, page: pageNumber) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                data.results.forEach { (item) in
                    let newItem = Results(id: item.id, title: item.title, image: item.image, overview: item.overview, youtube: nil, imageLandscape: nil, content: nil)
                    self.item.append(newItem)
                    self.applySnapshot(item: self.item)
                }
            }
        }
        fetchingMore = false
    }
}

extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItem = dataSource.itemIdentifier(for: indexPath)
        performSegue(withIdentifier: "toDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailVC = segue.destination as! DetailVC
        
        detailVC.movieId = selectedItem?.id ?? 0
        detailVC.movieTitle = selectedItem?.title ?? ""
        detailVC.movieBackdrop = "https://image.tmdb.org/t/p/w300\(selectedItem?.imageLandscape ?? selectedItem?.image ?? "")"
        detailVC.movieOverview = selectedItem?.overview ?? ""
    }
}
