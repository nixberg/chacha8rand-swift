extension ChaCha8Rand: Codable {
    private enum CodingKeys: String, CaseIterable, CodingKey {
        case seed
        case counter
        case index
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let seed = try container.decode(ContiguousArray<UInt32>.self, forKey: .seed)
        
        let counter = try container.decode(UInt32.self, forKey: .counter)
        
        let index = try container.decode(Int.self, forKey: .index)
        
        guard let generator = Self(seed: seed, counter: counter, index: index) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: CodingKeys.allCases,
                debugDescription: "TODO"
            ))
        }
        self = generator
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(seed, forKey: .seed)
        
        try container.encode(counter, forKey: .counter)
        
        try container.encode(index, forKey: .index)
    }
}
