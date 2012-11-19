import ipheader;
import ipaddress;
import ipdatagram;
import udpdatagram;
import udpheader;
import ipnetport;
import node;
import ipnet;
import ripmessage;

debug import std.stdio;


/**
 * A routing node implementing much of RIPv1 protocol in RFC1058.
 * This router is self configuring and will discover nearby routers
 * that speak RIPv1.  Messages are sent on UDP port 520.
 */
class RipRouterNode : Node {
  // Use the same cost for every network.
  immutable uint NETWORK_METRIC_COST = 1;

  // Internal data for keeping track of how packets are routed.
  private struct RouteEntry {
    IpAddress address;
    uint port;
    uint metric;
  }
  // A mapping from destination address to port.
  RouteEntry[uint] addressRouteEntryMap;

  this() {
  }

  this(uint numPorts) {
    foreach (portIndex ; 0 .. numPorts) {
      // The router ports have no address.
      auto ipNetPort = new IpNetPort();
      addIpNetPort(ipNetPort);
    }
  }

  // Read traffic from ipNetPorts and redirect it to another ipNetPort.
  override void run() {
    debug writeln("---- run() ----");
    // Check for visible IpDatagrams.
    auto ipNetPorts = getIpNetPorts();
    foreach (uint srcPortIndex, ipNetPort ; ipNetPorts) {
      debug writeln("routernode.run(): Checking netport: ", srcPortIndex);
      while (ipNetPort.hasData()) {
        IpDatagram ipDatagram = ipNetPort.receive();

        // Check if we have a RIP packet, UDP port 520.
        if (ipDatagram.getIpHeader().getProtocol() == IpHeader.Protocol.UDP) {
          UdpDatagram udpDatagram = new UdpDatagram(ipDatagram.datagram);
          if (udpDatagram.getUdpHeader().getDestinationPort() == 520) {
            // This is a routing message!
            receiveRipMessage(srcPortIndex, udpDatagram);
            continue;
          }
        }

        // Otherwise route normally.
        debug writeln("routernode.run(): Routing packet.");
        forwardDatagram(ipDatagram);
      }
    }

    // Now send out any packets that need sending.
    updateDirectRoutes();
    sendRipResponse();

    debug writeln("routernode.run(): Done.");
  }

  /**
   * Update routing information based upon directly connected networks.
   * Performing this operation depends on data gathered outside of RIP
   * protocol.  On Ethernet, something like ARP is usually used, but in
   * this simulation, similar information is available from IpNet.
   */
  private void updateDirectRoutes() {
    debug writeln("updateDirectRoutes()");
    // Get directly connected addresses.
    foreach (uint ipNetPortIndex, ipNetPort ; getIpNetPorts()) {
      // Initialize routes for all directly connected addresses.
      auto directIpAddressList = getAttachedIpAddressList(ipNetPort);
      foreach (ipAddress ; directIpAddressList) {
        uint metric = NETWORK_METRIC_COST;
        if (ipAddress == ipNetPort.getAddress())
          metric = 0;
          
        // Update or insert new route:  address    port            metric
        auto newRouteEntry = RouteEntry(ipAddress, ipNetPortIndex, metric);
        debug writeln("updateDirectRoutes() - newRouteEntry = ", newRouteEntry);
        addressRouteEntryMap[ipAddress.value] = newRouteEntry;
      }
    }
  }

  // Helper function to find neighbors to an interface.
  private IpAddress[] getAttachedIpAddressList(IpNetPort ipNetPort) {
    auto ipNet = cast(IpNet) ipNetPort.getNet();
    // We must be able to detect neighbor IP addresses for RIP to work.
    if (ipNet is null) {
      throw new Error("Non-IP Net!  Cannot detect neighbors!");
    }

    return ipNet.getAttachedIpAddressList();
  }

  // Process incoming RipMessages and perform routing table updates.
  private void receiveRipMessage(uint port, UdpDatagram udpDatagram) {
    debug writeln("receiveRipMessage()");
    RipMessage ripMessage = new RipMessage();
    ripMessage.unpack(udpDatagram.getUdpData());

    debug writeln("receiveRipMessage() - Test B");
    if (ripMessage.getVersion == 0) // Ignore version 0.
      return;
    // Direct router requests are not supported at the moment.
    if (ripMessage.getCommand() == RipCommand.REQUEST)
      return;

    debug writeln("receiveRipMessage() - Test A");
    // Now we know we are handling a broadcasted response, a routing table.
    debug writeln("ripMessage.getCommand() = ", ripMessage.getCommand());
    debug writeln("udpDatagram.getUdpHeader().getSourcePort() = ",
                  udpDatagram.getUdpHeader().getSourcePort());
    if (ripMessage.getCommand() == RipCommand.RESPONSE) {
      debug writeln("receiveRipMessage() - Test C");
      // Ignore responses that have the wrong source port.
      if (udpDatagram.getUdpHeader().getSourcePort() != 520)
        return;
      debug writeln("receiveRipMessage() - processing");
      // TODO:  Check source address to see if it is directly connected.
      // Now process the routes.
      foreach (ripRoute ; ripMessage.getRoutes()) {
        if (ripRoute.metric < RipRoute.METRIC_INFINITY)
          ripRoute.metric += NETWORK_METRIC_COST;
        // If there is a better route, add it to our routing table.
        if (ripRoute.address.value !in addressRouteEntryMap ||
            ripRoute.metric < addressRouteEntryMap[ripRoute.address.value].metric) {
          auto newRouteEntry = RouteEntry(ripRoute.address, port, ripRoute.metric);
          debug writeln("Adding newRouteEntry = ", newRouteEntry);
          addressRouteEntryMap[ripRoute.address.value] = newRouteEntry;
        }
      }
    }
  }

