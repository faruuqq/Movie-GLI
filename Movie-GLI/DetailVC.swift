//
//  DetailVC.swift
//  Movie-GLI
//
//  Created by Muhammad Faruuq Qayyum on 14/01/21.
//

import UIKit
import SDWebImage
import Alamofire
import youtube_ios_player_helper

class DetailVC: UIViewController, YTPlayerViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backdrop: UIImageView!
    @IBOutlet weak var overview: UILabel!
    @IBOutlet weak var review: UILabel!
    @IBOutlet weak var reviewOwner: UILabel!
    @IBOutlet weak var youtube: YTPlayerView!
    
    var movieTitle: String?
    var movieId: Int?
    var movieBackdrop: String?
    var movieOverview: String?
    let homeVC = ViewController()
    
    fileprivate enum BaseUrl {
        case review, youtube
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = movieTitle
        backdrop.sd_setImage(with: URL(string: movieBackdrop ?? ""), completed: nil)
        overview.text = movieOverview ?? ""
        getReview()
        youtube.delegate = self
        getYouTube()
    }

}

extension DetailVC {
    
    fileprivate func fetchData(url: BaseUrl, completion: @escaping(Result<Review, Error>) ->()) {
        let headers: HTTPHeaders = ["Accept": "application/json"]
        let baseUrl = "https://api.themoviedb.org/3"
        var getUrl: String?
        let parameters = ["api_key" : "88a8b9b29d2fd7cd6c976f0b79c01ca3"]
        
        switch url {
        case .review:
            getUrl = "/movie/\(movieId ?? 0)/reviews"
        case .youtube:
            getUrl = "/movie/\(movieId ?? 0)/videos"
        }
        
        
        AF.request(baseUrl + getUrl!, parameters: parameters, headers: headers).responseDecodable(of: Review.self) { (result) in
            if let error = result.error {
                completion(.failure(error))
            }
            print(result.response!.statusCode)
            guard result.response!.statusCode == 200 else { return }
            completion(.success(result.value!))
        }
    }
    
    fileprivate func getReview() {
        fetchData(url: .review) { [weak self] (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                self?.reviewOwner.text = data.results.first?.author
                self?.review.text = data.results.first?.content
            }
        }
    }
    
    fileprivate func getYouTube() {
        fetchData(url: .youtube) { [weak self] (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let data):
                self?.youtube.load(withVideoId: (data.results.first?.key)!, playerVars: ["playsinline" : 1])
            }
        }
    }
}
