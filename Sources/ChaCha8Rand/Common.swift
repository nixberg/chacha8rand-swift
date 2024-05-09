extension UnsafeRawBufferPointer {
    @inline(__always)
    func loadBigEndianUInt64(fromByteOffset offset: Int) -> UInt64 {
        UInt64(bigEndian: self.loadUnaligned(fromByteOffset: offset, as: UInt64.self))
    }
    
    @inline(__always)
    func loadLittleEndianUInt32(fromByteOffset offset: Int) -> UInt32 {
        UInt32(littleEndian: self.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
    }
    
    @inline(__always)
    func loadLittleEndianUInt64(fromByteOffset offset: Int) -> UInt64 {
        UInt64(littleEndian: self.loadUnaligned(fromByteOffset: offset, as: UInt64.self))
    }
}

extension UnsafeMutableRawBufferPointer {
    @inline(__always)
    func storeBigEndianBytes(of value: UInt64, toByteOffset offset: Int) {
        self.storeBytes(of: value.bigEndian, toByteOffset: offset, as: UInt64.self)
    }
    
    @inline(__always)
    func storeLittleEndianBytes(of value: UInt32, toByteOffset offset: Int) {
        self.storeBytes(of: value.littleEndian, toByteOffset: offset, as: UInt32.self)
    }
    
    @inline(__always)
    func storeLittleEndianBytes(of value: UInt64, toByteOffset offset: Int) {
        self.storeBytes(of: value.littleEndian, toByteOffset: offset, as: UInt64.self)
    }
}
