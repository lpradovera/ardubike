class Ardubike
  def initialize(port_str)
    @port_str = port_str
    #@port_str = "/dev/tty.usbserial-A9007N5X"
    @baud_rate = 9600  
    @data_bits = 8  
    @stop_bits = 1  
    @parity = SerialPort::NONE 
    @last_tick = nil
    @speeds = []
    @playing = false
    @fans = [0, 0, 0]
    20.times { @speeds.push(0) }

    @sp = SerialPort.new(@port_str, @baud_rate, @data_bits, @stop_bits, @parity)

    p "Ardubike ready"
  end

  def run
    while true do  
      sp_char = @sp.getc  
      if sp_char && sp_char.match(/F|B/)
        if @last_tick
          elapsed = Time.now - @last_tick
          speed = (((0.50 * 3.1415) / elapsed )* 3.6).round(2)
          speed = -1 * speed if sp_char.match /B/
          reading = speed_reading(speed)
          #video_speed(reading)
          #p (reading > -45 && reading < 45) ? reading : 0
          p reading
          fan_speed reading
        end
        @last_tick = Time.now
      end  
    end
  end


  def speed_reading(speed)
    @speeds.shift
    @speeds.push(speed)
    result = (@speeds.inject{ |sum, el| sum + el } /  @speeds.size).round(2)
    #cap result to something sensible
    result = 60 if result > 60
    return result
  end

  def video_speed(reading)
    if reading < 5
      VlcControl.instance.ask("pause", false)
      @playing = false
    else
      VlcControl.instance.ask("play", false) unless @playing
      @playing = true
    end
    VlcControl.instance.ask("rate 0.5", false) if reading >= 5 && reading < 10
    VlcControl.instance.ask("rate 0.8", false) if reading >= 10  && reading < 15
    VlcControl.instance.ask("rate 1", false) if reading >= 15  && reading < 25
    VlcControl.instance.ask("rate 1.5", false) if reading >= 25
  end

  def fan_speed(reading)
    if reading >= 15 && @fans[0] == 0
      @sp.write 1
      @fans[0] = 1
    end
    if reading < 15 && @fans[0] == 1
      @sp.write 2
    end
  end
end
