require "libao"
require "libmpg123"

# This class contains some code borrowed by mjago/sonicri
#
# License: MIT
#
# https://github.com/mjago/sonicri/blob/c8504c20/src/sonicri/audio.cr
class Audio
  BYTE_FORMAT = LibAO::Byte_Format::AO_FMT_BIG
  BUFFER_SIZE = 1024 * 6

  @quit = false
  @pause = false
  @deque = Deque(UInt8).new(BUFFER_SIZE)
  @sample_rate = 0_i64
  @decoded_bytes = 0_i64
  @ao_buf = Bytes.new(BUFFER_SIZE)
  @play_chan = Channel(Nil).new

  @bpm = 150
  @rows_per_beat = 8
  @row_rate = 0.0

  def initialize(@ao = Libao::Ao.new, @mpg = Libmpg123::Mpg123.new)
    @row_rate = (@bpm / 60.0) * @rows_per_beat
    @mpg.new(nil)
    @mpg.param(:flags, :quiet)
  end

  def open(audio_path, bpm = 150, rows_per_beat = 8, start_playing = false)
    @bpm = bpm
    @rows_per_beat = rows_per_beat
    @row_rate = (@bpm / 60.0) * @rows_per_beat

    @mpg.open(audio_path)
    @mpg.param(:flags, :quiet, 0.0)
    sample_length = @mpg.length
    @mpg.seek(0_i64)
    @pause = true
    start_fibers
    play if start_playing
  end

  def row : Float
    return 0.0 if @sample_rate == 0
    seconds = (@mpg.sample_offset) / @sample_rate.to_f
    seconds * @row_rate
  end

  def row=(position : Int32)
    return if @row_rate == 0
    offset = (position / @row_rate * @sample_rate).floor
    @mpg.seek(offset, :seek_set)
  end

  def play
    @pause = false
  end

  def pause
    @pause = true
  end

  def is_paused?
    @pause
  end

  def exit
    @quit = true
    @mpg.exit
    @ao.exit
    @deque.clear
  end

  private def start_fibers
    start_decode_fiber
    start_play_fiber
  end

  private def start_decode_fiber
    spawn do
      until @quit
        while @pause
          sleep 0.1
        end
        break if @quit

        size = @deque.size
        data = Bytes.new(size) { @deque.shift }
        result = decode(in: data, insize: size, outsize: BUFFER_SIZE)
        process_decode_result(result)
        Fiber.yield
      end
    end
  end

  private def decode(in, insize, outsize)
    return unless input = in
    @mpg.decode(input, insize.to_i64,
      @ao_buf, outsize.to_i64,
      pointerof(@decoded_bytes))
  end

  private def process_decode_result(result)
    case result
    when LibMPG::Errors::DONE.value
      @mpg.seek(0)
    when LibMPG::Errors::NEW_FORMAT.value
      set_audio_format
    when LibMPG::Errors::OK.value
      @play_chan.send(nil)
    when LibMPG::Errors::NEED_MORE.value
    when LibMPG::Errors::BAD_HANDLE.value
      raise("bad handle")
    end
    Fiber.yield
  end

  private def set_audio_format
    @sample_rate = 0_i64
    @decoded_bytes = 0_i64
    channels = encoding = 0
    @mpg.get_format(pointerof(@sample_rate), pointerof(channels), pointerof(encoding))
    bits = @mpg.encsize(encoding) * 8
    @ao.set_format(bits, @sample_rate, channels, BYTE_FORMAT, matrix = nil)
    @ao.open_live
  end

  private def start_play_fiber
    spawn do
      until @quit
        @play_chan.receive
        @ao.play(@ao_buf, @decoded_bytes)
        Fiber.yield
      end
    end
  end
end
