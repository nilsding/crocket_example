require "crocket"
require "./audio"

DATA_DIR = File.expand_path(File.join(__DIR__, "../data"))
audio_path = File.join(DATA_DIR, "audio.mp3")

audio = Audio.new
audio.open(audio_path, bpm: 150, rows_per_beat: 4)

device = Crocket::SyncDevice.new("data/sync")

abort "failed to connect to host" unless device.tcp_connect("localhost")

Crocket::SyncDevice.define_pause_callback do |should_pause|
  if should_pause
    audio.pause
  else
    audio.play
  end
end
Crocket::SyncDevice.define_set_row_callback do |row|
  audio.row = row
end
Crocket::SyncDevice.define_is_playing_callback do
  !audio.is_paused?
end

clear_r = device["clear.r"]
clear_g = device["clear.g"]
clear_b = device["clear.b"]

# it's showtime!

audio.play

loop do
  row = audio.row
  break if row > 128

  device.tcp_connect("localhost") unless device.update(audio.row)

  r = (clear_r[row] * 255).ceil.to_i
  g = (clear_g[row] * 255).ceil.to_i
  b = (clear_b[row] * 255).ceil.to_i

  puts "\033[48;2;#{r};#{g};#{b}m"
end

device.save_tracks
audio.exit
