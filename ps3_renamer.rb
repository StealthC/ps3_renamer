def sanitize_filename!(filename)
   # Strip out the non-ascii character
   filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
   filename.gsub!(/_+/, '_')
   filename
end

def read_params(param_path)
  #http://www.psdevwiki.com/ps3/PARAM.SFO
  params = nil
  file = File.open(param_path, "rb") { |file|
    params = {}
    file.pos = 0x08
    key_table_start = file.read(0x04).unpack("l<").first
    data_table_start = file.read(0x04).unpack("l<").first
    tables_entries = file.read(0x04).unpack("l<").first
    index_table = file.pos
    tables_entries.times{|n|
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
    }
  }
  params
end
def rename_ps3_folders(root_path = Dir.pwd, rename_theme)
  raise "Diretório não existe" unless Dir.exist? root_path
  Dir.foreach(root_path) {|filename|
    if Dir.exist? file_path = File.join(root_path, filename) and ![".", ".."].include? filename
      if File.exist? param_path = File.join(file_path, "PS3_GAME", "PARAM.SFO")
          params = read_params(param_path)
          if params
            renamed_dir = sanitize_filename!((rename_theme % params).strip.upcase)
            newname = File.join(root_path, renamed_dir)
            if (file_path != newname)
              raise "Diretório #{newname} já existe" if Dir.exist? newname
              File.rename file_path, newname
              puts "Renomeado: #{newname}"
            end
          end
      end
    end
  }
end


vars = {}
vars[:rename_theme] = "%{TITLE} - %{TITLE_ID}"
vars[:dir] = ARGV.shift
rename_ps3_folders(vars[:dir], vars[:rename_theme])
