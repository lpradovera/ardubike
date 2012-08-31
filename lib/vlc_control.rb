class VlcControl
  def self.instance
    @instance ||  VLCRC::VLC.new('localhost', 1234, "/Applications/VLC.app/Contents/MacOS/VLC")
  end
end
