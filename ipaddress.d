import std.string;
import std.conv;

struct IpAddress {
  uint value;

  static IpAddress opCall(uint address) {
    IpAddress ipAddress;
    ipAddress.value = address;
    return ipAddress;
  }

  static IpAddress opCall(string quadAddr) {
    IpAddress ipAddress;
    foreach (i ; 0 .. 3) {
      auto pos = indexOf(quadAddr, '.');
      if (pos == -1)
        throw new Exception("Invalid IP Address format.");

      // Pull out the numerical vlaue of the next quad.
      uint quadVal = to!uint(quadAddr[0 .. pos]);
      if (quadVal >= 256)
        throw new Exception("Invalid IP Address format.");

      // Shift up the old sum and add in the new one.
      ipAddress.value <<= 8;
      ipAddress.value += quadVal;

      quadAddr = quadAddr[pos + 1 .. $];
    }
    // Now get the last quad.
    uint quadVal = to!uint(quadAddr);
    if (quadVal >= 256)
      throw new Exception("Invalid Ip Address format.");

    // Shift up the old sum and add in the new one.
    ipAddress.value <<= 8;
    ipAddress.value += quadVal;

    return ipAddress;
  }
}

unittest {
  IpAddress a1 = (127u << 24) + (34u << 16) + (17u << 8) + 78u;
  IpAddress a2 = "127.34.17.78";

  assert(a1 == a2);

  auto a3 = IpAddress((127u << 24) + (34u << 16) + (17u << 8) + 78u);
  auto a4 = IpAddress("127.34.17.78");

  assert(a3 == a4);

  uint errorCount = 0;
  try {
    IpAddress a5 = "123.45.";
  } catch (Exception e) {
    errorCount++;
  }

  try {
    IpAddress a6 = "1.2.340.5";
  } catch (Exception e) {
    errorCount++;
  }

  assert(errorCount == 2);
}