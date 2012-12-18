import buffer;
import arraybuffer;
import conv;

debug import std.stdio;

/**
 * A buffer that stores data internally in STS-1 format (G.707).
 * Unlike the real thing, there is no time component present, thus
 * new data is packed as tightly as possible in the STS frames.
 *
 *  DS1   Router     Regenerator     ADM     Regenerator    Router   DS1
 *      +-------+    +---------+   +-----+   +---------+    +-----+
 * -----|       |----|         |---|     |---|         |----|     |------
 *      +-------+    +---------+   +-----+   +---------+    +-----+
 *         |<-Section--->|<-Section-->|<-Section->|<-Section--->|
 *         |                          |                         |
 *         |<-------Line------------->|<-------Line------------>|
 *         |                                                    |
 *         |<-----------------------Path----------------------->|
 *
 * A SONET STS-1 frame appears as follows:
 * <--------- 90 Columns ------------->
 * --Section-- --Payload--  -- Data --
 * A1  A2   J0      J1       ...
 * B1  E1   F1      B3       ...
 * D1  D2   D3      C2       ...
 * -- Line --
 * H1  H2   H3      G1       ...
 * B2  K1   K2      F2       ...
 * D4  D5   D6      H4       ...
 * D7  D8   D9      Z3       ...
 * D10 D11  D12     Z4       ...
 * S1  M1/0 E2      N1       ...
 *|--Transport--|--Synchronous Payload Envelope--|
 *
 * http://www.itu.int/rec/T-REC-G.707-200701-I/en
 */
class STSBuffer(T) : Buffer!T {
  /* SONET/SDH are byte-oriented protocols, so conversion must take place
     if types other than bytes are desired. */
  Buffer!ubyte dataBuffer;

  private size_t totalDataBytes = 0;
  private size_t writePos = 0;
  private size_t readPos = 0;

  immutable static ubyte A1 = 0xF6;
  immutable static ubyte A2 = 0x28;

  // J0 or Z0, indicates what order in the STS-N frame this STS-1 is in.
  ubyte sectionTrace = 0;
  // J1, indicates the path trace number.
  ubyte pathTrace = 0;

  // An error checking parity for each frame.
  // BIP[n] is set so the total number of '1' bits at at position N are even,
  // including the BIP itself.
  ubyte oldBIP1 = 0;
  ubyte newBIP1 = 0;

  // B3 computes BIP-8 parity excluding the Line and Section Overhead.
  ubyte oldBIP3 = 0;
  ubyte newBIP3 = 0;

  // B2 computes BIP-8 parity for Line Overhead and Payload.
  ubyte oldBIP2 = 0;
  ubyte newBIP2 = 0;


  this() {
    dataBuffer = new ArrayBuffer!ubyte();
  }

  this(Buffer!ubyte buffer) {
    dataBuffer = buffer;
  }


  // No public function should violate these constraints.
  invariant() {
    assert(writePos < 810, "Write position out of frame bounds!");
    assert(readPos < 810, "Read position out of frame bounds!");
  }

  void write(T data) {
    // First convert the input data into an array.
    T[] dataArray = [data];
    // Then write the data.
    write(dataArray);
  }

  void write(T[] data) {
    // Convert the data into bytes.
    auto byteArray = to!ubyte(data);

    int index = 0;
    while (index < byteArray.length) {
      ubyte nextByte;
      if (writePos % 90 <= 3) {
        // We are in a header section.
        size_t row = writePos / 90;
        size_t col = writePos % 90;
        
        // At the start of a new frame save the old parity calculations.
        if (row == 0 && col == 0) {
          oldBIP1 = newBIP1;
          oldBIP3 = newBIP3;
          oldBIP2 = newBIP2;
        }

        nextByte = getHeaderByte(row, col);

        // Include payload headers in B3.
        if (col == 3) {
          newBIP3 ^= nextByte;
        }
        // Line Overhead and payload envelope are in B2.
        if (row > 2 || col == 3) {
          newBIP2 ^= nextByte;
        }
      } else {
        // Data in the payload envelope.
        nextByte = byteArray[index++];
        newBIP3 ^= nextByte;
        newBIP2 ^= nextByte;

        // Update the number of actual data bytes in our buffer.
        totalDataBytes++;
      }

      // Update the bit-interleaved-parity.
      newBIP1 ^= nextByte;
      dataBuffer.write(nextByte);

      writePos++;

      if (writePos == 810) {
        writePos = 0;
      }
    }
  }

