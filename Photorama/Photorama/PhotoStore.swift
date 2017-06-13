//
//  PhotoStore.swift
//  Photorama
//
//  Created by Emilee Duquette on 6/12/17.
//  Copyright © 2017 Ryan Petrill. All rights reserved.
//

import UIKit

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

enum PhotosResult {
    case success([Photo])
    case failure(Error)
}


class PhotoStore {
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    
    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void) {
        
        let url = FlickrAPI.interestingPhotosURL //Returns built out URL request
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
        let result = self.processPhotosRequest(data: data, error: error)
            OperationQueue.main.addOperation {
            completion(result)
            }
    }
    task.resume()
}
    
    //Function to process the JSON data from the web service request
    private func processPhotosRequest(data: Data? , error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return FlickrAPI.photos(fromJSON: jsonData)
    }
    
    //Function that will rutrn an instance of ImageResult
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        let photoURL = photo.remoteURL
        let request = URLRequest(url: photoURL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
        
        let result = self.processImageRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result) //Run the function in the main thread
            }
        }
        task.resume()
    }
    
    //Processes the data into an image
    private func processImageRequest(data: Data? , error: Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData)
            else {
                //Couldn't Create an image
                if data == nil {
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        return .success(image)
    }
}
