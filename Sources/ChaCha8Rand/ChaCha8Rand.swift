public struct ChaCha8Rand {
    private var buffer = ContiguousArray<UInt64>(repeating: 0, count: 32)
    
    var seed: ContiguousArray<UInt32>
    var counter: UInt32 = 0
    
    var index = 0
    private var endIndex = 32
    
    public init() {
        seed = ContiguousArray(unsafeUninitializedCapacity: 8) { seed, count in
            seed.initialize(repeating: 0)
            for index in seed.indices {
                seed[index] = SystemRandomNumberGenerator.next() // TODO: fill(_:)
            }
            count = 8
        }
        self.block()
    }
    
    public init(seed: some Sequence<UInt8>) {
        self = seed.withContiguousStorageIfAvailable({
            Self(seed: UnsafeRawBufferPointer($0))
        }) ?? Array(seed).withUnsafeBytes({ Self(seed: $0) })
    }
    
    private init(seed bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count == 32, "TODO")
        self.seed = ContiguousArray(unsafeUninitializedCapacity: 8) { seed, count in
            seed.initialize(repeating: 0)
            seed[0] = bytes.loadLittleEndianUInt32(fromByteOffset: 00)
            seed[1] = bytes.loadLittleEndianUInt32(fromByteOffset: 04)
            seed[2] = bytes.loadLittleEndianUInt32(fromByteOffset: 08)
            seed[3] = bytes.loadLittleEndianUInt32(fromByteOffset: 12)
            seed[4] = bytes.loadLittleEndianUInt32(fromByteOffset: 16)
            seed[5] = bytes.loadLittleEndianUInt32(fromByteOffset: 20)
            seed[6] = bytes.loadLittleEndianUInt32(fromByteOffset: 24)
            seed[7] = bytes.loadLittleEndianUInt32(fromByteOffset: 28)
            count = 8
        }
        self.block()
    }
    
    init?(seed: ContiguousArray<UInt32>, counter: UInt32, index: Int) {
        guard
            seed.count == 8,
            (0...12).contains(counter),
            counter.isMultiple(of: 4),
            (0...counter.endIndex).contains(index)
        else {
            return nil
        }
        self.seed = seed
        self.counter = counter
        self.index = index
        self.endIndex = counter.endIndex
        self.block()
    }
    
    public mutating func next() -> UInt64 {
        assert((0...16).contains(counter) && counter.isMultiple(of: 4))
        assert(endIndex == 28 || endIndex == 32)
        assert((0...endIndex).contains(index))
        
        if index == endIndex {
            self.refill()
        }
        
        defer { index &+= 1 }
        return buffer.withUnsafeBufferPointer {
            $0[index]
        }
    }
    
    private mutating func refill() {
        counter &+= 4
        
        if counter == 16 {
            seed.withUnsafeMutableBufferPointer { seed in
                (seed[0], seed[1]) = buffer[28].words
                (seed[2], seed[3]) = buffer[29].words
                (seed[4], seed[5]) = buffer[30].words
                (seed[6], seed[7]) = buffer[31].words
            }
            counter = 0
        }
        
        self.block()
        
        index = 0
        endIndex = counter.endIndex
    }
    
    mutating func block() {
        seed.withUnsafeBufferPointer { seed in
            buffer.withUnsafeMutableBytes { buffer in
                var state = State(seed: seed, counter: counter)
                state.permute()
                state.finalize(into: buffer)
            }
        }
    }
}

extension UInt32 {
    var endIndex: Int {
        assert((0...12).contains(self))
        assert(self.isMultiple(of: 4))
        return self == 12 ? 28 : 32
    }
}

extension UInt64 {
    @inline(__always)
    var words: (UInt32, UInt32) {
        (UInt32(truncatingIfNeeded: self), UInt32(truncatingIfNeeded: self >> 32))
    }
}

extension SystemRandomNumberGenerator {
    static func next() -> UInt32 {
        var generator = Self()
        return generator.next()
    }
}
