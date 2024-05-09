extension ChaCha8Rand {
    private static let header: UInt64 = 0x3a38616863616863 // "chacha8:" in LE byte-order
    
    public init?(decoding bytes: some Sequence<UInt8>) {
        guard let decoded = bytes.withContiguousStorageIfAvailable({
            Self(decoding: UnsafeRawBufferPointer($0))
        }) ?? Array(bytes).withUnsafeBytes({ Self(decoding: $0) }) else {
            return nil
        }
        self = decoded
    }
    
    public init?(decoding buffer: UnsafeRawBufferPointer) {
        precondition(buffer.count == 48, "TODO")
        
        guard buffer.loadLittleEndianUInt64(fromByteOffset: 00) == Self.header else {
            return nil
        }
        
        let (counter, index) = buffer.loadBigEndianUInt64(fromByteOffset: 08)
            .quotientAndRemainder(dividingBy: 32)
        
        let seed = ContiguousArray<UInt32>(unsafeUninitializedCapacity: 8) { seed, count in
            seed.initialize(repeating: 0)
            seed[0] = buffer.loadLittleEndianUInt32(fromByteOffset: 16)
            seed[1] = buffer.loadLittleEndianUInt32(fromByteOffset: 20)
            seed[2] = buffer.loadLittleEndianUInt32(fromByteOffset: 24)
            seed[3] = buffer.loadLittleEndianUInt32(fromByteOffset: 28)
            seed[4] = buffer.loadLittleEndianUInt32(fromByteOffset: 32)
            seed[5] = buffer.loadLittleEndianUInt32(fromByteOffset: 36)
            seed[6] = buffer.loadLittleEndianUInt32(fromByteOffset: 40)
            seed[7] = buffer.loadLittleEndianUInt32(fromByteOffset: 44)
            count = 8
        }
        
        self.init(seed: seed, counter: 4 * UInt32(counter), index: Int(index))
    }
    
    public func encode(into buffer: UnsafeMutableRawBufferPointer) {
        precondition(buffer.count == 48, "TODO")
        
        buffer.storeLittleEndianBytes(of: Self.header, toByteOffset: 00)
        
        buffer.storeBigEndianBytes(of: UInt64(counter / 4) * 32 + UInt64(index), toByteOffset: 08)
        
        var offset = 16
        for word in seed {
            buffer.storeLittleEndianBytes(of: word, toByteOffset: offset)
            offset &+= 4
        }
    }
    
    public func encoded() -> [UInt8] {
        var result = [UInt8](repeating: 0, count: 48)
        result.withUnsafeMutableBytes {
            self.encode(into: $0)
        }
        return result
    }
}
