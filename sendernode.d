import ipheader;
import ipdatagram;
import ipaddress;
import node;
import ipnetport;


/**
 * A simple 1-NetPort node that sends a new IpDatagram each time it runs.
 */
class SenderNode : Node {
  // The data payload and counter for how many packets are sent.
  uint counter = 0;
  // A reference header used to create new IpDatagrams.
  IpHeader ipHeader;

  this(IpAddress address, IpAddress destinationAddress) {
    // Create our single IpNetPort.
    auto ipNetPort = new IpNetPort();
    ipNetPort.setAddress(address);
    addIpNetPort(ipNetPort);

    // Initialize our template header.
    ipHeader = new IpHeader();
    ipHeader.setSourceAddress(address.value);
    ipHeader.setDestinationAddress(destinationAddress.value);
  }

  void run() {
    // Check for any incoming data and ignore it.
    auto ipNetPort = getIpNetPort(0);
    while (ipNetPort.hasData()) {
      ipNetPort.receive();
    }

    // Now send out our all-important message.
    auto ipDatagram = new IpDatagram(ipHeader, [counter]);
    ipNetPort.send(ipDatagram);

    counter++;
  }
}