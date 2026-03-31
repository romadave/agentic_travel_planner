//
//  TripService.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//
import Foundation

final class TripAPIService {
    private let baseURL = "http://127.0.0.1:8000"
    
    func parseTripPrompt(_ prompt: String) async throws -> ParseTripPromptResponse {
        guard let url = URL(string: "\(baseURL)/parse-trip-prompt") else {
                    throw URLError(.badURL)
        }

        let requestBody = ParseTripPromptRequest(
            prompt: prompt,
            include_raw_llm_output: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(domain: "TripAPIService", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: serverMessage
            ])
        }

        return try JSONDecoder().decode(ParseTripPromptResponse.self, from: data)
    }
}
