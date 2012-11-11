import ipheader;

debug import std.stdio;


/**
 * A UDP Header and associated functions following RFC768.
 */
class UdpHeader {
  static immutable uint wordBitSize = uint.sizeof * 8;   // In bits
  static immutable uint wordByteSize = uint.sizeof;      // In bytes
  static immutable uint headerWords = 2;                 // In words

  // The raw header in 32-bit word.
  uint[] rawData;

  this() {
    rawData.length = headerWords;
    setSourcePort(0);
  }

  this(uint[] rawData) {
    this.rawData = rawData;
  }

  void init(IpHeader ipHeader, uint[] data) {
    setChecksum(calculateChecksum(ipHeader, data));
  }

  // Getter/setter functions for SourcePort.
  alias getField!(0, 16, 16) getSourcePort;
  alias setField!(0, 16, 16) setSourcePort;

  // Getter/setter functions for DestinationPort.
  alias getField!(0, 0, 16) getDestinationPort;
  alias setField!(0, 0, 16) setDestinationPort;

  // The length of the header and the data in octets.
  alias getField!(1, 16, 16) getLength;
  alias setField!(1, 16, 16) setLength;

  // Getter/setter functions for the CheckSum.
  alias getField!(1, 0, 16) getChecksum;
  alias setField!(1, 0, 16) setChecksum;

  // The UDP checksum includes information from the IP header and the data.
  uint calculateChecksum(IpHeader ipHeader, uint[] data) {
    uint checksum = 0;
    
    // First add in the pseudo-header from RFC768.
    debug writefln("getSourceAddress() = %x", ipHeader.getSourceAddress());
    checksum += 0x0000FFFF & ipHeader.getSourceAddress();
    checksum += ipHeader.getSourceAddress() >> 16;
    debug writefln("getDestinationAddress() = %x", ipHeader.getDestinationAddress());
    checksum += 0x0000FFFF & ipHeader.getDestinationAddress();
    checksum += ipHeader.getDestinationAddress() >> 16;
    debug writefln("getProtocol() = %x", ipHeader.getProtocol());
    checksum += ipHeader.getProtocol();
    debug writefln("getLength() = %x", getLength());
    checksum += getLength();

    debug writefln("PseudoHeader checksum = %x", checksum);

    // Next add in the UDP header.
    foreach (wordIndex ; 0 .. rawData.length) {
      checksum += 0x0000FFFF & rawData[wordIndex];
      checksum += rawData[wordIndex] >> 16;
    }
    checksum -= getChecksum(); // For calculation purposes, checksum = 0.
    debug writefln("  with UDP Header = %x", checksum);

    // And now the data.
    foreach (wordIndex ; 0 .. data.length) {
      checksum += 0x0000FFFF & data[wordIndex];
      checksum += data[wordIndex] >> 16;
    }
    debug writefln("  with Data = %x", checksum);

    // Add in any overflow for one's complement.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);
    // And make sure the overflow doesn't cause another overflow.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);

    debug writefln("  with overflow = %x", checksum);

    // Get the one's complement of the sum thus far.
    checksum = ~checksum & 0x0000FFFF;

    debug writefln("Complement = %x", checksum);

    // Zero is a reserved special value (unused checksum), use 0xFFFF instead.
    if (checksum == 0x00000000)
      return 0x0000FFFF;
    return checksum;
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

// Unit Tests against a real captured UDP header.
unittest {
  // 21:15:52.454036 IP 10.0.2.3.53 > 10.0.2.15.32014:
  //   39936 NXDomain*- 0/0/0 (48)
  uint[] udpDatagram = [
    // IP Header
    0x4510004c, 0x05c30000, 0x40115cbd, 0x0a000203, 0x0a00020f,
    // UDP Header
    0x00357d0e, 0x00386dd9,
    // Data
    0x9c008503, 0x00010000, 0x00000000, 0x08636c69, 0x656e7433,
	  0x37076472, 0x6f70626f, 0x7803636f, 0x6d053130, 0x67656e03,
    0x636f6d00, 0x00010001
  ];

  auto ipHeader = new IpHeader(udpDatagram[0..IpHeader.headerWords]);
  auto dataOffset = IpHeader.headerWords + UdpHeader.headerWords;
  auto rawUdpHeader = udpDatagram[IpHeader.headerWords..dataOffset];
  auto data = udpDatagram[dataOffset..$];

  auto udpHeader = new UdpHeader(rawUdpHeader);

  // Check getter methods.
  assert(udpHeader.getSourcePort() == 53, "Source Port Error");
  assert(udpHeader.getDestinationPort() == 32014, "Destination Port Error");
  assert(udpHeader.getLength() == 0x38, "UDP Length Error");
  assert(udpHeader.getChecksum() == 0x6dd9, "UDP Checksum Error");

  // Check checksum calculations.
  debug writefln("Calculated Checksum = %x",
                udpHeader.calculateChecksum(ipHeader, data));
  assert(udpHeader.calculateChecksum(ipHeader, data) == 0x6dd9,
         "Calculate Checksum error.");
}