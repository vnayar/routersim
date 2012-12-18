import net;

debug import std.stdio;

/**
 * A port on a network node to a network that responds to new messages on the Net.
 * Messages are added to the NetPort's internal buffer.
 * This base class can be implemented to add direct support to higher level
 * protocols at the same level as IP rather than simply raw data.
 * Note: In the observer patter, this is the observer.
 */
class NetPort {
  private Net net;

  // Used by derived classes.
  final Net getNet() {
    return net;
  }

  /// Called by a Net when being attached.
  final void setNet(Net net) {
    this.net = net;
  }

  /// Respond to messages from the Net.
  abstract void update();

  /// Indicates whether a read operation may be performed.
  abstract bool hasData();
}