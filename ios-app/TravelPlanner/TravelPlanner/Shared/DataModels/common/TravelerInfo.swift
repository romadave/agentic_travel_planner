//
//  Travelers.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

struct TravelerInfo: Codable, Equatable, Sendable {
    var adultCount: Int? = nil
    var hasKids: Bool? = nil
    var kidsAges: [Int]? = nil

    /// Computed total — adultCount + number of kids
    var travelerCount: Int {
        let adults = adultCount ?? 0
        let kids = (hasKids ?? false) ? (kidsAges?.count ?? 0) : 0
        return adults + kids
    }

    // Exclude travelerCount from decoding (it's computed),
    // but include it in encoding so the backend receives it.
    private enum CodingKeys: String, CodingKey {
        case adultCount, hasKids, kidsAges, travelerCount
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(adultCount, forKey: .adultCount)
        try container.encodeIfPresent(hasKids, forKey: .hasKids)
        try container.encodeIfPresent(kidsAges, forKey: .kidsAges)
        try container.encode(travelerCount, forKey: .travelerCount)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adultCount = try container.decodeIfPresent(Int.self, forKey: .adultCount)
        hasKids = try container.decodeIfPresent(Bool.self, forKey: .hasKids)
        kidsAges = try container.decodeIfPresent([Int].self, forKey: .kidsAges)
        // travelerCount is computed, skip decoding it
    }

    init(adultCount: Int? = nil, hasKids: Bool? = nil, kidsAges: [Int]? = nil) {
        self.adultCount = adultCount
        self.hasKids = hasKids
        self.kidsAges = kidsAges
    }
}
