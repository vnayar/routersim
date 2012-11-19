import ipheader;

debug import std.stdio;


/**
 * A datagram with an IP header.
 * Serialization, length, and checksum logic are taken care of here.
 */
class IpDatagram {
  // The entire datagram.
  uint[] datagram;

  // The header portion of the datagram.
  IpHeader ipHeader;
  // The data portion of the datagram.
  uint[] ipData;

  invariant() {
    // Make sure our header/data merely point to slices of the datagram.
    assert(datagram[0..IpHeader.headerWords] is ipHeader.rawData);
    assert(datagram[IpHeader.headerWords..$] is ipData);
  }

  this() {
    datagram = new uint[IpHeader.headerWords];
    ipHeader = new IpHeader(datagram[0..IpHeader.headerWords]);
    // Copy initial contents of a fresh header into memory.
    ipHeader.rawData[0..IpHeader.headerWords] =
      (new IpHeader()).rawData[0..IpHeader.headerWords];
    // This is just here for completeness, there is no data yet.
    ipData = datagram[IpHeader.headerWords .. $];
    // Perform length and checksum calculations.
    initIpHeader();
  }

  this(uint[] datagram)
  in {
    assert(datagram.length >= IpHeader.headerWords,
           "Datagram is too short to be an IP packet.");
  }
  body {
    this.datagram = datagram;
    ipHeader = new IpHeader(datagram[0..IpHeader.headerWords]);
    ipData = datagram[IpHeader.headerWords .. $];
    initIpHeader();
  }

  this(IpHeader ipHeader, uint[] data) {
    this(ipHeader.rawData ~ data);
  }

  private void initIpHeader() {
    ipHeader.init(ipData);
  }

  // Re-calculate the IP header including the checksum.
  void init() {
    initIpHeader();
  }

  IpHeader getIpHeader() {
    return ipHeader;
  }

  uint[] getIpData() {
    return ipData;
  }

}

// Test the default constructor.
unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  IpHeader ipHeader = new IpHeader();
  ipHeader.init([]);
  IpDatagram ipDatagram = new IpDatagram();
  // Make sure the header is in a sane state.
  assert(ipDatagram.getIpHeader().rawData == ipHeader.rawData);
  assert(ipDatagram.getIpData().length == 0);
}

// Test the raw-data constructor.
unittest {
  IpHeader ipHeader = new IpHeader();
  uint[] data = [1, 2, 3, 4];
  IpDatagram ipDatagram = new IpDatagram(ipHeader.rawData ~ data);
  assert(ipDatagram.getIpHeader().getTotalLength() == 36);
  assert(ipDatagram.getIpData() == data);
}

// Test the (Header, Data) constructor.
unittest {
  IpHeader ipHeader = new IpHeader();
  uint[] data = [1, 2, 3, 4];
  IpDatagram ipDatagram = new IpDatagram(ipHeader, data);
  assert(ipDatagram.getIpHeader().getTotalLength() == 36);
  assert(ipDatagram.getIpData() == data);
}