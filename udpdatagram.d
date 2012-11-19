import ipheader;
import udpheader;
import ipdatagram;

debug import std.stdio;


/**
 * A datagram with an IP and UDP header.
 * Serialization, length, and checksum logic are taken care of here.
 */
class UdpDatagram : IpDatagram {
  UdpHeader udpHeader;
  uint[] udpData;

  immutable uint udpHeaderOffset = IpHeader.headerWords;
  immutable uint udpDataOffset = udpHeaderOffset + UdpHeader.headerWords;

  invariant() {
    // Make sure our header/data merely point to slices of the datagram.
    assert(udpHeader !is null);
    assert(datagram[udpHeaderOffset..udpDataOffset] is udpHeader.rawData);
    assert(datagram[udpDataOffset..$] is udpData);
  }

  this() {
    // Create a new datagram with enough space for the UDP header.
    super(new IpHeader(), (new uint[UdpHeader.headerWords]));
    udpHeader = new UdpHeader(datagram[udpHeaderOffset..udpDataOffset]);
    // Copy initial contents of a fresh header into memory.
    udpHeader.rawData[0..UdpHeader.headerWords] =
      (new UdpHeader()).rawData[0..UdpHeader.headerWords];
    udpData = datagram[udpDataOffset..$];
    // Perform length and checksum calculations.
    init();
  }

  this(uint[] datagram)
  in {
    assert(datagram.length >= udpDataOffset,
           "Datagram is too short to be a UDP packet.");
  }
  body {
    udpHeader = new UdpHeader(datagram[udpHeaderOffset..udpDataOffset]);
    udpData = datagram[udpDataOffset..$];
    super(datagram);
    init();
  }

  this (IpHeader ipHeader, UdpHeader udpHeader, uint[] data) {
    this(ipHeader.rawData ~ udpHeader.rawData ~ data);
  }

  private void initUdpHeader() {
    udpHeader.init(getIpHeader(), getUdpData());
  }

  // Re-calculate lengths and checksums.
  override void init() {
    super.init();
    initUdpHeader();
  }

  UdpHeader getUdpHeader() {
    return udpHeader;
  }

  uint[] getUdpData() {
    return udpData;
  }
}

// Check that the UdpDatagram does not duplicate memory.
unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  auto ipHeader = new IpHeader();
  ipHeader.setSourceAddress(12345);
  ipHeader.setDestinationAddress(67890);

  auto udpHeader = new UdpHeader();
  udpHeader.setSourcePort(4422);
  udpHeader.setDestinationPort(8899);

  uint[] data = [1, 2, 3, 4];

  // Create an initial datagram to copy around.
  auto udpDatagram1 = new UdpDatagram(ipHeader, udpHeader, data);

  // Now create an IpDatagram which we will use to init a UdpDatagram.
  auto ipDatagram1 = new IpDatagram(udpDatagram1.datagram);
  auto udpDatagram2 = new UdpDatagram(ipDatagram1.datagram);

  // Check that no memory was duplicated.
  assert(udpDatagram2.datagram is ipDatagram1.datagram);
  // Some basic data integrity.
  assert(udpDatagram2.getIpHeader.getSourceAddress() == 12345);
  assert(udpDatagram2.getUdpHeader.getSourcePort() == 4422);
  assert(udpDatagram2.getUdpData() == data);
}

unittest {
  // Create a default datagram for giggles.
  auto udpDatagram = new UdpDatagram();
}