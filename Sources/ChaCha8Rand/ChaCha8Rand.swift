public struct ChaCha8Rand: RandomNumberGenerator {
    private var buffer = ContiguousArray<UInt64>(repeating: 0, count: 32)
    
    var seed: ContiguousArray<UInt32>
    var counter: UInt32 = 0
    
    var index = 0
    private var endIndex = 32
    
    public init() {
        seed = ContiguousArray(unsafeUninitializedCapacity: 8) { seed, count in
            seed.initialize(repeating: 0)
            for index in seed.indices {
                var generator = SystemRandomNumberGenerator()
                seed[index] = generator.next()
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
            seed[0] = bytes.loadUnaligned(fromByteOffset: 00, as: UInt32.self, endianess: .little)
            seed[1] = bytes.loadUnaligned(fromByteOffset: 04, as: UInt32.self, endianess: .little)
            seed[2] = bytes.loadUnaligned(fromByteOffset: 08, as: UInt32.self, endianess: .little)
            seed[3] = bytes.loadUnaligned(fromByteOffset: 12, as: UInt32.self, endianess: .little)
            seed[4] = bytes.loadUnaligned(fromByteOffset: 16, as: UInt32.self, endianess: .little)
            seed[5] = bytes.loadUnaligned(fromByteOffset: 20, as: UInt32.self, endianess: .little)
            seed[6] = bytes.loadUnaligned(fromByteOffset: 24, as: UInt32.self, endianess: .little)
            seed[7] = bytes.loadUnaligned(fromByteOffset: 28, as: UInt32.self, endianess: .little)
            count = 8
        }
        self.block()
    }
    
    init?(seed: ContiguousArray<UInt32>, counter: UInt32, index: Int) {
        endIndex = counter.endIndex
        guard
            seed.count == 8,
            (0...12).contains(counter),
            counter.isMultiple(of: 4),
            (0...endIndex).contains(index)
        else {
            return nil
        }
        self.seed = seed
        self.counter = counter
        self.index = index
        self.block()
    }
    
    private mutating func block() {
        seed.withUnsafeBufferPointer { seed in
            buffer.withUnsafeMutableBufferPointer { buffer in
                var state = State(seed: seed, counter: counter)
                state.permute()
                state.finalize(into: buffer)
            }
        }
    }
    
    public mutating func next() -> UInt64 {
        assert((0...16).contains(counter) && counter.isMultiple(of: 4))
        assert(endIndex == 28 || endIndex == 32)
        assert((0...endIndex).contains(index))
        
        if index == endIndex {
            self.refill()
        }
        
        defer { index &+= 1 }
        return buffer.withUnsafeBufferPointer({ $0[index] })
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
}

extension UInt32 {
    fileprivate var endIndex: Int {
        assert((0...12).contains(self))
        assert(self.isMultiple(of: 4))
        return self == 12 ? 28 : 32
    }
}

extension UInt64 {
    @inline(__always)
    fileprivate var words: (UInt32, UInt32) {
        (UInt32(truncatingIfNeeded: self), UInt32(truncatingIfNeeded: self >> 32))
    }
}
