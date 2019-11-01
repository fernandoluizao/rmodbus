# -*- coding: ascii
require 'rmodbus'

describe ModBus::TCPClient  do
  before(:each) do
    @uid = 1
    @sock = double('Socket')
    @adu = "\000\001\000\000\000\001\001"

    Socket.should_receive(:tcp).with('127.0.0.1', 1502, nil, nil, hash_including(:connect_timeout)).and_return(@sock)
    @sock.stub(:read).with(0).and_return('')

    @slave = ModBus::TCPClient.new('127.0.0.1', 1502).with_slave(@uid)
    @slave.debug = true
  end

  it 'should log rec\send bytes' do
    request, response = "\x3\x0\x6b\x0\x3", "\x3\x6\x2\x2b\x0\x0\x0\x64"
    mock_query(request,response)
    $stdout.should_receive(:puts).with("Tx (12 bytes): [00][01][00][00][00][06][01][03][00][6b][00][03]")
    $stdout.should_receive(:puts).with("Rx (15 bytes): [00][01][00][00][00][09][01][03][06][02][2b][00][00][00][64]")
    @slave.query(request)
  end

  it "should don't logging if debug disable" do
    @slave.debug = false
    request, response = "\x3\x0\x6b\x0\x3", "\x3\x6\x2\x2b\x0\x0\x0\x64"
    mock_query(request,response)
    @slave.query(request)
  end

  it "should log warn message if transaction mismatch" do
    @adu[0,2] = @slave.transaction.next.to_word
    @sock.should_receive(:write).with(@adu)
    @sock.should_receive(:read).with(7).and_return("\000\002\000\000\000\001" + @uid.chr)
    @sock.should_receive(:read).with(7).and_return("\000\001\000\000\000\001" + @uid.chr)

    $stdout.should_receive(:puts).with("Tx (7 bytes): [00][01][00][00][00][01][01]")
    $stdout.should_receive(:puts).with("Rx (7 bytes): [00][02][00][00][00][01][01]")
    $stdout.should_receive(:puts).with("Transaction number mismatch. A packet is ignored.")
    $stdout.should_receive(:puts).with("Rx (7 bytes): [00][01][00][00][00][01][01]")

    @slave.query('')
  end

  def mock_query(request, response)
    @adu = @slave.transaction.next.to_word + "\x0\x0\x0\x9" + @uid.chr + request
    @sock.should_receive(:write).with(@adu[0,4] + "\0\6" + @uid.chr + request)
    @sock.should_receive(:read).with(7).and_return(@adu[0,7])
    @sock.should_receive(:read).with(8).and_return(response)
  end
end

begin
  require "rubyserial"
  describe ModBus::RTUClient do
    before do 
      @sp = double('Serial port')

      Serial.should_receive(:new).with("/dev/port1", 9600, 7, 2, :odd).and_return(@sp)
      Serial.stub(:public_method_defined?).with(:flush_input).and_return(true)

      @sp.stub(:class).and_return(Serial)
      @sp.stub(:read_timeout=)
      @sp.stub(:flush_input)

      @slave = ModBus::RTUClient.new("/dev/port1", 9600, data_bits: 7, stop_bits: 2, parity: :odd).with_slave(1)
      @slave.read_retries = 0

    end
    
    it 'should log rec\send bytes' do
      request = "\x3\x0\x1\x0\x1"
      @sp.should_receive(:write).with("\1#{request}\xd5\xca")
      @sp.should_receive(:flush_input)  # Clean a garbage
      @sp.should_receive(:read).with(2).and_return("\x1\x3")
      @sp.should_receive(:read).with(1).and_return("\x2")
      @sp.should_receive(:read).with(4).and_return("\xff\xff\xb9\xf4")
      
      @slave.debug = true
      $stdout.should_receive(:puts).with("Tx (8 bytes): [01][03][00][01][00][01][d5][ca]")
      $stdout.should_receive(:puts).with("Rx (7 bytes): [01][03][02][ff][ff][b9][f4]")
      
      @slave.query(request).should == "\xff\xff"
    end
  end
rescue LoadError
end
