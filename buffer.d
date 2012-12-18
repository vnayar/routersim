debug import std.stdio;

/**
 * An interface for an object that can store and retrieve data
 * These can range from simple array memory buffers to complicated
 * protocols such as Ethernet or SONET.
 *
 * Buffers may be implemented in terms of other buffers, thus
 * a successive layers of wrapped protocols may be simulated.
 *
 * For example, suppose we have many buffers that take another
 * buffer as a constructor argument:
 *   auto myBuffer = new IpBuffer( new EthernetBuffer( new SONETBuffer() ) );
 */
interface Buffer(T) {
  // Look ahead and read without consuming from the buffer.
  T peek()
  in {
    assert(length() >= 1);
  }

  // Look ahead for 'num' data items without consuming them.
  T[] peek(size_t num)
  in {
    assert(num <= length());
  }

  // Read and consume a single data item.
  T read()
  in {
    debug writeln("read(): length() = ", length());
    assert(length() >= 1);
  }

  // Read and consume many data items.
  T[] read(size_t num)
  in {
    assert(num <= length());
  }

  // Write a single item on the buffer for subsequent reading.
  void write(T data);

  // Write many data items on the buffer.
  void write(T[] data);

  // Determine how many items are currently in the buffer.
  size_t length();
}
