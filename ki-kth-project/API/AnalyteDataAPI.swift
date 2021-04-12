//
//  AnalyteDataAPI.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-04-12.
//

import Foundation


struct AnalyteDataAPI {
    
    private let networkingService = NetworkingService()
    
    
    func getAnalyteData(by id: String, with completion: @escaping (Result<AnalyteData,Error>) -> Void) {
        
        let url =  "https://ki-kth-project-api.herokuapp.com/analyte/\(id)"
        
        networkingService.dispatchRequest(urlString: url, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let analyteData = try JSONDecoder().decode(AnalyteData.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(analyteData))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

//MARK: Analyte Data Decodable
struct AnalyteData: Decodable {
    let description: String
    let measurements: [Measurement]
}

struct Measurement: Decodable {
    let time: String
    let value: Double
}



