import ipheader;
import ipdatagram;
import ipaddress;
import net;
import netport;

debug import std.stdio;


/**
 * A NetPort specialized to handle IP traffic.
 */
class IpNetPort : NetPort {
  IpAddress address;

  /**
   * Filter out self-addressed IpDatagrams.
   */
  override void update() {
    debug writeln("IpNetPort.update()");
    uint[] datagram = getNet().getDatagram();
    auto header = new IpHeader(datagram[0..IpHeader.headerWords]);
    if (header.getSourceAddress() == address.value) {
      debug writeln("IpNetPort.update(): Dropping self-addressed datagram.");
      return;
    }
    super.update();
  }

  IpAddress getAddress() {
    return address;
  }

  void setAddress(IpAddress address) {
    this.address = address;
  }

  /**
   * Read an entire IpDatagram from the NetPort's internal buffer.
   */
  IpDatagram receive()
  in {
    assert(getBuffer().length() >= IpHeader.headerWords, "Not enough data to read.");
  }
  body {
    auto buffer = getBuffer();
    IpHeader ipHeader = new IpHeader(buffer.peek(IpHeader.headerWords));
    uint totalWords = ipHeader.getTotalLength() / cast(uint) uint.sizeof;
    uint[] datagram = buffer.read(totalWords);
    return new IpDatagram(datagram);
  }

  /**
   * Put an IpDatagram on the Net to be picked up by all attached NetPorts.
   */
  void send(IpDatagram ipDatagram) {
    Net net = getNet();
    net.setDatagram(ipDatagram.datagram);
    net.notify(this);
  }
}

unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  auto net = new Net();
  auto netPort1 = new IpNetPort();
  auto netPort2 = new IpNetPort();
  auto netPort3 = new IpNetPort();

  net.attach(netPort1);
  net.attach(netPort2);
  net.attach(netPort3);

  // Send an IpDatagram from one netport, check if the other receives it.
  IpHeader header = new IpHeader();
  header.setSourceAddress(12345);
  header.setDestinationAddress(67890);

  uint[] data = [1, 2, 3, 4];
  IpDatagram ipDatagram = new IpDatagram(header, data);

  assert(!netPort1.hasData());
  assert(!netPort2.hasData());
  assert(!netPort3.hasData());

  // This should trigger a separate packet to read from netPort1 & netPort2.
  netPort3.send(ipDatagram);

  assert(netPort1.hasData());
  assert(netPort2.hasData());
  assert(!netPort3.hasData());

  IpDatagram dg1 = netPort1.receive();
  IpDatagram dg2 = netPort2.receive();

  // Make sure there is not extra data.
  assert(!netPort1.hasData());
  assert(!netPort1.hasData());

  // Distinct objects.
  assert(dg1 !is dg2);
  // Same content.
  assert(dg1.datagram == dg2.datagram);
  // And uncorrupted.
  assert(dg1.datagram == ipDatagram.datagram);

  // Now add an address to a IpNetPort and see if filtering works.
  netPort1.setAddress(IpAddress(12345));  // Same as source address of ipDatagram.
  netPort1.send(ipDatagram);

  assert(!netPort1.hasData());
  assert(netPort2.hasData());
}