/**
 * Basic operations for binary encoded headers like IP, UDP, and TCP.
 */
class Header {
  static immutable uint wordBitSize = uint.sizeof * 8;   // In bits
  static immutable uint wordByteSize = uint.sizeof;      // In bytes

  // The raw header in 32-bit words.
  uint[] rawData;

  this() {
  }

  this(uint[] rawData) {
    this.rawData = rawData;
  }

  /**
   * Set the specified bits in the header to the specified value.
   * A separate function will be compiled for each compilation parameter set.
   * Params:
   *   wordOffset = The word the field is located in.
   *   bitOffset  = How many bits into the word the field is in.
   *   length     = How many bits long is the field.
   */
  private void setField(alias wordOffset, alias bitOffset, alias length)(uint val)
    if (is(typeof(wordOffset) : uint) &&
        is(typeof(bitOffset) : uint) &&
        is(typeof(length) : uint) && bitOffset + length <= wordBitSize)
  in {
    assert(wordOffset < rawData.length, "wordOffset is out of header bounds");
    assert(val >> length == 0, "Parameter is out of bounds.");
  }
  body {
    // Shift the value where it will be placed.
    val <<= bitOffset;
    // Create a mask with 1's where the value will be placed.
    uint mask = 0xFFFFFFFF >> (wordBitSize - length) << bitOffset;
    // Zero the bits where the new value will be placed.
    rawData[wordOffset] &= ~mask;
    // Insert the new value;
    rawData[wordOffset] += val;
  }

  /**
   * Get the specified bits in the header.
   * A separate function will be compiled for each compilation parameter set.
   * Params:
   *   wordOffset = The word the field is located in.
   *   bitOffset  = How many bits into the word the field is in.
   *   length     = How many bits long is the field.
   */
  private uint getField(alias wordOffset, alias bitOffset, alias length)() const
    if (is(typeof(wordOffset) : uint) &&
        is(typeof(bitOffset) : uint) &&
        is(typeof(length) : uint) && bitOffset + length <= wordBitSize)
  in {
    assert(wordOffset < rawData.length, "wordOffset is out of bounds");
  }
  body {
    uint mask = 0xFFFFFFFF >> (32 - length);
    return (rawData[wordOffset] >> bitOffset) & mask;
  }
}