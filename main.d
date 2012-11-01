import net;
import sendernode;
import receivernode;

/**
 * A very basic simulation with no router (yet).
 * +-------------+     net
 * | senderNode1 |<-----+
 * +-------------+      |       +--------------+
 *                      +------>| receiverNode |
 * +-------------+      |       +--------------+
 * | senderNode2 |<-----+
 * +-------------+
 */
void main() {
  auto net = new Net();
  auto senderNode1 = new SenderNode(10001, 20001);
  net.attach(senderNode1.getIpNetPort(0));

  auto senderNode2 = new SenderNode(10002, 20001);
  net.attach(senderNode2.getIpNetPort(0));

  auto receiverNode = new ReceiverNode(20001);
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