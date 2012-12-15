import ipaddress;
import net;
import sendernode;
import receivernode;
import csvrouternode;


/**
 * A very basic simulation with a router.
 * +--------------+    net1
 * | senderNode1 0|<----+    +-------------+
 * +--------------+     |    | routerNode  |
 *                      +--->|0           1|
 * +--------------+     |    |            2|  net2  +--------------+
 * | senderNode2 0|<----+    |            3|<------>| receiverNode |
 * +--------------+          |            4|        +--------------+
 *                           |            5|
 *                           |            6|
 *                           |            7|
 *                           +-------------+
 */
void main() {
  auto net1 = new Net();
  auto senderNode1 = new SenderNode(IpAddress("10.0.0.1"), IpAddress("10.0.1.1"));
  net1.attach(senderNode1.getIpNetPort(0));

  auto senderNode2 = new SenderNode(IpAddress("10.0.0.2"), IpAddress("10.0.1.1"));
  net1.attach(senderNode2.getIpNetPort(0));

  // Now configure our router node.
  auto addressPortMapCSV = q"EOS
10.0.0.1,0
10.0.0.2,0
10.0.1.1,3
EOS";
  auto routerNode = new CsvRouterNode(8); // An 8-port router.
  routerNode.loadAddressPortMapFromCSV(addressPortMapCSV);
  net1.attach(routerNode.getIpNetPort(0));
  
  auto net2 = new Net();
  net2.attach(routerNode.getIpNetPort(3));
  
  auto receiverNode = new ReceiverNode(IpAddress("10.0.1.1"));
  net2.attach(receiverNode.getIpNetPort(0));

  // Let every node send/receive for three cycles.
  foreach (i; 0 .. 3) {
    senderNode1.run();
    senderNode2.run();
    routerNode.run();
    receiverNode.run();
  }

  // Make sure our packet counts are correct.
  assert(senderNode1.counter == 3);
  assert(senderNode2.counter == 3);
  assert(receiverNode.counter == 6);
}