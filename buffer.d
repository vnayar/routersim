debug import std.stdio;

/**
 * A very simple memory buffer to simulate network queues.
 */
class Buffer(T) {
  T[] dataBuffer;

  // Look ahead and read without consuming from the buffer.
  T peek()
  in {
    assert(length() >= 1);
  }
  body {
    T data = dataBuffer[0];
    return data;
  }

  // Look ahead for 'num' data items without consuming them.
  T[] peek(uint num)
  in {
    assert(num <= length());
  }
  body {
    T[] data = dataBuffer[0..num].dup;
    return data;
  }

  // Read and consume a single data item.
  T read()
  in {
    debug writeln("read(): length() = ", length());
    assert(length() >= 1);
  }
  body {
    T data = dataBuffer[0];
    dataBuffer = dataBuffer[1..$];
    return data;
  }

  // Read and consume many data items.
  T[] read(uint num)
  in {
    assert(num <= length());
  }
  body {
    T[] data = dataBuffer[0..num].dup;
    dataBuffer = dataBuffer[num..$];
    return data;
  }

  // Write a single item on the buffer for subsequent reading.
  void write(T data) {
    debug writeln("write(): writing 1 unit.");
    dataBuffer ~= data;
  }

  // Write many data items on the buffer.
  void write(T[] data) {
    debug writeln("write(): writing ", data.length, " units.");
    dataBuffer ~= data;
  }

  // Determine how many items are currently in the buffer.
  size_t length() {
    return dataBuffer.length;
  }
}

// A swath of tests to confirm that Buffer works correctly.
unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  auto buf = new Buffer!int();

  // Single read-write test.
  buf.write(3);
  buf.write(4);
  assert(buf.length() == 2);
  assert(buf.read() == 3);
  assert(buf.length() == 1);
  assert(buf.read() == 4);
  assert(buf.length() == 0);

  // Array read-write test.
  buf.write([1, 2, 3]);
  buf.write([4, 5]);
  assert(buf.length() == 5);
  assert(buf.read() == 1);
  assert(buf.read(2) == [2, 3]);
  assert(buf.read(2) == [4, 5]);
  assert(buf.length() == 0);
}