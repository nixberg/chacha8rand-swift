enum Endianess {
    case big
    case little
    case native
}

extension UnsafeRawBufferPointer {
    @inline(__always)
    func loadUnaligned<T: FixedWidthInteger>(
        fromByteOffset offset: Int = 0,
        as type: T.Type,
        endianess: Endianess
    ) -> T {
        let value = self.loadUnaligned(fromByteOffset: offset, as: type)
        return switch endianess {
        case .big:
            T(bigEndian: value)
        case .little:
            T(littleEndian: value)
        case .native:
            value
        }
    }
}

extension UnsafeMutableRawBufferPointer {
    @inline(__always)
    func storeBytes<T: FixedWidthInteger>(
        of value: T,
        endianess: Endianess,
        toByteOffset offset: Int = 0
    ) {
        let value = switch endianess {
        case .big:
            value.bigEndian
        case .little:
            value.littleEndian
        case .native:
            value
        }
        self.storeBytes(of: value, toByteOffset: offset, as: T.self)
    }
}
