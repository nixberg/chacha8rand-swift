extension ChaCha8Rand {
    private static let header: UInt64 = 0x3a38616863616863 // "chacha8:" as little-endian integer
    
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
        
        guard buffer.loadUnaligned(as: UInt64.self, endianess: .little) == Self.header else {
            return nil
        }
        
        let (counter, index) = buffer.loadUnaligned(
            fromByteOffset: 08,
            as: UInt64.self,
            endianess: .big
        ).quotientAndRemainder(dividingBy: 32)
        
        let seed = ContiguousArray<UInt32>(unsafeUninitializedCapacity: 8) { seed, count in
            seed.initialize(repeating: 0)
            var offset = 16
            for index in seed.indices {
                seed[index] = buffer.loadUnaligned(
                    fromByteOffset: offset,
                    as: UInt32.self,
                    endianess: .little
                )
                offset &+= 4
            }
            count = 8
        }
        
        self.init(seed: seed, counter: 4 * UInt32(counter), index: Int(index))
    }
    
    public func encode(into buffer: UnsafeMutableRawBufferPointer) {
        precondition(buffer.count == 48, "TODO")
        
        buffer.storeBytes(of: Self.header, endianess: .little, toByteOffset: 00)
        
        let used = UInt64(counter / 4) * 32 + UInt64(index)
        buffer.storeBytes(of: used, endianess: .big, toByteOffset: 08)
        
        var offset = 16
        for word in seed {
            buffer.storeBytes(of: word, endianess: .little, toByteOffset: offset)
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
