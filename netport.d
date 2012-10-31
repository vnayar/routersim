import net;
import buffer;


/**
 * A port on a network node to a network that responds to new messages on the Net.
 * Messages are added to the NetPort's internal buffer.
 * Note: In the observer patter, this is the observer.
 */
class NetPort {
  Buffer buffer;
  Net net;
  
  this() {
    buffer = new Buffer!utin();
  }

  /// Respond to messages from the Net.
  void update() {
    buffer.write(net.getDatagram());
  }

  /// Called by a Net when being attached.
  void setNet(Net net) {
    this.net = net;
  }

  Buffer getBuffer() {
    return buffer;
  }

}