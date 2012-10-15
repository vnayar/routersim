import link;

// Imports used during testing.
unittest import node;

/// A wrapper for a basic link that uses IpDatagram.
class IpLink {
  this(Link link) {
    this.link = link;
  }

  /// Peek for an IP Header and read the IpDatagram.
  IpDatagram receive() {
    IpHeader header = link.peek(IpHeader.headerWords);
    uint totalLength = header.getTotalLength();
    uint totalWords = header.getTotalLength / uint.sizeof;
    // We already read the header, the data comes afterwards you silly goose!
    uint[] data = link.receive(totalWords)[IpHeader.headerWords .. totalWords];

    return IpDatagram(header, data);
  }

  /// Initialize and send an IpDatagram.
  void send(IpDatagram datagram) {
    datagram.init();                    // This computes length and checksums.
    link.send(datagram.header.rawData); // First send the header.
    link.send(datagram.data);           // Then the data.
  }

private:
  // The link we are wrapping.
  Link link;
}

unittest {
  auto sendBuffer = new Buffer!uint();
  auto receiveBuffer = new Buffer!uint();
}