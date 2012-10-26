import buffer;
import link;

/**
 * A class representing a simple network node that can send/receive datagrams.
 */
class Node {
  // Associate a buffer with every physical port.
  Buffer[] portBuffers;

  this(int ports) {
    portBuffers.length = ports;
    foreach (i ; 0 .. ports) {
      portBuffers[i] = new Buffer!uint();      
    }
  }

  /**
   * Create a link which can be used to receive/send data
   * between nodes.
   */
  static Link createLink(Node receiveNode, int receivePort,
                         Node sendNode, int sendPort)
  in {
    // Make sure the port numbers are actually valid.
    assert(receivePort < receiveNode.portBuffers.length);
    assert(sendPort < sendNode.portBuffers.length);
  }
  body {
    auto buffer1 = node1.getPortBuffer(port1);
    auto buffer2 = node2.getPortBuffer(port2);
    return new Link(buffer1, buffer2);
  }

  /// Internal function used to create links.
  private Buffer getPortBuffer(uint port) {
    return portBuffers[port];
  }

  /// A function run every cycle that specifies node behaviour.
  abstract void run();
}

unittest {
  import iplink;

  class ReceiveNode : Node {
    IpLink[] links;
    
  }

  class SendNode : Node {
  }

  auto receiveNode = new ReceiveNode(3);
  auto sendNode = new SendNode(3);

  auto link1 = new IpLink(Node.createLink(receiveNode, 2, sendNode, 1));
  auto link2 = new IpLink(Node.createLink(receiveNode, 0, sendNode, 0));
                  
}