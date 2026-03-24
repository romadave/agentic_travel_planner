//
//  ParseTripPrompt.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

struct ParseTripPromptRequest : Encodable {
    let prompt: String
    let include_raw_llm_output : Bool
}

struct ParseTripPromptResponse : Decodable {
    let prompt: String
    let parsedPromptResult : ParsedPromptResult
}

