import ipnetport;

/**
 * A class representing a simple network node that can send/receive datagrams.
 */
class Node {
  IpNetPort[] ipNetPorts;

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
