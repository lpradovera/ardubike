require "rubygems"
require "bundler"
Bundler.setup
Bundler.require

#port_str = "/dev/tty.usbserial-A9007N5X"
port_str = "/dev/ttyUSB0"
baud_rate = 9600  
data_bits = 8  
stop_bits = 1  
parity = SerialPort::NONE 
sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
printf "> "

Thread.new do 
  while true do  
    sp_char = sp.getc
    puts "COMING IN FROM SERIAL: #{sp_char}" if sp_char  
  end
end.run

loop do
  cmd = STDIN.gets.chomp
  case cmd
  when "quit"
    puts "Goodbye"
    break
  when "1on"
    sp.write 1
  when "1off"
    sp.write 2
  when "2on"
    sp.write 3
  when "2off"
    sp.write 4
  when "3on"
    sp.write 5
  when "3off"
    sp.write 6
  else
    puts "Unknown command #{cmd}"
  end
  printf "> "
end
