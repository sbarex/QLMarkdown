//
//  gunzip.swift
//  QLMarkdown
//
//  Created by Sbarex on 18/09/2026.
//

import Foundation
import Compression
import CryptoKit

enum GzipDecompressionError: Error {
    case streamInitFailed
    case decompressionFailed
    case invalidGzipHeader
}

/// Decompress gzip data.
/// Use the deflate/inflate stream of Apple (Compression.framework),
/// manually skipping the gzip header/footer because COMPRESSION_ZLIB require
/// a "raw deflate" stream and not a complete gzip package.
func gunzip(_ input: Data) throws -> Data {
    guard input.count > 18,
          input[0] == 0x1f, input[1] == 0x8b, input[2] == 0x08 else {
        throw GzipDecompressionError.invalidGzipHeader
    }
    
    // Basic parsing of the gzip eader gzip to found the begin of the deflate payload.
    let flags = input[3]
    var offset = 10 // fixed header: magic(2) + method(1) + flags(1) + mtime(4) + xfl(1) + os(1)
    
    if flags & 0x04 != 0 { // FEXTRA
        let xlen = Int(input[offset]) | (Int(input[offset + 1]) << 8)
        offset += 2 + xlen
    }
    if flags & 0x08 != 0 { // FNAME
        while input[offset] != 0 { offset += 1 }
        offset += 1
    }
    if flags & 0x10 != 0 { // FCOMMENT
        while input[offset] != 0 { offset += 1 }
        offset += 1
    }
    if flags & 0x02 != 0 { // FHCRC
        offset += 2
    }
    
    // The deflate payload exclude the final footers (CRC32 + original size, 8 byte)
    let deflatePayload = input.subdata(in: offset..<(input.count - 8))
    
    // Original uncompressed size, declared on the gzip footer (little-endian, 32 bit)
    let sizeRange = (input.count - 4)..<input.count
    let originalSize = input.subdata(in: sizeRange).withUnsafeBytes {
        $0.load(as: UInt32.self)
    }
    
    var destinationBuffer = [UInt8](repeating: 0, count: Int(originalSize))
    
    let decodedCount = deflatePayload.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) -> Int in
        guard let srcBase = srcPtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
        return compression_decode_buffer(
            &destinationBuffer, destinationBuffer.count,
            srcBase, deflatePayload.count,
            nil,
            COMPRESSION_ZLIB
        )
    }
    
    guard decodedCount == destinationBuffer.count else {
        throw GzipDecompressionError.decompressionFailed
    }
    
    return Data(destinationBuffer)
}

/// Get the hash SHA384 of a data.
/// - returns: The hash SHA384 (48 byte).
func sha384OfData(_ data: Data) -> Data {
    let digest = SHA384.hash(data: data)
    return Data(digest)
}

func sha384OfData(_ data: Data) -> String {
    let hash: Data = sha384OfData(data)
    
    return "sha384-" + hash.base64EncodedString()
}
