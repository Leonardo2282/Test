//
//  ImageCacheManager.swift
//  Test
//
//  Created by Сергей Богомолов on 25.02.2025.
//

import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let memoryCache = NSCache<NSString, UIImage>()
    private var diskCacheDirectory: URL?
    private let fileManager = FileManager.default

    private init() {
        let cacheDirectoryName = "MyImageCache"
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            diskCacheDirectory = cacheDirectory.appendingPathComponent(cacheDirectoryName)
            do {
                try fileManager.createDirectory(at: diskCacheDirectory!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating cache directory: \(error)")
                diskCacheDirectory = nil
            }
        } else {
            diskCacheDirectory = nil
        }
    }

    func getImage(for url: URL) -> UIImage? {
        let urlString = url.absoluteString as NSString

        if let image = memoryCache.object(forKey: urlString) {
            return image
        }

        if let diskCacheDirectory = diskCacheDirectory {
            let imagePath = diskCacheDirectory.appendingPathComponent(url.lastPathComponent).path

            if fileManager.fileExists(atPath: imagePath), let image = UIImage(contentsOfFile: imagePath) {
                memoryCache.setObject(image, forKey: urlString)
                return image
            }
        }

        return nil
    }

    func saveImage(_ image: UIImage, for url: URL) {
        let urlString = url.absoluteString as NSString

        memoryCache.setObject(image, forKey: urlString)

        if let diskCacheDirectory = diskCacheDirectory {
            let imagePath = diskCacheDirectory.appendingPathComponent(url.lastPathComponent).path

            if let imageData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try imageData.write(to: URL(fileURLWithPath: imagePath))
                } catch {
                    print("Error saving image to disk: \(error)")
                }
            }
        }
    }

    func removeImage(for url: URL) {
        let urlString = url.absoluteString as NSString

        memoryCache.removeObject(forKey: urlString)

        if let diskCacheDirectory = diskCacheDirectory {
            let imagePath = diskCacheDirectory.appendingPathComponent(url.lastPathComponent).path

            do {
                try fileManager.removeItem(atPath: imagePath)
            } catch {
                print("Error removing image from disk: \(error)")
            }
        }
    }
}

extension UIImageView {
    func loadImage(urlString: String, placeholder: UIImage? = nil) {
        self.image = placeholder

        guard let url = URL(string: urlString) else { return }
        
        if let cachedImage = ImageCacheManager.shared.getImage(for: url) {
            self.image = cachedImage
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error loading image: \(error)")
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                return
            }

            ImageCacheManager.shared.saveImage(image, for: url)

            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}
