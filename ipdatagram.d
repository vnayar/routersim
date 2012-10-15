struct IpDatagram {
  IpHeader header;
  uint[] data;

  void init() {
    header.init(data);
  }
}