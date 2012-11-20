import ipnetport;
import ipaddress;

/**
 * A class representing a simple network node that can send/receive datagrams.
 */
class Node {
  IpNetPort[] ipNetPorts;

  this() {
  }

  this(IpAddress[] ipAddressList) {
    foreach (ipAddress ; ipAddressList) {
      auto ipNetPort = new IpNetPort();
      ipNetPort.setAddress(ipAddress);
      addIpNetPort(ipNetPort);
    }
  }

  void addIpNetPort(IpNetPort ipNetPort) {
    ipNetPorts ~= ipNetPort;
  }

  IpNetPort getIpNetPort(int netPortIndex) {
    return ipNetPorts[netPortIndex];
  }

  IpNetPort[] getIpNetPorts() {
    return ipNetPorts;
  }

  /// A function run every cycle that specifies node behaviour.
  abstract void run();
}
