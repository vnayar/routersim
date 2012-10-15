import std.stdio;
import std.stream;

class NetworkNode {
  MemoryStream stream;

  this() {
    stream = new MemoryStream();
  }
}

/**
 * Play with MemoryStream to figure out how it works.
 */
unittest {
  MemoryStream stream = new MemoryStream();

  int intVal = 0xABCD1234;  // A 32-bit integer.
  stream.write(intVal);


  writeln("isOpen = ", stream.isOpen);
  writeln("position() = ", stream.position());
  writeln("available = ", stream.available);
  writeln("data = ", stream.data());

  stream.seekSet(0);

  stream.write(intVal);

  writeln("isOpen = ", stream.isOpen);
  writeln("position() = ", stream.position());
  writeln("available = ", stream.available);
  writeln("data = ", stream.data());

  /*
  writeln("data() = ", stream.data());

  ubyte b1, b2, b3, b4;
  stream.read(b1);
  writeln("b1 = ", b1);
  stream.read(b2);
  writeln("b2 = ", b2);
  stream.read(b3);
  writeln("b3 = ", b3);
  stream.read(b4);
  writeln("b4 = ", b4);
  */
}

void main() {
}