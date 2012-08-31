require "rubygems"
require "bundler"
Bundler.setup
Bundler.require

require("./lib/ardubike")
require("./lib/vlc_control")



#vlc = VlcControl.instance
#vlc.launch

#until vlc.connected?
  #p 'not connected'
  #sleep 0.1
  #vlc.connect
#end

#vlc.media = "/Users/luca/Documents/ArduBike/spiderman.mp4"
#vlc.pause

Ardubike.new("/dev/tty.usbserial-A9007N5X").run
