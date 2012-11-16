import ipheader;
import tcpheader;
import ipdatagram;

debug import std.stdio;


/**
 * A datagram with an IP and TCP header.
 * Serialization, length, and checksum logic are taken care of here.
 */
class TcpDatagram : IpDatagram {
  TcpHeader tcpHeader;
  uint[] tcpData;

  immutable uint tcpHeaderOffset = IpHeader.headerWords;
  immutable uint minTcpDataOffset = tcpHeaderOffset + TcpHeader.minTcpHeaderWords;

  invariant() {
    // Make sure our header/data merely point to slices of the datagram.
    assert(tcpHeader !is null);
    auto tcpDataOffset = getTcpDataOffset();
    assert(datagram[tcpHeaderOffset..tcpDataOffset] is tcpHeader.rawData);
    assert(datagram[tcpDataOffset..$] is tcpData);
  }

  private uint getTcpDataOffset() const
    out (offset) {
        assert(offset >= TcpHeader.minTcpHeaderWords);
    }
  body {
    return tcpHeaderOffset + tcpHeader.getDataOffset();
  }

  this() {
    // Create a new datagram with enough space for the UDP header.
    super(new IpHeader(), (new uint[TcpHeader.headerWords]));
    tcpHeader = new TcpHeader(datagram[tcpHeaderOffset..minTcpDataOffset]);
    // Copy initial contents of a fresh header into memory.
    tcpHeader.rawData[] = (new TcpHeader()).rawData[];
    tcpData = datagram[minTcpDataOffset..$];
    // Perform length and checksum calculations.
    init();
  }

  this(uint[] datagram)
    in {
      assert(datagram.length >= minTcpDataOffset,
             "Datagram is too short to be a TCP packet.");
    }
  body {
    tcpHeader = new TcpHeader(datagram[tcpHeaderOffset..minTcpDataOffset]);
    // Check for options, and resize the header if need be.
    if (tcpHeader.getDataOffset() != TcpHeader.minTcpHeaderWords)
      tcpHeader = new TcpHeader(datagram[tcpHeaderOffset..getTcpDataOffset()]);
    tcpData = datagram[getTcpDataOffset()..$];
    super(datagram);
    init();
  }

  this (IpHeader ipHeader, TcpHeader tcpHeader, uint[] data) {
    this(ipHeader.rawData ~ tcpHeader.rawData ~ data);
  }

  private void initTcpHeader() {
    tcpHeader.init(getIpHeader(), getTcpData());
  }

  // Re-calculate lengths and checksums.
  override void init() {
    super.init();
    initTcpHeader();
  }

  TcpHeader getTcpHeader() {
    return tcpHeader;
  }

  uint[] getTcpData() {
    return tcpData;
  }
}

// Check that the UdpDatagram does not duplicate memory.
unittest {
  auto ipHeader = new IpHeader();
  ipHeader.setSourceAddress(12345);
  ipHeader.setDestinationAddress(67890);

  auto tcpHeader = new TcpHeader();
  tcpHeader.setSourcePort(4422);
  tcpHeader.setDestinationPort(8899);

  uint[] data = [1, 2, 3, 4];

  // Create an initial datagram to copy around.
  auto tcpDatagram1 = new TcpDatagram(ipHeader, tcpHeader, data);

  // Now create an IpDatagram which we will use to init a UdpDatagram.
  auto ipDatagram1 = new IpDatagram(tcpDatagram1.datagram);
  auto tcpDatagram2 = new TcpDatagram(ipDatagram1.datagram);

  // Check that no memory was duplicated.
  assert(tcpDatagram2.datagram is ipDatagram1.datagram);
  // Some basic data integrity.
  assert(tcpDatagram2.getIpHeader.getSourceAddress() == 12345);
  assert(tcpDatagram2.getTcpHeader.getSourcePort() == 4422);
  assert(tcpDatagram2.getTcpData() == data);
}

unittest {
  // Create a default datagram for giggles.
  auto tcpDatagram = new TcpDatagram();
}