import ipaddress;
import ipnet;
import node;
import sendernode;
import receivernode;
import riprouternode;

import std.stdio;


/**
 * Basic simulation of router network using RIPv1.
 *            10.0.0.2      10.0.0.3
 *   +-------------+ 0       0 +-------------+
 *   | senderNode1 |<----+---->| senderNode2 |
 *   +-------------+     |     +-------------+
 *                     0 v 10.0.0.1
 *     10.0.1.1  1 +-----------+ 2  10.0.2.1
 *             +-->|routerNode1|<---+
 *             |   +-----------+    |
 *             |                    |
 *  10.0.1.2 0 v 10.0.3.1  10.0.3.2 v 0 10.0.2.2
 *    +-------------+ 1     1 +-------------+
 *    | routerNode2 |<------->| routerNode3 |
 *    +-------------+         +-------------+
 *  10.0.4.1 2 ^                    ^ 2 10.0.5.1
 *             |                    |
 *  10.0.4.2 0 v 10.0.6.1  10.0.6.2 v 0 10.0.5.2
 *    +-------------+ 1     1 +-------------+
 *    | routerNode4 |<------->| routerNode5 |
 *    +-------------+         +-------------+
 *  10.0.7.1 2 ^                    ^ 2 10.0.8.1
 *             |                    |
 *  10.0.7.2 0 v                    v 0 10.0.8.2
 *    +-------------+         +-------------+
 *    |receiverNode1|         |receiverNode2|
 *    +-------------+         +-------------+
 */
