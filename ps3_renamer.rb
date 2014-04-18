require 'net/ftp'
# Reads a PARAM.SFO and get all Keys and values to a Hash
# more details can be found on
# http://www.psdevwiki.com/ps3/PARAM.SFO
# file = PARAM.SFO file (already opened in binary mode and with read access)
def read_param_sfo(file)
  params = {}
  file.pos = 0x08
  key_table_start = file.read(0x04).unpack("l<").first
  data_table_start = file.read(0x04).unpack("l<").first
  tables_entries = file.read(0x04).unpack("l<").first
  index_table = file.pos
  tables_entries.times do |n|
    pos = file.pos
    key_offset = file.read(0x02).unpack("s<").first
    data_fmt = file.read(0x02).unpack("s<").first
    data_len = file.read(0x04).unpack("l<").first
    data_max = file.read(0x04).unpack("l<").first
    data_offset = file.read(0x04).unpack("l<").first
    file.pos = key_offset + key_table_start
    key = (file.gets(0.chr)[0...-1]).to_sym
    file.pos = data_offset + data_table_start
    params[key] = file.gets(data_len - 1)
    file.pos = pos + 0x10
  end
  params
end


# Strip out the non-ascii character and
# remove duplicate underscores
def sanitize_filename!(filename)
   # Strip out the non-ascii character
   filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
   # remove duplicate underscores
   filename.gsub!(/_+/, '_')
   filename
end

# Searches from a path for PS3 game folders and apply the renaming pattern.
def rename_ps3_folders(root_path, rename_theme)
  root_path = Dir.pwd unless root_path
  rename_theme = "%{TITLE} - %{TITLE_ID}" unless rename_theme

  raise "Directory does not exist" unless Dir.exist? root_path
  Dir.foreach(root_path) {|filename|
    if Dir.exist? file_path = File.join(root_path, filename) and ![".", ".."].include? filename
      if File.exist? param_path = File.join(file_path, "PS3_GAME", "PARAM.SFO")
          params = nil
          file = File.open(param_path, "rb") do |file|
            params = read_param_sfo(file)
          end
          if params
            renamed_dir = sanitize_filename!((rename_theme % params).strip.upcase)
            newname = File.join(root_path, renamed_dir)
            if file_path != newname
              raise "Directory #{newname} already exists" if Dir.exist? newname
              File.rename file_path, newname
              puts "Renamed: #{newname}"
            end
          end
      end
    end
  }
end

# Opens a ftp connection with PS3 and rename the directories
def ftp_rename(host, games_path, rename_theme)
  host = "10.0.0.147" unless host
  games_path = 'dev_hdd0/GAMES' unless games_path
  rename_theme = "%{TITLE} - %{TITLE_ID}" unless rename_theme
  Net::FTP.open(host) do |ftp|
    ftp.login
    ftp.chdir(games_path)
    ftp.nlst.each do |filename|
      unless filename == "." or filename == ".."
        param_path = filename + "/PS3_GAME/PARAM.SFO"
        begin
          params = nil
          ftp.getbinaryfile(param_path, "PARAM.SFO.TEMP")
          file = File.open("PARAM.SFO.TEMP", "rb") do |file|
            params = read_param_sfo(file)
          end
          if params
            newname = sanitize_filename!((rename_theme % params).strip.upcase)
            if (newname != filename)
              ftp.rename(filename, newname)
              puts "Renamed: #{newname}"
            end
          end
        rescue Net::FTPPermError => exception

        end
      end
    end
  end
end

if (first_arg = ARGV.shift).upcase == "FTP"
  #raise "FTP function not implemented yet"
  host = ARGV.shift
  games_path = ARGV.shift
  rename_theme = ARGV.shift
  ftp_rename(host, games_path, rename_theme)
else
  dir = first_arg
  rename_theme = ARGV.shift
  rename_ps3_folders(dir, rename_theme)
end
