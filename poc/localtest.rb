require "rubygems"
require "bundler"
Bundler.setup
Bundler.require 

class FakeSerial
  include Celluloid
  def initialize
    @step = 0
    @current_timer = nil
  end

  def set_speed
    @current_timer.cancel if @current_timer
    if @step.abs > 0
      time = 1/@step.abs.to_f
      @current_timer = every(time) {
        run_step
      }
    end
  end
  
  def speed_up
    @step += 1
    set_speed
  end

  def speed_down
    @step -= 1
    set_speed
  end

  def stop
    @step = 0
    set_speed
  end

  def run_step
    SpeedManager.instance.step!(@step/@step.abs)
  end
end

class SpeedManager
  include Celluloid
  def self.instance
    @instance ||= SpeedManager.new
  end

  def initialize(step=2)
    @step = step
    @acc = 0
    @first = true
    @playing = false
    @current_speed = 0
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
    p "LETTURA: #{speed} #{VlcControl.instance.position}"
    video_speed(speed)
    @acc = 0
  end

  def video_speed(reading)
    play_or_stop(reading)
    set_speed(0.3) if reading >= 5 && reading < 10
    set_speed(0.8) if reading >= 10  && reading < 15
    set_speed(1) if reading >= 15  && reading < 25
    set_speed(1.5) if reading >= 25
  end

  def play_or_stop(reading)
    if reading < 5
      VlcControl.instance.ask("pause", false)
      @current_speed = 0
      @playing = false
    else
      VlcControl.instance.ask("play", false) unless @playing
      @playing = true
    end
  end

  def set_speed(speed)
    VlcControl.instance.ask("rate #{speed}", false) unless speed == @current_speed 
    @current_speed = speed
  end
end

class VlcControl
  include Celluloid
  def self.instance
    @instance ||  VLCRC::VLC.new('localhost', 1234, "/usr/bin/vlc")
  end

  def self.run
    self.instance.launch
    until self.instance.connected?
      p 'not connected'
      sleep 0.1
      self.instance.connect
    end
    self.instance.media = "/home/lgdemo/Video/3D_TnB_12lg_2h_docu_world_cities_paris_ips_20130630.tp"
    self.instance.pause
  end
end

fs = FakeSerial.new
VlcControl.run
SpeedManager.instance.run!

loop do
  cmd = STDIN.gets.chomp
  case cmd
  when "q"
    puts "Goodbye"
    VlcControl.instance.exit
    break
  when "u"
    fs.speed_up!
  when "d"
    fs.speed_down!
  when "s"
    puts "Stopped"
    fs.stop!
  else
    puts "Unknown command #{cmd}"
  end
  printf "> "
end

