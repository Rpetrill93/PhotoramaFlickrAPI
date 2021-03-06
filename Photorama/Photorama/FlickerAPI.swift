//
//  FlickerAPI.swift
//  Photorama
//
//  Created by Emilee Duquette on 6/12/17.
//  Copyright © 2017 Ryan Petrill. All rights reserved.
// BUILD OUT THE BASIC URL REQUEST 

import Foundation

enum FlickrError: Error {
    case invalidJSONData
}

enum Method: String {
    case interestingPhotos = "flickr.interestingness.getList"
}


struct FlickrAPI {

    //Construct the baseURL string for the API Request
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "a6d819499131071f158fd740860a5a88"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    //Construct the flicker API Call URL
    private static func flickerURL(method: Method ,
                                   parameters: [String:String]?) -> URL {
        var components = URLComponents(string: baseURLString)!
        
        var queryItems = [URLQueryItem]()
        
        let baseParams = [
        "method": method.rawValue,
        "format": "json",
        "nojsoncallback": "1",
        "api_key": apiKey
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        return components.url!
    }
    
    //Interesting Photos URL Computed Property
    static var interestingPhotosURL: URL {
        return flickerURL(method: .interestingPhotos,
                          parameters: ["extras":"url_h, date_taken"])
    }
    
    //Converts JSON Data to Photo Results
    static func photos(fromJSON data: Data) -> PhotosResult {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            
            guard
            let jsonDictionary = jsonObject as? [AnyHashable:Any],
            let photos = jsonDictionary["photos"] as? [String:Any],
                let photosArray = photos["photo"] as? [[String:Any]] else {
                    
                    //The JSON Structure doesn't match our expectations
                    return.failure(FlickrError.invalidJSONData)
            }
            
            
            var finalPhotos = [Photo]()
            for photoJSON in photosArray {
                if let photo = photo(fromJson: photoJSON) {
                    finalPhotos.append(photo)
                }
            }
            if finalPhotos.isEmpty && !photosArray.isEmpty {
                //We werent able to parse any of the photos
                //Maybe JSON format for photos has changed
                return .failure(FlickrError.invalidJSONData)
            }
            return .success(finalPhotos)
        } catch let error {
            return .failure(error)
        }
        
    }
    
    //Now parse JSON dictionary into a Photo instance
    private static func photo(fromJson json: [String: Any]) -> Photo? {
        guard
            let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString) else {
                
                //Not enough information to construct a photo
            return nil
        }
        return Photo(title: title, photoID: photoID, remoteURL: url, dateTaken: dateTaken)
    }
}
