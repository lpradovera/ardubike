require "rubygems"
require "bundler"
Bundler.setup
Bundler.require 

step = 1 

class SerialWrapper
  #include Celluloid

  def initialize
    port_str = "/dev/ttyUSB0"
    baud_rate = 9600  
    data_bits = 8  
    stop_bits = 1  
    parity = SerialPort::NONE 
    @sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
  end

  def write(arg)
    p "WRITE #{arg}"
    @sp.write arg
  end

  def getc
    @sp.getc
  end
end

class SpeedManager
  include Celluloid

  def initialize(sp, step=2)
    @sp = sp
    @step = step
    @acc = 0
    @first = true
    @playing = false
    @ventola = false
    @odorama1 = false
    @odorama2 = false
    @stopped_steps = 0
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
      if @acc == 0
        @stopped_steps += 1
      else
        @stopped_steps = 0
      end
    end
    p "LETTURA: #{@acc} rps - #{speed} kmh"
    @acc = 0
    if @stopped_steps * @step >= 10
      reset
    else
      video_speed(speed)
      odorama
    end
  end

  def video_speed(reading)
    if reading >= 0
      play_or_stop(reading)
      set_speed(0.5) if reading >= 5 && reading < 10
      set_speed(0.7) if reading >= 10  && reading < 15
      set_speed(1) if reading >= 15  && reading < 25
      set_speed(1.5) if reading >= 25 && reading < 35
      set_speed(2) if reading >= 35
    else
      seek_back('-2') if reading <= -1 && reading > -10
      seek_back('-5') if reading <= -10
    end
  end

  def reset
    p "RESET #{@stopped_steps}"
    @stopped_steps = 0
    #@sp.write 2 if @ventola == true
    #@sp.write 4 if @odorama1 == true
    #@sp.write 6 if @odorama2 == true
    #@ventola = false
    #@odorama1 = false
    #@odorama2 = false

    VlcControl.ask("pause", false) if @playing
    p "STOPPED"
    @playing = false
    VlcControl.ask("seek -1000", false)
    #odorama()
    ventola(0)
  end

  def odorama()
    pos = VlcControl.ask("get_time", true).to_i
    p "POSIZIONE VIDEO #{pos}"
    if pos > 30 && pos < 60
      if @odorama1 == false
        puts "Odorama 1 ON"
        @sp.write 3
        @odorama1 = true
      end
    else
      if @odorama1 == true
        puts "Odorama 1 OFF"
        @sp.write 4
        @odorama1 = false
      end
    end
    if pos > 70 && pos < 130
      if @odorama2 == false
        puts "Odorama 2 ON"
        @sp.write 5
        @odorama2 = true
      end
    else
      if @odorama2 == true
        puts "Odorama 2 OFF"
        @sp.write 6
        @odorama2 = false
      end
    end
  end

  def play_or_stop(reading)
    if reading < 5
      VlcControl.ask("pause", false) if @playing == true
      @current_speed = 0
      p "STOPPED"
      @playing = false
    else
      VlcControl.ask("pause", false) if @playing == false
      p "PLAYING"
      @playing = true
    end
  end

  def ventola(speed)
    if speed >= 1 && @ventola == false
      puts "******************************* Ventola ON"
      @ventola = true
      @sp.write 1
    end
    
    if speed < 1 && @ventola == true
      puts " *************************** Ventola OFF"
      @ventola = false
      @sp.write 2
    end
  end

  def set_speed(speed)
    VlcControl.ask("rate #{speed}", false) unless speed == @current_speed 
    @current_speed = speed
    ventola(speed)
  end

  def seek_back(secs)
    VlcControl.ask("pause", false) if @playing == false
    p "PLAYING"
    @playing = true
    VlcControl.ask("seek #{secs}", false)
  end
end

class VlcControl
  #include Celluloid
  def self.instance
    @instance ||  VLCRC::VLC.new('localhost', 1234, "/usr/bin/vlc")
  end

  def self.ask(command, response)
    p "VLCRC: #{command}"
    VlcControl.instance.ask(command, response)
  end

  def self.run
    self.instance.launch
    until self.instance.connected?
      p 'not connected'
      sleep 0.1
      self.instance.connect
    end
    self.instance.media = "/home/lgdemo/Video/3D_SxS_11lg_real_legends_of_flight.tp"
    #self.instance.media = "/home/lgdemo/Video/3D_TnB_12lg_2h_docu_world_cities_paris_ips_20130630.tp"
    VlcControl.ask("pause", false)
    VlcControl.ask("fullscreen", false)
  end
end

VlcControl.run
sp = SerialWrapper.new
sm = SpeedManager.new(sp, step)
sm.run!

while true do  
  sp_char = sp.getc  
  if sp_char && sp_char.match(/F|B/)
    p sp_char
    sm.step!(1) if sp_char.match(/F/)
    sm.step!(-1) if sp_char.match(/B/)
  end  
end
