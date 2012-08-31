require "rubygems"
require "bundler"
Bundler.setup
Bundler.require

port_str = "/dev/tty.usbserial-A9007N5X"
baud_rate = 9600  
data_bits = 8  
stop_bits = 1  
parity = SerialPort::NONE 
sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

step = 3 

class SpeedManager
  include Celluloid
  def initialize(step=2)
    @step = step
    @acc = 0
    @first = true
  end

  def run
    every(@step) {
      read!
    }
  end

  def step(val)
    @acc += val
  end

  def read
    if @first
      speed = 0
      @first = false
    else
      speed = (@acc * 3.1415 * 0.46 * 3.6 / @step).round(2)
    end
    p "LETTURA: #{speed}"
    @acc = 0
  end
end

sm = SpeedManager.new(step)
sm.run!

while true do  
  sp_char = sp.getc  
  if sp_char && sp_char.match(/F|B/)
    p sp_char
    sm.step!(1) if sp_char.match(/F/)
    sm.step!(-1) if sp_char.match(/B/)
  end  
end

