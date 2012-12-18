import std.traits;

debug import std.stdio;


/**
 * Convert an array from a larger type into a smaller type.
 * This operation only works if the larger type's size is
 * a multiple of the smaller type's size.
 */
T1[] to(T1, T2)(T2[] t2)
  if (isUnsigned!T2 && isUnsigned!T1 &&
      T2.sizeof > T1.sizeof &&
      T2.sizeof % T1.sizeof == 0)
{
  // Make a mask of just the high order bits.
  // For example to go from UINT to UBYTE we want 0xFF000000.
  size_t offset = (T2.sizeof - T1.sizeof) * 8;
  T2 mask = ~0;  // Start will all bits set to 1.
  mask <<= offset;

  debug(2) writefln("mask = %x, offset = %d", mask, offset);

  T1[] littleWords;
  // Advance allocation saves us from dynamic resizing.
  littleWords.length = t2.length * (T2.sizeof / T1.sizeof);

  size_t pos = 0;
  foreach (word ; t2) {
    // 'word' is passed by value, we are free to modify our copy.
    foreach (i ; 0 .. T2.sizeof / T1.sizeof) {
      // Store the smaller type in most-significant order.
      littleWords[pos++] = cast(T1) ((word & mask) >> offset);
      word <<= T1.sizeof * 8;
    }
  }

  return littleWords;
}

unittest {
  uint[] bigWords = [0x0A0B0C0D, 0x0E0F0102];
  ubyte[] littleWords = to!ubyte(bigWords);

  assert(bigWords[0] == 0x0A0B0C0D, "Original data modified!");
  assert(littleWords.length == 8, "Wrong number of little words!");
  debug(2) writeln("littleWords = ", littleWords);
  assert(littleWords[0] == 0x0A && littleWords[1] == 0x0B);
  assert(littleWords[2] == 0x0C && littleWords[3] == 0x0D);
  assert(littleWords[4] == 0x0E && littleWords[7] == 0x02);
}

/**
 * Convert an array from a smaller type into a larger type.
 * This operation only works if the larger type's size is
 * a multiple of the smaller type's size.
 */
T1[] to(T1, T2)(T2[] t2)
  if (isUnsigned!T2 && isUnsigned!T1 &&
      T1.sizeof > T2.sizeof &&
      T1.sizeof % T2.sizeof == 0)
{
  size_t wordRatio = T1.sizeof / T2.sizeof;

  T1[] bigWords;
  // Advance allocation saves us from dynamic resizing.
  bigWords.length = t2.length / wordRatio;

  size_t pos = 0;
  // Set put together smaller words for each big word.
  foreach (ref bigWord ; bigWords) {
    bigWord = 0;
    foreach (word ; t2[pos .. pos + wordRatio]) {
      bigWord <<= T2.sizeof * 8;
      bigWord += word;
    }
    pos += wordRatio;
  }

  return bigWords;
}

unittest {
  ubyte[] littleWords = [
      0x0A, 0x0B, 0x0C, 0x0D,
      0x0E, 0x0F, 0x01, 0x02
  ];
  uint[] bigWords = to!uint(littleWords);

  assert(littleWords[0] == 0x0A, "Original data modified!");
  assert(bigWords.length == 2, "Wrong number of big words!");
  debug(2) writeln("bigWords = ", bigWords);
  assert(bigWords[0] == 0x0A0B0C0D && bigWords[1] == 0x0E0F0102);
}
