import ipheader;
import ipdatagram;
import ipaddress;
import node;
import ipnetport;

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

  void run() {
    // Check for self-destined IpDatagrams.
    auto ipNetPort = getIpNetPort(0);
    while (ipNetPort.hasData()) {
      IpDatagram ipDatagram = ipNetPort.receive();
      if (ipDatagram.getIpHeader().getDestinationAddress() ==
          ipNetPort.getAddress().value) {
        counter++;
      }
    }
  }
}