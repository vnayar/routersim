import net;
import ipaddress;
import ipnetport;

debug import std.stdio;


/**
 * A net with special logic to get directly connected addresses.
 * This object performs logic that serves the same role as a protocol like ARP.
 */
class IpNet : Net {
  IpAddress[] getAttachedIpAddressList() {
    IpAddress[] ipAddressList;
    foreach (netPort ; _netPortList) {
      auto ipNetPort = cast(IpNetPort) netPort;
      if (ipNetPort !is null) {
        ipAddressList ~= ipNetPort.getAddress();
      }
    }
    return ipAddressList;
  }
}

unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  import std.algorithm;

  auto ipNet = new IpNet();

  auto ipNetPort1 = new IpNetPort();
  ipNetPort1.setAddress(IpAddress("10.0.0.1"));
  ipNet.attach(ipNetPort1);

  auto ipNetPort2 = new IpNetPort();
  ipNetPort2.setAddress(IpAddress("10.0.0.2"));
  ipNet.attach(ipNetPort2);

  auto ipNetPort3 = new IpNetPort();
  ipNetPort3.setAddress(IpAddress("10.0.0.3"));
  ipNet.attach(ipNetPort3);

  auto ipAddressList = ipNet.getAttachedIpAddressList();

  assert(ipAddressList.length == 3);
  assert(find(ipAddressList, IpAddress("10.0.0.2")).length >= 1);
  assert(find(ipAddressList, IpAddress("10.0.0.4")).length == 0);
}