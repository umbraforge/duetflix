//
//  APIClient.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//


// URL'ye giden ordan json alıp istediğimiz tip'e çeviren bir fonksiyon
import Foundation


enum APIError : Error {
    case invalidURL // url hatası
    case requestFailed(statusCode: Int)
    case decodingFailed(Error) // JSON, beklenen yapıya uymadıysa
}

// fetchPopular çağırılınca T = MovieResponse olur başka bir istekte başka şey olur vb ....
struct APIClient {
    func fetch <T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url) // MEKTUP, ne isteniyor?
        
        // Headerları request'e ekleme
        request.setValue("Bearer \(AppConfig.tmdbAccessToken)", forHTTPHeaderField: "Authorization") // token'ı mektuba yaz
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        // URLRequest ile istek gönderme
        let (data, response) = try await URLSession.shared.data(for: request) // mektub'u postacıya ver ve postacıyı gönder
        
        // HTTP durum kodu kontrolü
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(statusCode: -1)
        }
        
        // durum başarılı mı? değilse hata kodunu döndür
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        // JSON decode etme
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data) // ham datayı model'e çevirir
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
