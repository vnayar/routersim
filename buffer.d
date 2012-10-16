debug import std.stdio;

/**
 * A very simple memory buffer to simulate network queues.
 */
class Buffer(T) {
  T[] dataBuffer;

  T peek()
  in {
    assert(length() >= 1);
  }
  body {
    T data = dataBuffer[0];
    return data;
  }

  T[] peek(uint num)
  in {
    assert(num <= length());
  }
  body {
    T[] data = dataBuffer[0..num].dup;
    return data;
  }

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

  T[] read(uint num)
  in {
    assert(num <= length());
  }
  body {
    T[] data = dataBuffer[0..num].dup;
    dataBuffer = dataBuffer[num..$];
    return data;
  }

  void write(T data) {
    debug writeln("write(): writing 1 unit.");
    dataBuffer ~= data;
  }

  void write(T[] data) {
    debug writeln("write(): writing ", data.length, " units.");
    dataBuffer ~= data;
  }

  size_t length() {
    return dataBuffer.length;
  }
}

unittest {
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