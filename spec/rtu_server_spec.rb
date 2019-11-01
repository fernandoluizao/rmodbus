# -*- coding: ascii
require 'rmodbus'

describe ModBus::RTUServer do
  before do
    @sp = double('Serial')
    Serial.should_receive(:new).with('/dev/ttyS0', 4800, 7, 2, :none).and_return(@sp)
    @sp.stub(:read_timeout=)

    @server = ModBus::RTUServer.new('/dev/ttyS0', 4800, 1, :data_bits => 7, :stop_bits => 2)
    @server.coils = [1,0,1,1]
    @server.discrete_inputs = [1,1,0,0]
    @server.holding_registers = [1,2,3,4]
    @server.input_registers = [1,2,3,4]
  end

  it "should be valid initialized " do
    @server.coils.should == [1,0,1,1]
    @server.discrete_inputs.should == [1,1,0,0]
    @server.holding_registers.should == [1,2,3,4]
    @server.input_registers.should == [1,2,3,4]

    @server.port.should == '/dev/ttyS0'
    @server.baud.should == 4800
    @server.data_bits.should == 7
    @server.stop_bits.should == 2
    @server.parity.should == :none
  end
end
