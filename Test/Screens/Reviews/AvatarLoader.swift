//
//  AvatarLoader.swift
//  Test
//
//  Created by Сергей Богомолов on 25.02.2025.
//

import Foundation

final class AvatarLoader {
    typealias GetAvatarResult = Result<Data, GetAvatarError>
    
    enum GetAvatarError: Error {
        case badURL
        case badData(Error)
    }
    
    func getAvatar(avatarUrlString: String, completion: @escaping (GetAvatarResult) -> Void) {
        guard let url = URL(string: avatarUrlString) else {
            return completion(.failure(.badURL))
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    completion(.success(data))
                }
                if let error = error {
                    completion(.failure(.badData(error)))
                }
        }.resume()
    }
}

