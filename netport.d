import net;
import buffer;


/**
 * A port on a network node to a network that responds to new messages on the Net.
 * Messages are added to the NetPort's internal buffer.
 * Note: In the observer patter, this is the observer.
 */
class NetPort {
  private Buffer!uint buffer;
  private Net net;
  
  this() {
    buffer = new Buffer!uint();
  }

  /// Respond to messages from the Net.
  void update() {
    buffer.write(net.getDatagram());
  }

  // Used by derived classes.
  Net getNet() {
    return net;
  }

  /// Called by a Net when being attached.
  void setNet(Net net) {
    this.net = net;
  }

  Buffer!uint getBuffer() {
    return buffer;
  }

  bool hasData() {
    return buffer.length > 0;
  }

}