import link;
import ipdatagram;
import ipheader;

debug import std.stdio;

/// A wrapper for a basic link that uses IpDatagram.
class IpLink {
  this(Link link) {
    this.link = link;
  }

  /// Peek for an IP Header and read the IpDatagram.
  IpDatagram receive() {
    uint[5] headerData = link.peek(IpHeader.headerWords);
    //auto header = IpHeader(link.peek(IpHeader.headerWords));
    auto header = IpHeader(headerData);
    uint totalLength = header.getTotalLength();
    uint totalWords = header.getTotalLength / uint.sizeof;
    // We already read the header, the data comes afterwards you silly goose!
    debug writefln("Attempting to read %d words.", totalWords);
    uint[] data = link.receive(totalWords)[IpHeader.headerWords .. totalWords];

    return IpDatagram(header, data);
  }

  /// Initialize and send an IpDatagram.
  void send(IpDatagram datagram) {
    datagram.init();                    // This computes length and checksums.
    debug writeln("Sending datagram has TotalLength = ", datagram.header.getTotalLength());
    link.send(datagram.header.rawData); // First send the header.
    link.send(datagram.data);           // Then the data.
  }

private:
  // The link we are wrapping.
  Link link;
}

unittest {
  // Imports used during testing.
  import buffer;

  // Create a raw link to wrap around.
  auto receiveBuffer = new Buffer!uint();
  auto sendBuffer = new Buffer!uint();

  auto forwardLink = new Link(receiveBuffer, sendBuffer);
  auto backwardLink = new Link(sendBuffer, receiveBuffer);

  // Initialize our IpLink around the raw link.
  auto localIpLink = new IpLink(forwardLink);
  auto remoteIpLink = new IpLink(backwardLink);

  // Now create dummy data to send.
  auto ipDatagram = IpDatagram(IpHeader(), [10u, 11u, 12u, 13u]);
  ipDatagram.init();

  // Send the data and see if it gets picked up intact.
  debug writeln("Sending ipDatagram");
  localIpLink.send(ipDatagram);
  debug writeln("Receiving datagram");
  auto testIpDatagram = remoteIpLink.receive();

  debug writeln("ipDatagram = ", ipDatagram);
  debug writeln("testIpDatagram = ", testIpDatagram);
  assert(ipDatagram !is testIpDatagram);
  assert(ipDatagram.header == testIpDatagram.header);
  assert(ipDatagram.data == testIpDatagram.data);
}