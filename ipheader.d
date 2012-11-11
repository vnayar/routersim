debug import std.stdio;

/**
 * Data structure for the IP protocol header.
 * http://www.ietf.org/rfc/rfc791.txt
 */
class IpHeader {
  static immutable uint wordBitSize = uint.sizeof * 8;   // In bits
  static immutable uint wordByteSize = uint.sizeof;      // In bytes
  static immutable uint headerWords = 5;                 // In words

  // The raw header in 32-bit words.
  uint[] rawData;

  this() {
    rawData.length = headerWords;
    setVersion(4);
    setHeaderLength(5);
    setTypeOfService(0);
    setFlags(0);
    setFragmentOffset(0);
    setTimeToLive(50u); // 50 hops at max
    setProtocol(17u); // Default to UDP
  }

  this(uint[] rawData) {
    this.rawData = rawData;
  }

  /// Set reasonable default values in the header.
  void init(uint[] data) {
    setTotalLength(calculateTotalLength(data));
    setHeaderChecksum(calculateHeaderChecksum());
  }

  alias getField!(0, 28, 4) getVersion;
  alias setField!(0, 28, 4) setVersion;

  alias getField!(0, 24, 4) getHeaderLength;
  alias setField!(0, 24, 4) setHeaderLength;

  alias getField!(0, 16, 8) getTypeOfService;
  alias setField!(0, 16, 8) setTypeOfService;

  alias getField!(0, 0, 16) getTotalLength;
  alias setField!(0, 0, 16) setTotalLength;

  // Identifier from the sender to help in assembling fragments of a datagram.
  alias getField!(1, 16, 16) getIdentification;
  alias setField!(1, 16, 16) setIdentification;

  alias getField!(1, 13, 3) getFlags;
  alias setField!(1, 13, 3) setFlags;

  alias getField!(1, 0, 13) getFragmentOffset;
  alias setField!(1, 0, 13) setFragmentOffset;

  alias getField!(2, 24, 8) getTimeToLive;
  alias setField!(2, 24, 8) setTimeToLive;

  alias getField!(2, 16, 8) getProtocol;
  alias setField!(2, 16, 8) setProtocol;

  alias getField!(2, 0, 16) getHeaderChecksum;
  alias setField!(2, 0, 16) setHeaderChecksum;

  uint getSourceAddress() {
    return rawData[3];
  }

  void setSourceAddress(uint address) {
    rawData[3] = address;
  }

  uint getDestinationAddress() {
    return rawData[4];
  }

  void setDestinationAddress(uint address) {
    rawData[4] = address;
  }

  uint calculateTotalLength(uint[] data) {
    uint headerLength = cast(uint) rawData.length * wordByteSize;
    uint dataLength = cast(uint) data.length * wordByteSize;
    return headerLength + dataLength;
  }

  /// Compute the current header checksum according to RFC791.
  uint calculateHeaderChecksum() {
    uint checksum = 0;
    
    foreach (wordIndex ; 0 .. rawData.length) {
      checksum += 0x0000FFFF & rawData[wordIndex];
      checksum += rawData[wordIndex] >> 16;
    }
    // In computing the checksum, the header is considered to be 0.
    checksum -= cast(ushort) rawData[2];
    // Add in any overflow for one's complement.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);
    // And make sure the overflow doesn't cause another overflow.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);

    // And finally return the one's complement of the sum.
    return ~checksum & 0x0000FFFF;
  }

  /**
   * Set the specified bits in the header to the specified value.
   * A separate function will be compiled for each compilation parameter set.
   * Params:
   *   wordOffset = The word the field is located in.
   *   bitOffset  = How many bits into the word the field is in.
   *   length     = How many bits long is the field.
   */
  private void setField(alias wordOffset, alias bitOffset, alias length)(uint val)
    if (is(typeof(wordOffset) : uint) &&
        is(typeof(bitOffset) : uint) &&
        is(typeof(length) : uint) && bitOffset + length <= wordBitSize)
  in {
    assert(wordOffset < rawData.length, "wordOffset is out of header bounds");
    assert(val >> length == 0, "Parameter is out of bounds.");
  }
  body {
    // Shift the value where it will be placed.
    val <<= bitOffset;
    // Create a mask with 1's where the value will be placed.
    uint mask = 0xFFFFFFFF >> (wordBitSize - length) << bitOffset;
    // Zero the bits where the new value will be placed.
    rawData[wordOffset] &= ~mask;
    // Insert the new value;
    rawData[wordOffset] += val;
  }

  private uint getField(alias wordOffset, alias bitOffset, alias length)()
    if (is(typeof(wordOffset) : uint) &&
        is(typeof(bitOffset) : uint) &&
        is(typeof(length) : uint) && bitOffset + length <= wordBitSize)
  in {
    assert(wordOffset < rawData.length, "wordOffset is out of bounds");
  }
  body {
    uint mask = 0xFFFFFFFF >> (32 - length);
    return (rawData[wordOffset] >> bitOffset) & mask;
  }
}

unittest {
  import std.conv;

  /* An example ping packet from the localhost (10.0.2.15) to (4.2.2.2).
     $ sudo tcpdump -c 1 -i any -x ip host 4.2.2.2 &
     $ ping -c 1 4.2.2.2
     0x0000:  4500 0054 0000 4000 4001 2897 0a00 020f
     0x0010:  0402 0202 0800 f704 0a01 0001 e8c8 7850
     0x0020:  0000 0000 cb0c 0c00 0000 0000 1011 1213
     0x0030:  1415 1617 1819 1a1b 1c1d 1e1f 2021 2223
     0x0040:  2425 2627 2829 2a2b 2c2d 2e2f 3031 3233
     0x0050:  3435 3637
  */
  auto header = new IpHeader([0x45000054,   // version, ihl, tos, total_length
                              0x00004000,   // indentification, flags, fragment_offset
                              0x40012897,   // ttl, proto, header_cksm
                              0x0a00020f,   // source_addr
                              0x04020202]); // dest_addr

  // Compare our header checksum calculations against a real packet.
  assert(header.calculateHeaderChecksum() == 0x2897,
         "Calculated Header Checksum " ~ to!string(header.calculateHeaderChecksum())
         ~ ", expected " ~ to!string(0x2897));

  // Check that length calculations are correct.
  assert(header.calculateTotalLength(new uint[10]) == 60,
         "Calculated Total Length = " ~ to!string(header.calculateTotalLength(new uint[10]))
         ~ ", expected " ~ to!string(60));
  
  assert(header.getVersion() == 0x4);
  header.setVersion(0xa);
  assert(header.getVersion() == 0xa);

  assert(header.getHeaderLength() == 0x5);
  header.setHeaderLength(0xd);
  assert(header.getHeaderLength() == 0xd);
}