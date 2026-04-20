import Foundation
import Vapor

enum PNGEncoder {
  static func encode(canvas: RasterCanvas) throws -> Data {
    guard canvas.width > 0, canvas.height > 0 else {
      throw Abort(.internalServerError, reason: "Cannot encode an empty image.")
    }

    var png = Data()
    png.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    var ihdr = Data()
    ihdr.appendUInt32BE(UInt32(canvas.width))
    ihdr.appendUInt32BE(UInt32(canvas.height))
    ihdr.append(contentsOf: [8, 6, 0, 0, 0])
    png.appendChunk(type: "IHDR", data: ihdr)

    let raw = scanlineData(canvas: canvas)
    png.appendChunk(type: "IDAT", data: zlibStoredData(raw))
    png.appendChunk(type: "IEND", data: Data())
    return png
  }

  private static func scanlineData(canvas: RasterCanvas) -> Data {
    var data = Data()
    data.reserveCapacity((canvas.width * 4 + 1) * canvas.height)

    for y in 0..<canvas.height {
      data.append(0)
      let start = y * canvas.width * 4
      let end = start + canvas.width * 4
      data.append(contentsOf: canvas.pixels[start..<end])
    }

    return data
  }

  private static func zlibStoredData(_ raw: Data) -> Data {
    var data = Data()
    data.append(contentsOf: [0x78, 0x01])

    var offset = 0
    while offset < raw.count {
      let chunkLength = min(65_535, raw.count - offset)
      let isFinal = offset + chunkLength == raw.count
      data.append(isFinal ? 0x01 : 0x00)
      data.appendUInt16LE(UInt16(chunkLength))
      data.appendUInt16LE(UInt16.max - UInt16(chunkLength))
      data.append(contentsOf: raw[offset..<(offset + chunkLength)])
      offset += chunkLength
    }

    data.appendUInt32BE(adler32(raw))
    return data
  }

  private static func adler32(_ data: Data) -> UInt32 {
    var s1: UInt32 = 1
    var s2: UInt32 = 0

    for byte in data {
      s1 = (s1 + UInt32(byte)) % 65_521
      s2 = (s2 + s1) % 65_521
    }

    return (s2 << 16) | s1
  }
}

private extension Data {
  mutating func appendChunk(type: String, data: Data) {
    let typeBytes = Array(type.utf8)
    appendUInt32BE(UInt32(data.count))
    append(contentsOf: typeBytes)
    append(data)

    var crcInput = Data()
    crcInput.append(contentsOf: typeBytes)
    crcInput.append(data)
    appendUInt32BE(CRC32.checksum(crcInput))
  }

  mutating func appendUInt16LE(_ value: UInt16) {
    append(UInt8(value & 0xFF))
    append(UInt8((value >> 8) & 0xFF))
  }

  mutating func appendUInt32BE(_ value: UInt32) {
    append(UInt8((value >> 24) & 0xFF))
    append(UInt8((value >> 16) & 0xFF))
    append(UInt8((value >> 8) & 0xFF))
    append(UInt8(value & 0xFF))
  }
}

private enum CRC32 {
  static func checksum(_ data: Data) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF

    for byte in data {
      crc ^= UInt32(byte)
      for _ in 0..<8 {
        if crc & 1 == 1 {
          crc = (crc >> 1) ^ 0xEDB8_8320
        } else {
          crc >>= 1
        }
      }
    }

    return crc ^ 0xFFFF_FFFF
  }
}
