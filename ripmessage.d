import ipaddress;

debug import std.stdio;


/**
 * A repeatable route structure in RIPv1, RFC1058.
 */
struct RipRoute {
  // The RFC says that IP is Address Family 2.
  immutable ushort IP_ADDRESS_FAMILY = 2;
  // The number of words per route (for parsing).
  immutable size_t RIP_ROUTE_WORDS = 5;
  // The highest allowable metric.
  immutable uint METRIC_INFINITY = 16;

  IpAddress address;
  uint metric;
  ushort addressFamily = IP_ADDRESS_FAMILY; 

  // Format the data structure to be transmitted over a wire.
  uint[] pack() {
    uint[] routeData;
    routeData.length = RIP_ROUTE_WORDS;
    routeData[0] = addressFamily << 16;
    routeData[1] = address.value;
    routeData[2] = 0;
    routeData[3] = 0;
    routeData[4] = metric;

    return routeData;
  }

  // Extract a data structure from its wire format.
  void unpack(uint[] routeData)
    in {
      assert(routeData.length >= RIP_ROUTE_WORDS);
    }
  body {
    addressFamily = cast(ushort)(routeData[0] >> 16);
    address = IpAddress(routeData[1]);
    metric = routeData[4];
  }
}

// Basic tests for the RipRoute structure.
unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__,  " --");

  RipRoute ripRoute1 = RipRoute(IpAddress("10.0.2.1"), 3);
  uint[] ripData = ripRoute1.pack();
  RipRoute ripRoute2;
  ripRoute2.unpack(ripData);

  debug writeln("ripRoute1 = ", ripRoute1);
  debug writeln("ripRoute2 = ", ripRoute2);
  assert(ripRoute1 == ripRoute2);
}

// Supported RIPv1 commands.
enum RipCommand : ubyte { REQUEST=1, RESPONSE=2 };

// A data structure for RIPv1 message, described in RFC1058.
class RipMessage {
  // The type of operation for the message.
  RipCommand command;
  // The RIP version.
  ubyte ver = 1;
  // A variable list of addresses and their metric.
  RipRoute[] routes;

  invariant() {
    assert(routes.length <= 25, "RIP Message cannot have more than 25 routes.");
  }
  
  RipCommand getCommand() {
    return command;
  }
  void setCommand(RipCommand command) {
    this.command = command;
  }

  ubyte getVersion() {
    return ver;
  }
  void setVersion(ubyte ver) {
    this.ver = ver;
  }

  RipRoute[] getRoutes() {
    return routes;
  }

  void addRoute(IpAddress address, uint metric)
    in {
      assert(metric >= 0 && metric <= 16,
             "Metric must be 0-15 or 16 (not reachable).");
    }
  body {
    routes ~= RipRoute(address, metric);
  }

  // Convert a RipMessage into serialized data.
  uint[] pack() {
    uint[] ripData;
    ripData.length = 1;
    ripData[0] = (getCommand() << 24) + (getVersion() << 16);
    foreach (route ; routes) {
      ripData ~= route.pack();
    }
    return ripData;
  }

  // From serialized data, initialize a RipMessage.
  void unpack(uint[] ripData) {
    setCommand(cast(RipCommand)((ripData[0] >> 24) & 0xFF));
    setVersion(cast(ubyte)((ripData[0] >> 16) & 0xFF));
    uint pos = 1;
    while (pos < ripData.length) {
      auto ripRoute = RipRoute();
      ripRoute.unpack(ripData[pos..$]);
      routes ~= ripRoute;

      pos += RipRoute.RIP_ROUTE_WORDS;
    }
  }
}

// RipMessage tests to pack/unpack as well as data access.
unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__,  " --");

  // Create our original test message.
  auto ripMessage1 = new RipMessage();
  ripMessage1.setCommand(RipCommand.REQUEST);
  ripMessage1.addRoute(IpAddress("10.0.1.2"), 4);
  ripMessage1.addRoute(IpAddress("10.0.1.3"), 3);
  ripMessage1.addRoute(IpAddress("10.0.1.4"), 2);

  // Check its accessor methods.
  assert(ripMessage1.getCommand() == RipCommand.REQUEST);
  assert(ripMessage1.getRoutes().length == 3);

  // Put it in wire format.
  uint[] ripData = ripMessage1.pack();
  assert(ripData.length == 16);

  // Extract the wire format.
  auto ripMessage2 = new RipMessage();
  ripMessage2.unpack(ripData);
  
  // Make sure the data inside is preserved.
  debug writeln("ripMessage1 = ", ripMessage1);
  debug writeln("ripMessage2 = ", ripMessage2);
  assert(ripMessage1.getCommand() == ripMessage2.getCommand());
  assert(ripMessage1.getVersion() == ripMessage2.getVersion());
  assert(ripMessage1.getRoutes() == ripMessage2.getRoutes());
}