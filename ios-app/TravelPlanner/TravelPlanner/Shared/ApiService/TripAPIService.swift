//
//  TripService.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//
#if targetEnvironment(simulator)
private let baseURL = "http://127.0.0.1:8000"
#else
private let baseURL = "http://192.168.1.23:8000" // your Mac's IP
#endif

import Foundation

final class TripAPIService {
    
    func parseTripPrompt(_ prompt: String) async throws -> ParseTripPromptResponse {
        let endPoint = baseURL + "/parse-trip-prompt"
        guard let url = URL(string: "\(endPoint)") else {
            print("bad URL ", endPoint)
                    throw URLError(.badURL)
        }

        let requestBody = ParseTripPromptRequest(
            prompt: prompt,
            include_raw_llm_output: false
        )
        
        print("request body ", requestBody.self)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("Got response back")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("bad server response")
            throw URLError(.badServerResponse)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("Server error ", serverMessage)
            throw NSError(domain: "TripAPIService", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: serverMessage
            ])
        }

        return try JSONDecoder().decode(ParseTripPromptResponse.self, from: data)
    }
    
    func submitFinalDraft(_ draft: TripRequestDraft) async throws -> FinalTripResponse {
        let endPoint = baseURL + "/finalTripRequest"
        guard let url = URL(string: endPoint) else {
            print("bad URL ", endPoint)
            throw URLError(.badURL)
        }
        
        print("Submitting final draft to endpoint: \(endPoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300 // 5 minutes — backend orchestrates multiple agents
        request.httpBody = try JSONEncoder().encode(draft)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("Got response back")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("bad server response")
            throw URLError(.badServerResponse)
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("Server error ", serverMessage)
            throw NSError(domain: "TripAPIService", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: serverMessage
            ])
        }
        
        return try JSONDecoder().decode(FinalTripResponse.self, from: data)
    }
    
}