  // Build a RIP message from the current routing table.
  private void sendRipResponse() {
    debug writeln("sendRipResponse()");
    RipMessage ripMessage = new RipMessage();
    ripMessage.setCommand(RipCommand.RESPONSE);
    foreach (RouteEntry routeEntry ; addressRouteEntryMap) {
      debug writeln("sendRipReponse() - routeEntry = ", routeEntry);
      ripMessage.addRoute(routeEntry.address, routeEntry.metric);
    }

    // Now package the packet for export.
    uint[] ripData = ripMessage.pack();
    auto udpHeader = new UdpHeader();
    udpHeader.setSourcePort(520);
    udpHeader.setDestinationPort(520);

    // Generate UDP packets for each interface.
    foreach (ipNetPort ; getIpNetPorts()) {
      auto ipHeader = new IpHeader();
      ipHeader.setProtocol(IpHeader.Protocol.UDP);
      ipHeader.setSourceAddress(ipNetPort.getAddress().value);

      // Send a message to every host on the same net as the interface.
      auto directIpAddressList = getAttachedIpAddressList(ipNetPort);
      foreach (ipAddress ; directIpAddressList) {
        // Don't send to ourselves, silly!
        if (ipAddress == ipNetPort.getAddress())
          continue;

        ipHeader.setDestinationAddress(ipAddress.value);

        auto udpDatagram = new UdpDatagram(ipHeader, udpHeader, ripData);
        // Send the message out.
        ipNetPort.send(udpDatagram);
      }
    }

  }

  private void forwardDatagram(IpDatagram ipDatagram) {
    debug writeln("forwardDatagram()");
    // Now find what port it goes to, if any at all.
    uint destAddr = ipDatagram.getIpHeader().getDestinationAddress();

    // If we do not have a route, drop the datagram.
    if (destAddr !in addressRouteEntryMap)
      return;

    uint port = addressRouteEntryMap[destAddr].port;
    debug writeln("routernode.run(): Sending to port ", port);
    auto destIpNetPort = getIpNetPort(port);

    auto ipHeader = ipDatagram.getIpHeader();
    auto newTimeToLive = ipHeader.getTimeToLive() - 1;
    ipHeader.setTimeToLive(newTimeToLive);
    destIpNetPort.send(ipDatagram);
  }
}

unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  import net;

  class TestIpNetPort : IpNetPort {
    uint counter = 0;
    override void update() {
      debug writeln("TestIpNetPort packet seen.");
      counter++;
      super.update();
    }
  }

  // Create a small line of routers.
  // +-----------+ ipNet12  +-----------+ ipNet23  +-----------+
  // |routerNode1|<-------->|routerNode2|<-------->|routerNode3|
  // +-----------+          +-----------+          +-----------+
  //       10.0.0.1    10.0.0.2     10.0.1.2    10.0.1.3
  auto ipNetPort11 = new IpNetPort();
  ipNetPort11.setAddress(IpAddress("10.0.0.1"));
  auto ipNetPort21 = new IpNetPort();
  ipNetPort21.setAddress(IpAddress("10.0.0.2"));

  auto ipNet12 = new IpNet();
  ipNet12.attach(ipNetPort11);
  ipNet12.attach(ipNetPort21);

  auto ipNetPort22 = new IpNetPort();
  ipNetPort22.setAddress(IpAddress("10.0.1.2"));
  auto ipNetPort31 = new IpNetPort();
  ipNetPort31.setAddress(IpAddress("10.0.1.3"));

  auto ipNet23 = new IpNet();
  ipNet23.attach(ipNetPort22);
  ipNet23.attach(ipNetPort31);

  auto routerNode1 = new RipRouterNode();
  routerNode1.addIpNetPort(ipNetPort11);
  auto routerNode2 = new RipRouterNode();
  routerNode2.addIpNetPort(ipNetPort21);
  routerNode2.addIpNetPort(ipNetPort22);
  auto routerNode3 = new RipRouterNode();
  routerNode3.addIpNetPort(ipNetPort31);

  // All right, everything is set-up, now let routes propigate for 2 cycles.
  foreach (i ; 0..2) {
    routerNode1.run();
    routerNode2.run();
    routerNode3.run();
  }

  // By now, each node should have all routes.
  debug writeln("routerNode1.addressRouteEntryMap = ",
                routerNode1.addressRouteEntryMap);
  debug writeln("routerNode1.addressRouteEntryMap = ",
                routerNode2.addressRouteEntryMap);
  debug writeln("routerNode1.addressRouteEntryMap = ",
                routerNode3.addressRouteEntryMap);
  assert(routerNode1.addressRouteEntryMap.length == 4);
  assert(routerNode2.addressRouteEntryMap.length == 4);
  assert(routerNode3.addressRouteEntryMap.length == 4);

  assert(routerNode1.addressRouteEntryMap[IpAddress("10.0.1.3").value].metric == 2);
  assert(routerNode1.addressRouteEntryMap[IpAddress("10.0.1.2").value].metric == 1);
  assert(routerNode1.addressRouteEntryMap[IpAddress("10.0.0.1").value].metric == 0);
}
