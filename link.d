import buffer;

/// A simple one-way communication link for raw data.
class Link {
  this(Buffer!uint receiveBuf, Buffer!uint sendBuf) {
    receiveBuffer = receiveBuf;
    sendBuffer = sendBuf;
  }

  uint peek() {
    return receiveBuffer.peek();
  }

  uint[] peek(uint num) {
    return receiveBuffer.peek(num);
  }

  uint receive() {
    return receiveBuffer.read(); 
  }
  uint[] receive(uint num) {
    return receiveBuffer.read(num);
  }
  void send(uint data) {
    sendBuffer.write(data);
  }
  void send(uint[] data) {
    sendBuffer.write(data);
  }
private:
  Buffer!uint sendBuffer;
  Buffer!uint receiveBuffer;
}
