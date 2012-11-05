import std.typecons;
import std.csv;

import ipheader;
import ipdatagram;
import ipaddress;
import node;
import ipnetport;

debug import std.stdio;


/**
 * A routing node capable of delivering traffic to specific ports.
 */
class RouterNode : Node {
  uint[uint] addressPortMap;

  this(uint numPorts) {
    foreach (portIndex ; 0 .. numPorts) {
      // The router ports have no address.
      auto ipNetPort = new IpNetPort();
      addIpNetPort(ipNetPort);
    }
  }

  /// Initialie the IP to Port routing table from a file.
  void loadAddressPortMapFromCSV(string text) {
    // The file contains (IP, port) pairs.
    uint[uint] addressPortMap;
    foreach (route ; csvReader!(Tuple!(string, uint))(text)) {
      IpAddress address = route[0];
      uint port = route[1];
      debug writeln("routerNode.loadAddressPortMapFromCSV(): Adding route: ",
                    route[0], " => ", route[1]);
      addressPortMap[address.value] = port;
    }
    setAddressPortMap(addressPortMap);
  }

  void setAddressPortMap(uint[uint] addressPortMap) {
    this.addressPortMap = addressPortMap;
  }

  // Read traffic from ipNetPorts and redirect it to another ipNetPort.
  void run() {
    // Check for visible IpDatagrams.
    auto ipNetPorts = getIpNetPorts();
    foreach (srcPortIndex, ipNetPort ; ipNetPorts) {
      debug writeln("routernode.run(): Checking netport: ", srcPortIndex);
      while (ipNetPort.hasData()) {
        IpDatagram ipDatagram = ipNetPort.receive();
        debug writeln("routernode.run(): Routing packet.");
        forwardDatagram(ipDatagram);
      }
    }
    debug writeln("routernode.run(): Done.");
  }

  private void forwardDatagram(IpDatagram ipDatagram) {
    // Now find what port it goes to, if any at all.
    uint destAddr = ipDatagram.getIpHeader().getDestinationAddress();

    // If we do not have a route, drop the datagram.
    if (destAddr !in addressPortMap)
      return;

    uint port = addressPortMap[destAddr];
    debug writeln("routernode.run(): Sending to port ", port);
    auto destIpNetPort = getIpNetPort(port);

    auto ipHeader = ipDatagram.getIpHeader();
    auto newTimeToLive = ipHeader.getTimeToLive() - 1;
    ipHeader.setTimeToLive(newTimeToLive);
    destIpNetPort.send(ipDatagram);
  }
}

unittest {
  debug writeln("-- unittest: ", __FILE__, " --");
  import net;

  class TestIpNetPort : IpNetPort {
    uint counter = 0;
    override void update() {
      debug writeln("TestIpNetPort packet seen.");
      counter++;
      super.update();
    }
  }

  auto routerNode = new RouterNode(3);

  auto net0 = new Net();
  net0.attach(routerNode.getIpNetPort(0));
  auto np0 = new TestIpNetPort();
  net0.attach(np0);

  auto net1 = new Net();
  net1.attach(routerNode.getIpNetPort(1));
  auto np1 = new TestIpNetPort();
  net1.attach(np1);

  auto net2 = new Net();
  net2.attach(routerNode.getIpNetPort(2));
  auto np2 = new TestIpNetPort();
  net2.attach(np2);

  // Load the
  string addressPortMapCSV = q"EOS
10.0.0.1,0
10.0.0.2,0
10.0.0.3,1
10.0.0.4,2
EOS";
  routerNode.loadAddressPortMapFromCSV(addressPortMapCSV);

  // Now we inject traffic on various networks, and see if the router
  // passes it along appropriately.
  auto ipHeader = new IpHeader();
  ipHeader.setSourceAddress(IpAddress("10.0.0.2").value);
  ipHeader.setDestinationAddress(IpAddress("10.0.0.3").value);
  auto ipDatagram = new IpDatagram(ipHeader, [1u, 2u, 3u]);
  auto ttl = ipDatagram.getIpHeader().getTimeToLive();
  net0.setDatagram(ipDatagram.datagram);
  net0.notify();

  routerNode.run();
  
  assert(np0.counter == 1);  // Just to make sure we hit the wire.
  assert(np1.counter == 1);  // Check if the router did its job.

  // Also make sure that the TTL was decremented.
  auto np0Datagram = np0.receive();
  auto np1Datagram = np1.receive();

  debug writeln("np0Datagram ttl = ", np0Datagram.getIpHeader().getTimeToLive());
  debug writeln("np1Datagram ttl = ", np1Datagram.getIpHeader().getTimeToLive());
  assert(np1Datagram.getIpHeader().getTimeToLive() ==
         np0Datagram.getIpHeader().getTimeToLive() - 1);
}