void main() {
  ////
  // BEGIN Create Diagram
  ////

  auto senderNode1 = new SenderNode(IpAddress("10.0.0.2"), IpAddress("10.0.7.2"));
  auto senderNode2 = new SenderNode(IpAddress("10.0.0.3"), IpAddress("10.0.8.2"));

  auto routerNode1 = new RipRouterNode([
    IpAddress("10.0.0.1"),
    IpAddress("10.0.1.1"),
    IpAddress("10.0.2.1")
  ]);

  auto ipNet0 = new IpNet();
  ipNet0.attach(senderNode1.getIpNetPort(0));
  ipNet0.attach(senderNode2.getIpNetPort(0));
  ipNet0.attach(routerNode1.getIpNetPort(0));
  

  auto routerNode2 = new RipRouterNode([
    IpAddress("10.0.1.2"),
    IpAddress("10.0.3.1"),
    IpAddress("10.0.4.1")
  ]);

  auto routerNode3 = new RipRouterNode([
    IpAddress("10.0.2.2"),
    IpAddress("10.0.3.2"),
    IpAddress("10.0.5.1")
  ]);

  auto ipNet1 = new IpNet();
  ipNet1.attach(routerNode1.getIpNetPort(1));
  ipNet1.attach(routerNode2.getIpNetPort(0));

  auto ipNet2 = new IpNet();
  ipNet2.attach(routerNode1.getIpNetPort(2));
  ipNet2.attach(routerNode3.getIpNetPort(0));

  auto ipNet3 = new IpNet();
  ipNet3.attach(routerNode2.getIpNetPort(1));
  ipNet3.attach(routerNode3.getIpNetPort(1));

  auto routerNode4 = new RipRouterNode([
    IpAddress("10.0.4.2"),
    IpAddress("10.0.6.1"),
    IpAddress("10.0.7.1")
  ]);

  auto routerNode5 = new RipRouterNode([
    IpAddress("10.0.5.2"),
    IpAddress("10.0.6.2"),
    IpAddress("10.0.8.1")
  ]);

  auto ipNet4 = new IpNet();
  ipNet4.attach(routerNode2.getIpNetPort(2));
  ipNet4.attach(routerNode4.getIpNetPort(0));

  auto ipNet5 = new IpNet();
  ipNet5.attach(routerNode3.getIpNetPort(2));
  ipNet5.attach(routerNode5.getIpNetPort(0));

  auto ipNet6 = new IpNet();
  ipNet6.attach(routerNode4.getIpNetPort(1));
  ipNet6.attach(routerNode5.getIpNetPort(1));

  auto receiverNode1 = new ReceiverNode(IpAddress("10.0.7.2"));
  auto receiverNode2 = new ReceiverNode(IpAddress("10.0.8.2"));

  auto ipNet7 = new IpNet();
  ipNet7.attach(routerNode4.getIpNetPort(2));
  ipNet7.attach(receiverNode1.getIpNetPort(0));

  auto ipNet8 = new IpNet();
  ipNet8.attach(routerNode5.getIpNetPort(2));
  ipNet8.attach(receiverNode2.getIpNetPort(0));

  ////
  // END Create Diagram
  ////

  // Create some helper variables.
  auto senderNodes = [senderNode1, senderNode2];
  auto routerNodes = [routerNode1, routerNode2, routerNode3, routerNode4,
                      routerNode5];
  auto receiverNodes = [receiverNode1, receiverNode2];
  Node[string] allNodes =
    ["senderNode1": cast(Node) senderNode1,
     "senderNode2": senderNode2,
     "routerNode1": routerNode1, "routerNode2": routerNode2,
     "routerNode3": routerNode3, "routerNode4": routerNode4,
     "routerNode5": routerNode5,
     "receiverNode1": receiverNode1, "receiverNode2": receiverNode2];

  // Give the routes enough time to initialize.
  writeln("Propigating routing tables.");
  foreach (i ; 0..routerNodes.length) {
    foreach (routerNode ; routerNodes) {
      routerNode.run();
    }
  }

  // Print out the routing tables thus far.
  foreach (index, routerNode ; routerNodes) {
    writeln("==== ", index + 1, " (", routerNode.addressRouteEntryMap.length,
            ") ====");
    writeln("routerNode", index + 1, ".addressRouteEntryMap = ",
            routerNode.addressRouteEntryMap);
  }

  showNodeStatus(allNodes);

  // Now get some packets sent out.
  writeln("Sending 3 packets from senderNode1.");
  foreach (i ; 0 .. 3) {
    senderNode1.run();
  }

  // Give the routers some time to send the data along.
  writeln("Running router nodes.");
  foreach (i ; 0 .. routerNodes.length) {
    foreach (routerNode ; routerNodes) {
      routerNode.run();
    }
  }

  showNodeStatus(allNodes);

  // Now get some packets sent out.
  writeln("Sending 3 packets from senderNode2.");
  foreach (i ; 0 .. 3) {
    senderNode2.run();
  }

  // Give the routers some time to send the data along.
  writeln("Running router nodes.");
  foreach (i ; 0 .. routerNodes.length) {
    foreach (routerNode ; routerNodes) {
      routerNode.run();
    }
  }

  showNodeStatus(allNodes);

  // Now check for data in the receiver nodes.
  writeln("Running receiver nodes.");
  foreach (i ; 0 .. 3) {
    foreach (receiverNode ; receiverNodes) {
      receiverNode.run();
    }
  }

  showNodeStatus(allNodes);

  // Check that packet counts are what we expect.
  assert(senderNode1.counter == 3);
  assert(senderNode2.counter == 3);
  writeln("receiverNode1.counter = ", receiverNode1.counter);
  assert(receiverNode1.counter == 3);
  writeln("receiverNode2.counter = ", receiverNode2.counter);
  assert(receiverNode2.counter == 3);

}

/**
 * Print to the console the status of node interfaces.
 */
void showNodeStatus(Node[string] nodes) {
  writeln("==== Begin Report ====");
  foreach (nodeName, node ; nodes) {
    writefln("[%10s - %s]", nodeName, node.status());
    foreach (index, ipNetPort ; node.getIpNetPorts()) {
      auto rx = ipNetPort.rx;
      writefln("  [%2d: rx:{bytes:%8d packets:%4d dropped:%4d}]",
              index, rx.bytes, rx.packets, rx.dropped);
      auto tx = ipNetPort.tx;
      writefln("  [%2d: tx:{bytes:%8d packets:%4d dropped:%4d}]",
              index, tx.bytes, tx.packets, tx.dropped);
    }
  }
  writeln("==== End Report ====");
}