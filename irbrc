require 'irb/completion'
require 'rubygems'

begin
  require 'wirble'
  Wirble.init
  Wirble.colorize
rescue LoadError
  puts "Wirble not installed: sudo gem install wirble"
end

begin
  require 'hirb'
  Hirb.enable
rescue LoadError
  puts "Hirb not installed: sudo gem install hirb"
end

ARGV.concat [ "--readline", "--prompt-mode", "simple" ]
