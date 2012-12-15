import ipheader;
import ipdatagram;
import tcpdatagram;
import ipaddress;
import node;
import ipnetport;

import std.string;

debug import std.stdio;


/**
 * A simple 1-NetPort node that receives IpDatagrams addressed to it.
 */
class ReceiverNode : Node {
  // A debugging counter stating how many packets have been received.
  uint counter;

  this(IpAddress address) {
    // Initialize IpNetPort 0.
    auto ipNetPort = new IpNetPort();
    ipNetPort.setAddress(address);
    addIpNetPort(ipNetPort);
  }

  override void run() {
    // Check for self-destined IpDatagrams.
    auto ipNetPort = getIpNetPort(0);
    while (ipNetPort.hasData()) {
      debug writeln("New Packet.");
      IpDatagram ipDatagram = ipNetPort.receive();
      debug writeln("  Protocol = ", ipDatagram.getIpHeader().getProtocol());
      if (ipDatagram.getIpHeader().getProtocol() == IpHeader.Protocol.TCP) {
        debug writeln("  New TCP Packet.");
        auto tcpDatagram = new TcpDatagram(ipDatagram.datagram);
        if (tcpDatagram.getTcpHeader().getDestinationPort() == 4321) {
          debug writeln("    New TCP Packet with right port.");
          // This is the message we want!
          counter++;
        }
      }
    }
  }

  override string status() {
    return format("received:%4d", counter);
  }
}