  /**
   * Produce SONET header bytes depending for a position in the frame.
   */
  ubyte getHeaderByte(size_t row, size_t col)
    in {
      assert(row < 9 && col < 4, "Header location out of bounds.");
    }
  body {
    switch (row) {
    case 0:
      // The first header row.
      switch (col) {
      case 0: return A1;  // A1
      case 1: return A2;  // A2
      case 2: return sectionTrace;  // J0
      case 3: return pathTrace;  // J1
      default:
        throw new Error("Header location out of bounds.");
      }
    case 1:
      switch (col) {
      case 0: return oldBIP1;  // B1
      case 1: return 0;  // E1 - Orderwire, voice channel for technicians.
      case 2: return 0;  // F1 - Section User
      case 3: return oldBIP3;  // B3 - Section Parity.
      default:
        throw new Error("Header location out of bounds.");
      }
    case 2:
      switch (col) {
      case 0: return 0;  // D1 - Alarms, maintenance, control.
      case 1: return 0;  // D2 - Alarms, maintenance, control.
      case 2: return 0;  // D3 - Alarms, maintenance, control.
      // C2 - Path Signal Label:
      // http://www.cisco.com/en/US/tech/tk482/tk607/
      //     technologies_tech_note09186a00800942bd.shtml
      case 3: return 0x02;  // (Virtual Tributaries)
      default:
        throw new Error("Header location out of bounds.");
      }
    case 3:
      switch (col) {
      case 0: return 0;  // H1 - Frame pointer for synchronizing disparate
      case 1: return 0;  // H2 - data rates and clocks.
      case 2: return 0;  // H3 - Negative frequency adjustment.
      case 3: return 0;  // G1 - Path Status and performance.
      default:
        throw new Error("Header location out of bounds.");
      }
    case 4:
      switch (col) {
      case 0: return oldBIP2;  // B2 - BIP8 for Line Overhead and Payload
      case 1: return 0;  // K1 - Protection Signals
      case 2: return 0; // K2
      case 3: return 0;  // F2 - Path User Channel
      default:
        throw new Error("Header location out of bounds.");
      }
    case 5:
      switch (col) {
      case 0: return 0;  // D4 - Administrative channels.
      case 1: return 0;  // D5
      case 2: return 0; // D6
      case 3: return 0;  // H4
      default:
        throw new Error("Header location out of bounds.");
      }
    case 6:
      switch (col) {
      case 0: return 0;  // D7 - Administrative channels.
      case 1: return 0;  // D8
      case 2: return 0; // D9
      case 3: return 0;  // Z3
      default:
        throw new Error("Header location out of bounds.");
      }
    case 7:
      switch (col) {
      case 0: return 0;  // D10 - Administrative channels.
      case 1: return 0;  // D11
      case 2: return 0; // D12
      case 3: return 0;  // Z4
      default:
        throw new Error("Header location out of bounds.");
      }
    case 8:
      switch (col) {
      case 0: return 0;  // S1 - Synchronization status.
      case 1: return 0;  // M1/0 - Remote Line Error Indication
      case 2: return 0; // E2 - Order wire
      case 3: return 0;  // N1
      default:
        throw new Error("Header location out of bounds.");
      }
    default:
      throw new Error("Header location out of bounds.");
    }
  }

  // Determine how many items are currently in the buffer.
  // Item size is defined by our compile-time parameters.
  size_t length() {
    return totalDataBytes * ubyte.sizeof / T.sizeof;
  }

  // Read and consume a single data item.
  T read() {
    return read(1)[0];
  }

  // Read and consume many data items.
  T[] read(size_t num) {
    ubyte[] readBytes;
    // Pre-allocate our read buffer.
    readBytes.length = num * T.sizeof / ubyte.sizeof;
    size_t totalBytesRead = 0;

    while (totalBytesRead < readBytes.length) {
      // Fist we discard header bytes.
      if (readPos % 90 <= 3) {
        dataBuffer.read();  // Throw away this byte.
      } else {
        readBytes[totalBytesRead++] = dataBuffer.read();
        totalDataBytes--;
      }
      readPos++;

      if (readPos == 810) {
        readPos = 0;
      }
    }

    // Convert to our target type before returning.
    return to!T(readBytes);
  }

  // Look ahead and read without consuming from the buffer.
  T peek() {
    return peek(1)[0];
  }

  // Look at but do not consume many data items.
  T[] peek(size_t num) {
    ubyte[] readBytes;
    // Pre-allocate our read buffer.
    readBytes.length = num * T.sizeof / ubyte.sizeof;
    size_t totalBytesRead = 0;
    size_t currentReadPos = readPos;

    // Look ahead and pad for headers, 4 header bytes per 90 byte row.
    size_t peekBytes = readBytes.length + (readBytes.length / 86 + 1) * 4;
    // But watch out for edges.
    if (peekBytes > dataBuffer.length())
      peekBytes = dataBuffer.length();

    ubyte[] peekData = dataBuffer.peek(peekBytes);
    size_t peekPos = 0;
    while (totalBytesRead < readBytes.length) {
      // Fist we discard header bytes.
      if (currentReadPos % 90 > 3) {
        readBytes[totalBytesRead++] = peekData[peekPos];
      }
      currentReadPos++;
      peekPos++;

      if (currentReadPos == 810) {
        currentReadPos -= 0;
      }
    }

    // Convert to our target type before returning.
    return to!T(readBytes);
  }

}

unittest {
  debug writeln("-- unittest: ", __FILE__, ":", __LINE__, " --");

  // Create a buffer of variable size.
  uint[] createTestData(uint n) {
    uint[] data;
    data.length = n;
    foreach (uint index, ref d ; data) {
      d = index;
    }
    return data;
  }

  void testReadWritePeek(uint[] testData) {
    auto stsBuffer = new STSBuffer!uint();
    stsBuffer.write(testData);
    auto preReadLength = stsBuffer.length();
    auto peekData = stsBuffer.peek(testData.length);
    assert(stsBuffer.length() == preReadLength,
           "Peek must not modify length.");
    auto readData = stsBuffer.read(testData.length);
    debug(2) writeln("readData = ", readData);
    assert(readData == peekData, "Read data does not match peek data.");
    assert(readData == testData, "Read data does not match write data.");
  }

  debug writeln("Testing single-row read-write-peek.");
  testReadWritePeek(createTestData(5));
  debug writeln("Testing multi-row read-write-peek.");
  testReadWritePeek(createTestData(90));  // 360 bytes, over 5 rows.
  debug writeln("Testing multi-frame read-write-peek.");
  testReadWritePeek(createTestData(1000));  // 4000 bytes, over 6 frames.
}