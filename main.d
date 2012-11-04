import net;
import sendernode;
import receivernode;
import ipaddress;


/**
 * A very basic simulation with no router (yet).
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
  auto net = new Net();
  auto senderNode1 = new SenderNode(IpAddress("10.0.0.1"), IpAddress("10.0.1.1"));
  net.attach(senderNode1.getIpNetPort(0));

  auto senderNode2 = new SenderNode(IpAddress("10.0.0.2"), IpAddress("10.0.1.1"));
  net.attach(senderNode2.getIpNetPort(0));

  auto receiverNode = new ReceiverNode(IpAddress("10.0.1.1"));
  net.attach(receiverNode.getIpNetPort(0));

  foreach (i; 0 .. 3) {
    senderNode1.run();
    senderNode2.run();
    receiverNode.run();
  }

  // Make sure our packet counts are correct.
  assert(senderNode1.counter == 3);
  assert(senderNode2.counter == 3);
  assert(receiverNode.counter == 6);
}