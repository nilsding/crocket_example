require "baked_file_system"
require "file_utils"

class FileStorage
  extend BakedFileSystem

  @@tmp_dir : String?

  bake_folder "../data"

  def self.tmp_dir
    @@tmp_dir ||= File.join(Dir.tempdir, "crocket_example_#{Time.now.to_unix_ms}")
  end

  def self.unpack
    print "Unpacking..."
    STDOUT.flush
    Dir.mkdir_p(tmp_dir)

    files.each do |baked_file|
      File.open(File.join(tmp_dir, baked_file.path.sub("/", "")), "wb") do |real_file|
        IO.copy baked_file, real_file
      end
    end
    puts " done"
  end

  def self.cleanup
    return if tmp_dir.nil?
    FileUtils.rm_rf(tmp_dir)
  end
end
