debug import std.stdio;

/**
 * A very simple memory buffer to simulate network queues.
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
