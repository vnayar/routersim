import header;
import ipheader;

debug import std.stdio;


/**
 * A UDP Header and associated functions following RFC768.
 */
class UdpHeader : Header {
  static immutable uint headerWords = 2;                 // In words

  this() {
    rawData.length = headerWords;
    setSourcePort(0);
  }
  
  this(uint[] rawData) {
    super(rawData);
  }

  void init(IpHeader ipHeader, uint[] data) {
    setLength(cast(short)(headerWords + data.length) * wordByteSize);
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
    checksum += 0x0000FFFF & ipHeader.getSourceAddress();
    checksum += ipHeader.getSourceAddress() >> 16;
    checksum += 0x0000FFFF & ipHeader.getDestinationAddress();
    checksum += ipHeader.getDestinationAddress() >> 16;
    checksum += ipHeader.getProtocol();
    checksum += getLength();

    // Next add in the UDP header.
    foreach (wordIndex ; 0 .. rawData.length) {
      checksum += 0x0000FFFF & rawData[wordIndex];
      checksum += rawData[wordIndex] >> 16;
    }
    checksum -= getChecksum(); // For calculation purposes, checksum = 0.

    // And now the data.
    foreach (wordIndex ; 0 .. data.length) {
      checksum += 0x0000FFFF & data[wordIndex];
      checksum += data[wordIndex] >> 16;
    }

    // Add in any overflow for one's complement.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);
    // And make sure the overflow doesn't cause another overflow.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);

    // Get the one's complement of the sum thus far.
    checksum = ~checksum & 0x0000FFFF;

    // Zero is a reserved special value (unused checksum), use 0xFFFF instead.
    if (checksum == 0x00000000)
      return 0x0000FFFF;
    return checksum;
  }
}

// Unit Tests against a real captured UDP header.
unittest {
  debug writeln("-- unittest: ", __FILE__, " --");

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