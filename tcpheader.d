import header;
import ipheader;

debug import std.stdio;


/**
 * A TCP Header and associated functions following RFC793.
 */
class TcpHeader : Header {
  static immutable uint headerWords = 5;                 // In words
  static immutable uint minTcpHeaderWords = 5;

  this() {
    rawData.length = headerWords;
    setDataOffset(minTcpHeaderWords);
  }

  this(uint[] rawData) {
    super(rawData);
  }

  void init(IpHeader ipHeader, uint[] data) {
    setChecksum(calculateChecksum(ipHeader, data));
  }

  alias getField!(0, 16, 16) getSourcePort;
  alias setField!(0, 16, 16) setSourcePort;

  alias getField!(0, 0, 16) getDestinationPort;
  alias setField!(0, 0, 16) setDestinationPort;

  uint getSequenceNumber() {
    return rawData[1];
  }
  void setSequenceNumber(uint num) {
    rawData[1] = num;
  }

  uint getAcknowledgementNumber() {
    return rawData[2];
  }
  void setAcknowledgementNumber(uint num) {
    rawData[2] = num;
  }

  alias getField!(3, 28, 4) getDataOffset;
  alias setField!(3, 28, 4) setDataOffset;

  alias getField!(3, 16, 6) getFlags;
  alias setField!(3, 16, 6) setFlags;

  alias getField!(3, 0, 16) getWindow;
  alias setField!(3, 0, 16) setWindow;

  alias getField!(4, 16, 16) getChecksum;
  alias setField!(4, 16, 16) setChecksum;

  alias getField!(4, 0, 16) getUrgentPointer;
  alias setField!(4, 0, 16) setUrgentPointer;

  // The TCP checksum includes information from the Ip header and the data.
  uint calculateChecksum(IpHeader ipHeader, uint[] data) {
    uint checksum = 0;

    // First add in the pseudo-header from RFC793.
    checksum += 0x0000FFFF & ipHeader.getSourceAddress();
    checksum += ipHeader.getSourceAddress() >> 16;
    checksum += 0x0000FFFF & ipHeader.getDestinationAddress();
    checksum += ipHeader.getDestinationAddress() >> 16;
    checksum += ipHeader.getProtocol();
    // The TCP Length is not part of the TCP fields, it is computed.
    checksum += ipHeader.getTotalLength() - wordByteSize * IpHeader.headerWords;
    debug writeln("TCP Length = ", 
                  ipHeader.getTotalLength() - wordByteSize * IpHeader.headerWords);
    debug writefln("Pseudo Header Checksum = %x", checksum);

    // Add in the TCP header.
    foreach (wordIndex ; 0 .. rawData.length) {
      checksum += 0x0000FFFF & rawData[wordIndex];
      checksum += rawData[wordIndex] >> 16;
    }
    checksum -= getChecksum(); // For calculation purposes, checksum = 0.
    debug writefln("TCP Header Checksum = %x", checksum);

    // And now the data.
    foreach (wordIndex ; 0 .. data.length) {
      checksum += 0x0000FFFF & data[wordIndex];
      checksum += data[wordIndex] >> 16;
    }
    debug writefln("Data Checksum = %x", checksum);

    // Add in any overflow for one's complement.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);
    // And make sure the overflow doesn't cause another overflow.
    checksum = (checksum >> 16) + (checksum & 0x0000FFFF);
    debug writefln("Remove Carry Checksum = %x", checksum);

    // Get the one's complement of the sum thus far.
    checksum = ~checksum & 0x0000FFFF;
    debug writefln("One's Complement Checksum = %x", checksum);

    return checksum;
  }
}

unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  // $ sudo tcpdump -i any -nx tcp port 80
  // $ curl http://ddg.gg
  // 22:04:44.535266 IP 208.94.146.81.80 > 10.0.2.15.54861:
  //   Flags [P.], seq 1:152, ack 159, win 65535, length 151
  uint[] tcpDatagram = [
    // IP Header
    0x450000bf, 0x06870000, 0x400604f4, 0xd05e9251, 0x0a00020f,
    // TCP Header
    0x0050d64d, 0x55d4ec02, 0x3a444079, 0x5018ffff, 0x0bab0000,
    // Data
    0x48545450, 0x2f312e31, 0x20333031, 0x204d6f76, 0x65642050,
    0x65726d61, 0x6e656e74, 0x6c790d0a, 0x53657276, 0x65723a20,
    0x41706163, 0x68652d43, 0x6f796f74, 0x652f312e, 0x310d0a4c,
    0x6f636174, 0x696f6e3a, 0x20687474, 0x70733a2f, 0x2f647563,
    0x6b647563, 0x6b676f2e, 0x636f6d0d, 0x0a436f6e, 0x74656e74,
    0x2d4c656e, 0x6774683a, 0x20300d0a, 0x44617465, 0x3a204672,
    0x692c2031, 0x36204e6f, 0x76203230, 0x31322030, 0x333a3034,
    0x3a343720, 0x474d540d, 0x0a0d0a00
  ];

  auto ipHeader = new IpHeader(tcpDatagram[0..IpHeader.headerWords]);
  auto rawTcpHeader = tcpDatagram[IpHeader.headerWords..$];
  auto tcpHeader = new TcpHeader(rawTcpHeader);

  // Check getter methods.
  assert(tcpHeader.getSourcePort() == 80);
  assert(tcpHeader.getDestinationPort() == 54861);
  assert(tcpHeader.getSequenceNumber() == 0x55d4ec02);
  assert(tcpHeader.getAcknowledgementNumber() == 0x3a444079);
  assert(tcpHeader.getDataOffset() == 0x5);
  assert(tcpHeader.getFlags() == 0x18);
  assert(tcpHeader.getWindow() == 0xffff);
  assert(tcpHeader.getChecksum() == 0x0bab);
  assert(tcpHeader.getUrgentPointer() == 0x0000);

  debug writefln("Calculate Checksum:  Got %x, expected %x.",
          tcpHeader.calculateChecksum(ipHeader, []),
          0x6ee2);
  assert(tcpHeader.calculateChecksum(ipHeader, []) == 0x0bab,
         "Calculate Checksum error.");
}