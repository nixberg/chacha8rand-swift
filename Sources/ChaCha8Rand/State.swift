
struct State {
    private var v00: SIMD4<UInt32>
    private var v01: SIMD4<UInt32>
    private var v02: SIMD4<UInt32>
    private var v03: SIMD4<UInt32>
    private var v04: SIMD4<UInt32>
    private var v05: SIMD4<UInt32>
    private var v06: SIMD4<UInt32>
    private var v07: SIMD4<UInt32>
    private var v08: SIMD4<UInt32>
    private var v09: SIMD4<UInt32>
    private var v10: SIMD4<UInt32>
    private var v11: SIMD4<UInt32>
    private var v12: SIMD4<UInt32>
    private var v13: SIMD4<UInt32>
    private var v14: SIMD4<UInt32>
    private var v15: SIMD4<UInt32>
    
    private var s0: SIMD4<UInt32>
    private var s1: SIMD4<UInt32>
    private var s2: SIMD4<UInt32>
    private var s3: SIMD4<UInt32>
    private var s4: SIMD4<UInt32>
    private var s5: SIMD4<UInt32>
    private var s6: SIMD4<UInt32>
    private var s7: SIMD4<UInt32>
    
    @inline(__always)
    init(seed: UnsafeBufferPointer<UInt32>, counter: UInt32) {
        assert(seed.count == 8)
        
        v00 = SIMD4(repeating: 0x61707865)
        v01 = SIMD4(repeating: 0x3320646e)
        v02 = SIMD4(repeating: 0x79622d32)
        v03 = SIMD4(repeating: 0x6b206574)
        v04 = SIMD4(repeating: seed[0])
        v05 = SIMD4(repeating: seed[1])
        v06 = SIMD4(repeating: seed[2])
        v07 = SIMD4(repeating: seed[3])
        v08 = SIMD4(repeating: seed[4])
        v09 = SIMD4(repeating: seed[5])
        v10 = SIMD4(repeating: seed[6])
        v11 = SIMD4(repeating: seed[7])
        v12 = SIMD4(repeating: counter) &+ SIMD4(0, 1, 2, 3)
        v13 = .zero
        v14 = .zero
        v15 = .zero
        
        s0 = v04
        s1 = v05
        s2 = v06
        s3 = v07
        s4 = v08
        s5 = v09
        s6 = v10
        s7 = v11
    }
    
    @inline(__always)
    mutating func permute() {
        for _ in 0..<4 {
            quarterRound(&v00, &v04, &v08, &v12)
            quarterRound(&v01, &v05, &v09, &v13)
            quarterRound(&v02, &v06, &v10, &v14)
            quarterRound(&v03, &v07, &v11, &v15)
            
            quarterRound(&v00, &v05, &v10, &v15)
            quarterRound(&v01, &v06, &v11, &v12)
            quarterRound(&v02, &v07, &v08, &v13)
            quarterRound(&v03, &v04, &v09, &v14)
        }
        
        v04 &+= s0
        v05 &+= s1
        v06 &+= s2
        v07 &+= s3
        v08 &+= s4
        v09 &+= s5
        v10 &+= s6
        v11 &+= s7
    }
    
    @inline(__always)
    consuming func finalize(into buffer: UnsafeMutableRawBufferPointer) {
        buffer.storeWords(of: v00, toByteOffset: 000)
        buffer.storeWords(of: v01, toByteOffset: 016)
        buffer.storeWords(of: v02, toByteOffset: 032)
        buffer.storeWords(of: v03, toByteOffset: 048)
        buffer.storeWords(of: v04, toByteOffset: 064)
        buffer.storeWords(of: v05, toByteOffset: 080)
        buffer.storeWords(of: v06, toByteOffset: 096)
        buffer.storeWords(of: v07, toByteOffset: 112)
        buffer.storeWords(of: v08, toByteOffset: 128)
        buffer.storeWords(of: v09, toByteOffset: 144)
        buffer.storeWords(of: v10, toByteOffset: 160)
        buffer.storeWords(of: v11, toByteOffset: 176)
        buffer.storeWords(of: v12, toByteOffset: 192)
        buffer.storeWords(of: v13, toByteOffset: 208)
        buffer.storeWords(of: v14, toByteOffset: 224)
        buffer.storeWords(of: v15, toByteOffset: 240)
    }
}

@inline(__always)
fileprivate func quarterRound(
    _ a: inout SIMD4<UInt32>,
    _ b: inout SIMD4<UInt32>,
    _ c: inout SIMD4<UInt32>,
    _ d: inout SIMD4<UInt32>
) {
    a &+= b
    d ^= a
    d.rotate(left: 16)
    
    c &+= d
    b ^= c
    b.rotate(left: 12)
    
    a &+= b
    d ^= a
    d.rotate(left: 08)
    
    c &+= d
    b ^= c
    b.rotate(left: 07)
}

extension SIMD2<UInt64> {
    @inline(__always)
    fileprivate init(_ source: SIMD4<UInt32>) {
#if _endian(little)
        self = unsafeBitCast(source, to: Self.self)
#else
#warning("Support for big-endian platforms is untested!")
        self = Self(
            Scalar(value.y) << 32 | Scalar(value.x),
            Scalar(value.w) << 32 | Scalar(value.z)
        )
#endif
    }
}

extension SIMD4<UInt32> {
    @inline(__always)
    fileprivate mutating func rotate(left count: Scalar) {
        self = self &<< count | self &>> (32 - count)
    }
}

extension UnsafeMutableRawBufferPointer {
    @inline(__always)
    fileprivate func storeWords(
        of value: SIMD4<UInt32>,
        toByteOffset offset: Int
    ) {
        self.storeBytes(of: SIMD2<UInt64>(value), toByteOffset: offset, as: SIMD2<UInt64>.self)
    }
}
 
