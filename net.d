import std.container;
import std.algorithm;
import std.range;

import netport;

debug import std.stdio;


/**
 * A network connection with one or more NetPorts attached.
 * Each time a message is sent to a net, all of the attached NetPorts
 * will receive an update.
 * Note: In the observer patter, this is the subject.
 */
class Net {
  uint[] _datagram;
  SList!NetPort _netPortList;

  this() {
    _netPortList = SList!NetPort();
  }

  /// Attach a NetPort to be notified when new data arrives on the net.
  void attach(NetPort netPort) {
    netPort.setNet(this);
    _netPortList.insertFront(netPort);
  }

  /// Remove a NetPort so that it is no longer notified.
  void detach(NetPort netPort) {
    auto r = find(_netPortList[], netPort);
    _netPortList.linearRemove(take(r, 1));
  }

  /// Read the data currently on the network line.
  uint[] getDatagram() {
    return _datagram;
  }

  /// Put raw data onto a network line for all to hear.
  void setDatagram(uint[] datagram) {
    _datagram = datagram;
  }

  /**
   * Let all listening NetPorts know new data has arrived.
   */
  void notify(NetPort excludeNetPort = null) {
    foreach (netPort ; _netPortList) {
      if (netPort !is excludeNetPort)
        netPort.update();
    }
  }
}

// A battery of tests to confirm Net works correctly.
unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  uint updateCounter = 0;

  // Make a simple extension of NetPort that has minimal dependency.
  class TestNetPort : NetPort {
    override void update() { updateCounter++; }
    override bool hasData() { return true; }
  }

  auto net = new Net();
  auto netPort1 = new TestNetPort();
  auto netPort2 = new TestNetPort();

  net.attach(netPort1);
  net.attach(netPort2);

  // With two observers, we should have two calls to update().
  net.setDatagram([1u, 2u, 3u]);
  net.notify();

  assert(updateCounter == 2);
  assert(net.getDatagram() == [1u, 2u, 3u]);

  net.detach(netPort2);
  net.notify();

  assert(updateCounter == 3);
}