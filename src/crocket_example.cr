require "crocket"
require "./audio"

{% if flag?(:sync_player) %}
require "./file_storage"

FileStorage.unpack
at_exit do
  FileStorage.cleanup
end
{% end %}

audio_path = {% if flag?(:sync_player) %}
               File.join(FileStorage.tmp_dir, "audio.mp3")
             {% else %}
               "data/audio.mp3"
             {% end %}

audio = Audio.new
audio.open(audio_path, bpm: 150, rows_per_beat: 4)

device = Crocket::SyncDevice.new(
  {% if flag?(:sync_player) %}
  # Workaround: librocket-player does not like absolute paths
  # TODO: look figure out how to use Rocket's `sync_set_io_cb` with
  # BakedFileSystem
  File.join(
    Array.new(Dir.current.split("/").size - 1, "..").join("/"),
    FileStorage.tmp_dir,
    "sync")
  {% else %}
  "data/sync"
  {% end %}
)

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
  # Fiber.yield
end

device.save_tracks
audio.exit
