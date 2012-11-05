import ipheader;

class IpDatagram {
  // The entire datagram.
  uint[] datagram;

  // The header portion of the datagram.
  IpHeader header;
  // The data portion of the datagram.
  uint[] data;

  invariant() {
    // Make sure our header/data merely point to slices of the datagram.
    assert(datagram[0..IpHeader.headerWords] is header.rawData);
    assert(datagram[IpHeader.headerWords..$] is data);
  }

  this() {
    datagram = new uint[IpHeader.headerWords];
    header = new IpHeader(datagram[0..IpHeader.headerWords]);
    // Copy initial contents of a fresh header into memory.
    header.rawData[0..IpHeader.headerWords] =
      (new IpHeader()).rawData[0..IpHeader.headerWords];
    // This is just here for completeness, there is no data yet.
    data = datagram[IpHeader.headerWords .. $];
    // Perform length and checksum calculations.
    init();
  }

  this(uint[] datagram)
  in {
    assert(datagram.length >= IpHeader.headerWords,
           "Datagram is too short to be an IP packet.");
  }
  body {
    this.datagram = datagram;
    header = new IpHeader(datagram[0..IpHeader.headerWords]);
    data = datagram[IpHeader.headerWords .. $];
    init();
  }

  this(IpHeader ipHeader, uint[] data) {
    this(ipHeader.rawData ~ data);
  }

  // Re-calculate the IP header including the checksum.
  void init() {
    header.init(data);
  }

  IpHeader getIpHeader() {
    return header;
  }

  uint[] getData() {
    return data;
  }

}

unittest {
  IpHeader ipHeader = new IpHeader();
  ipHeader.init([]);
  IpDatagram ipDatagram = new IpDatagram();
  // Make sure the header is in a sane state.
  assert(ipDatagram.getIpHeader().rawData == ipHeader.rawData);
  assert(ipDatagram.getData().length == 0);
}

unittest {
  IpHeader ipHeader = new IpHeader();
  uint[] data = [1, 2, 3, 4];
  IpDatagram ipDatagram = new IpDatagram(ipHeader.rawData ~ data);
  assert(ipDatagram.getIpHeader().getTotalLength() == 36);
  assert(ipDatagram.getData() == data);
}

unittest {
  IpHeader ipHeader = new IpHeader();
  uint[] data = [1, 2, 3, 4];
  IpDatagram ipDatagram = new IpDatagram(ipHeader, data);
  assert(ipDatagram.getIpHeader().getTotalLength() == 36);
  assert(ipDatagram.getData() == data);
}