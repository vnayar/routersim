import buffer;
import link;

/**
 * A class representing a simple network node that can send/receive datagrams.
 */
class Node {
  // Associate a buffer with every physical port.
  Buffer[] portBuffers;

  Node(int ports) {
    portBuffers.length = ports;
    foreach (i ; 0 .. ports) {
      portBuffers[i] = new Buffer!uint();      
    }
  }

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