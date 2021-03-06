# coding: utf-8

module Php4r
  def is_numeric(number)
    if (Float(number) rescue false)
      return true
    else
      return false
    end
  end
  
  def call_user_func(*paras)
    if paras[0].is_a?(String)
      send_paras = [paras[0].to_sym]
      send_paras << paras[1] if paras[1]
      send(*send_paras)
    elsif paras[0].is_a?(Array)
      send_paras = [paras[0][1].to_sym]
      send_paras << paras[1] if paras[1]
      paras[0][0].send(*send_paras)
    else
      raise "Unknown user-func: '#{paras[0].class.name}'."
    end
  end
  
  def method_exists(obj, method_name)
    return obj.respond_to?(method_name.to_s)
  end
  
  def is_a(obj, classname)
    classname = classname.to_s
    classname = "#{classname[0..0].upcase}#{classname[1..999]}"
    
    return true if obj.is_a?(classname)
    return false
  end
  
  def print_r(argument, ret = false, count = 1)
    retstr = ""
    cstr = argument.class.to_s
    supercl = argument.class.superclass
    superstr = supercl.to_s if supercl
    
    if argument.respond_to?(:to_hash)
      argument_use = argument.to_hash
      
      retstr << "#{argument.class.name}{\n"
      argument_use.each do |key, val|
        i = 0
        while i < count
          retstr << "   "
          i += 1
        end
        
        if key.is_a?(Symbol)
          keystr = ":#{key.to_s}"
        else
          keystr = key.to_s
        end
        
        retstr << "[#{keystr}] => "
        retstr << Php4r.print_r(val, true, count + 1).to_s
      end
      
      i = 0
      while i < count - 1
        retstr << "   "
        i += 1
      end
      
      retstr << "}\n"
    elsif argument.is_a?(String) or argument.is_a?(Integer) or argument.is_a?(Fixnum) or argument.is_a?(Float)
      retstr << "#{argument}\n"
    elsif argument.is_a?(Symbol)
      retstr << ":#{argument.to_s}\n"
    elsif argument.is_a?(Exception)
      retstr << "#\{#{argument.class.to_s}: #{argument.message}}\n"
    elsif cstr == "Thread"
      retstr << "#{argument.class.name} - "
      
      hash = {}
      argument.keys.each do |key|
        hash[key] = argument[key]
      end
      
      retstr << Php4r.print_r(hash, true, count).to_s
    elsif cstr == "Class"
      retstr << "#{argument.class.to_s} - "
      hash = {"name" => argument.name}
      retstr << Php4r.print_r(hash, true, count).to_s
    elsif cstr == "URI::Generic"
      retstr << "#{argument.class.to_s}{\n"
      methods = [:host, :port, :scheme, :path]
      count += 1
      methods.each do |method|
        i_spaces = 0
        while i_spaces < count - 1
          retstr << "   "
          i_spaces += 1
        end
        
        retstr << "#{method}: #{argument.send(method)}\n"
      end
      
      count -= 1
      
      i = 0
      while i < count - 1
        retstr << "   "
        i += 1
      end
      
      retstr << "}\n"
    elsif cstr == "Time" or cstr == "Datet"
      argument = argument.time if cstr == "Datet"
      retstr << "#{cstr}::#{"%04d" % argument.year}-#{"%02d" % argument.month}-#{"%02d" % argument.day} #{"%02d" % argument.hour}:#{"%02d" % argument.min}:#{"%02d" % argument.sec}\n"
    elsif argument.respond_to?(:to_a)
      retstr << "#{argument.class.name}{\n"
      
      arr_count = 0
      argument.to_a.each do |i|
        i_spaces = 0
        while i_spaces < count
          retstr << "   "
          i_spaces += 1
        end
        
        retstr << "[#{arr_count}] => "
        retstr << Php4r.print_r(i, true, count + 1).to_s
        arr_count += 1
      end
      
      i_spaces = 0
      while i_spaces < count - 1
        retstr << "   "
        i_spaces += 1
      end
      
      retstr << "}\n"
    else
      #print argument.to_s, "\n"
      retstr << "Unknown class: '#{cstr}' with superclass '#{supercl}'.\n"
    end
    
    if ret.is_a?(TrueClass)
      return retstr
    else
      print retstr
    end
  end
  
  def gettext(string)
    return GetText._(string)
  end
  
  #Returns the number as a formatted string.
  def number_format(number, precision = 2, seperator = ".", delimiter = ",")
    number = number.to_f if !number.is_a?(Float)
    precision = precision.to_i
    return sprintf("%.#{precision.to_s}f", number).gsub(".", seperator) if number < 1 and number > -1
    
    number = sprintf("%.#{precision.to_s}f", number).split(".")
    
    str = ""
    number[0].reverse.scan(/(.{1,3})/) do |match|
      if match[0] == "-"
        #This happens if the number is a negative number and we have reaches the minus-sign.
        str << match[0]
      else
        str << delimiter if str.length > 0
        str << match[0]
      end
    end
    
    str = str.reverse
    if precision > 0
      str << "#{seperator}#{number[1]}"
    end
    
    return str
  end
  
  def ucwords(string)
    return string.to_s.split(" ").select{|w| w.capitalize! or w }.join(" ")
  end
  
  def strtoupper(str)
    return str.to_s.upcase
  end
  
  def strtolower(str)
    return str.to_s.downcase
  end
  
  def htmlspecialchars(string)
    return string.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
  end
  
  def http_build_query(obj)
    return Php4r.http_build_query_rec("", obj)
  end
  
  def http_build_query_rec(orig_key, obj, first = true)
    url = ""
    first_ele = true
    
    if obj.is_a?(Array)
      ele_count = 0
      
      obj.each do |val|
        orig_key_str = "#{orig_key}[#{ele_count}]"
        val = "#<Model::#{val.table}::#{val.id}>" if val.respond_to?("is_knj?")
        
        if val.is_a?(Hash) or val.is_a?(Array)
          url << Php4r.http_build_query_rec(orig_key_str, val, false)
        else
          url << "&" if !first or !first_ele
          url << "#{Php4r.urlencode(orig_key_str)}=#{Php4r.urlencode(val)}"
        end
        
        first_ele = false if first_ele
        ele_count += 1
      end
    elsif obj.is_a?(Hash)
      obj.each do |key, val|
        if first
          orig_key_str = key
        else
          orig_key_str = "#{orig_key}[#{key}]"
        end
        
        val = "#<Model::#{val.table}::#{val.id}>" if val.respond_to?("is_knj?")
        
        if val.is_a?(Hash) or val.is_a?(Array)
          url << Php4r.http_build_query_rec(orig_key_str, val, false)
        else
          url << "&" if !first or !first_ele
          url << "#{Php4r.urlencode(orig_key_str)}=#{Php4r.urlencode(val)}"
        end
        
        first_ele = false if first_ele
      end
    else
      raise "Unknown class: '#{obj.class.name}'."
    end
    
    return url
  end
  
  def isset(var)
    return false if var == nil or var == false
    return true
  end
  
  def strpos(haystack, needle)
    return false if !haystack
    return false if !haystack.to_s.include?(needle)
    return haystack.index(needle)
  end
  
  def substr(string, from, to = nil)
    #If 'to' is not given it should be the total length of the string.
    if to == nil
      to = string.length
    end
    
    #The behaviour with a negative 'to' is not the same as in PHP. Hack it!
    if to < 0
      to = string.length + to
    end
    
    #Cut the string.
    string = "#{string[from.to_i, to.to_i]}"
    
    #Sometimes the encoding will no longer be valid. Fix that if that is the case.
    if !string.valid_encoding? and Php4r.class_exists("Iconv")
      string = Iconv.conv("UTF-8//IGNORE", "UTF-8", "#{string}  ")[0..-2]
    end
    
    #Return the cut string.
    return string
  end
  
  def md5(string)
    require "digest"
    return Digest::MD5.hexdigest(string.to_s)
  end
  
  def header(headerstr)
    match = headerstr.to_s.match(/(.*): (.*)/)
    if match
      key = match[1]
      value = match[2]
    else
      #HTTP/1.1 404 Not Found
      
      match_status = headerstr.to_s.match(/^HTTP\/[0-9\.]+ ([0-9]+) (.+)$/)
      if match_status
        key = "Status"
        value = match_status[1] + " " + match_status[2]
      else
        raise "Couldnt parse header."
      end
    end
    
    begin
      _hb.header(key, value) #This is for Hayabusa appserver - knj.
    rescue NameError
      _kas.header(key, value) #This is for knjappserver - knj.
    end
    
    return true
  end
  
  def nl2br(string)
    return string.to_s.gsub("\n", "<br />\n")
  end
  
  def urldecode(string)
    #Thanks to CGI framework
    str = string.to_s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/) do
      [$1.delete('%')].pack('H*')
    end
  end
  
  def urlencode(string)
    #Thanks to CGI framework
    string.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end.tr(' ', '+')
  end
  
  def file_put_contents(filepath, content)
    File.open(filepath.untaint, "w") do |file|
      file.write(content)
    end
    
    return true
  end
  
  def file_get_contents(filepath)
    filepath = filepath.to_s
    
    if http_match = filepath.match(/^http(s|):\/\/([A-z_\d\.]+)(|:(\d+))(\/(.+))$/)
      port = http_match[4].to_i if http_match[4].to_s.length > 0
      
      args = {
        :host => http_match[2]
      }
      
      if http_match[1] == "s"
        args[:ssl] = true
        args[:validate] = false
        
        if !port
          port = 443
        end
      end
      
      args[:port] = port if port
      
      require "http2"
      Http2.new(args) do |http|
        return http.get(http_match[5]).body
      end
    end
    
    return File.read(filepath.untaint)
  end
  
  def is_file(filepath)
    begin
      if File.file?(filepath)
        return true
      end
    rescue
      return false
    end
    
    return false
  end
  
  def is_dir(filepath)
    begin
      return true if File.directory?(filepath)
    rescue
      return false
    end
    
    return false
  end
  
  def unlink(filepath)
    FileUtils.rm(filepath)
  end
  
  def file_exists(filepath)
    return true if File.exists?(filepath.to_s.untaint)
    return false
  end
  
  def strtotime(date_string, cur = nil)
    require "datet"
    
    if !cur
      cur = Datet.new
    else
      cur = Datet.new(Time.at(cur))
    end
    
    date_string = date_string.to_s.downcase
    
    if date_string.match(/[0-9]+-[0-9]+-[0-9]+/i)
      begin
        return Time.local(*ParseDate.parsedate(date_string)).to_i
      rescue
        return 0
      end
    end
    
    date_string.scan(/((\+|-)([0-9]+) (\S+))/) do |match|
      timestr = match[3]
      number = match[2].to_i
      mathval = match[1]
      number = -number if mathval == "-"
      
      if timestr == "years" or timestr == "year"
        cur.add_years(number)
      elsif timestr == "months" or timestr == "month"
        cur.add_months(number)
      elsif timestr == "weeks" or timestr == "week"
        cur.add_days(number * 7)
      elsif timestr == "days" or timestr == "day"
        cur.add_days(number)
      elsif timestr == "hours" or timestr == "hour"
        cur.add_hours(number)
      elsif timestr == "minutes" or timestr == "minute" or timestr == "min" or timestr == "mints"
        cur.add_minutes(timestr)
      elsif timestr == "seconds" or timestr == "second" or timestr == "sec" or timestr == "secs"
        cur.add_seconds(number)
      end
    end
    
    return cur.to_i
  end
  
  def class_exists(classname)
    begin
      Kernel.const_get(classname)
      return true
    rescue
      return false
    end
  end
  
  def html_entity_decode(string)
    string = Php4r.htmlspecialchars(string)
    string = string.gsub("&oslash;", "ø").gsub("&aelig;", "æ").gsub("&aring;", "å").gsub("&euro;", "€").gsub("#39;", "'").gsub("&amp;", "&").gsub("&gt;", ">").gsub("&lt;", "<").gsub("&quot;", '"').gsub("&#039;", "'")
    return string
  end
  
  def strip_tags(htmlstr)
    htmlstr.scan(/(<([\/A-z]+).*?>)/) do |match|
      htmlstr = htmlstr.gsub(match[0], "")
    end
    
    return htmlstr.gsub("&nbsp;", " ")
  end
  
  def die(msg)
    print msg
    exit
  end
  
  def opendir(dirpath)
    res = {:files => [], :index => 0}
    Dir.foreach(dirpath) do |file|
      res[:files] << file
    end
    
    return res
  end
  
  def readdir(res)
    ret = res[:files][res[:index]] if res[:files].index(res[:index]) != nil
    return false if !ret
    res[:index] += 1
    return ret
  end
  
  def fopen(filename, mode)
    begin
      return File.open(filename, mode)
    rescue
      return false
    end
  end
  
  def fwrite(fp, str)
    begin
      fp.print str
    rescue
      return false
    end
    
    return true
  end
  
  def fputs(fp, str)
    begin
      fp.print str
    rescue
      return false
    end
    
    return true
  end
  
  def fread(fp, length = 4096)
    return fp.read(length)
  end
  
  def fgets(fp, length = 4096)
    return fp.read(length)
  end
  
  def fclose(fp)
    fp.close
  end
  
  def move_uploaded_file(tmp_path, new_path)
    FileUtils.mv(tmp_path.untaint, new_path.untaint)
  end
  
  def utf8_encode(str)
    str = str.to_s if str.respond_to?("to_s")
    
    if str.respond_to?("encode")
      begin
        return str.encode("iso-8859-1", "utf-8")
      rescue Encoding::InvalidByteSequenceError
        #ignore - try iconv
      end
    end
    
    require "iconv"
    
    begin
      return Iconv.conv("iso-8859-1", "utf-8", str.to_s)
    rescue
      return Iconv.conv("iso-8859-1//ignore", "utf-8", "#{str}  ").slice(0..-2)
    end
  end
  
  def utf8_decode(str)
    str = str.to_s if str.respond_to?(:to_s)
    require "iconv" if RUBY_PLATFORM == "java" #This fixes a bug in JRuby where Iconv otherwise would not be detected.
    
    if str.respond_to?(:encode)
      begin
        return str.encode("utf-8", "iso-8859-1")
      rescue Encoding::InvalidByteSequenceError
        #ignore - try iconv
      end
    end
    
    require "iconv"
      
    begin
      return Iconv.conv("utf-8", "iso-8859-1", str.to_s)
    rescue
      return Iconv.conv("utf-8//ignore", "iso-8859-1", str.to_s)
    end
  end
  
  def setcookie(cname, cvalue, expire = nil, domain = nil)
    args = {
      "name" => cname,
      "value" => cvalue,
      "path" => "/"
    }
    args["expires"] = Time.at(expire) if expire
    args["domain"] = domain if domain
    
    _kas.cookie(args)
    return status
  end
  
  #This method is only here for convertion support - it doesnt do anything.
  def session_start
    
  end
  
  def explode(expl, strexp)
    return strexp.to_s.split(expl)
  end
  
  def dirname(filename)
    File.dirname(filename)
  end
  
  def chdir(dirname)
    Dir.chdir(dirname)
  end
  
  def include_once(filename)
    require filename
  end
  
  def require_once(filename)
    require filename
  end
  
  def echo(string)
    print string
  end
  
  def count(array)
    return array.length
  end
  
  def json_encode(obj)
    if Php4r.class_exists("Rho")
      return Rho::JSON.generate(obj)
    elsif Php4r.class_exists("JSON")
      return JSON.generate(obj)
    else
      raise "Could not figure out which JSON lib to use."
    end
  end
  
  def json_decode(data, as_array = false)
    #FIXME: Should be able to return as object, which will break all projects using it without second argument...
    raise "String was not given to 'Php4r.json_decode'." if !data.is_a?(String)
    
    if Php4r.class_exists("Rho")
      return Rho::JSON.parse(data)        
    elsif Php4r.class_exists("JSON")  
      return JSON.parse(data)
    else
      raise "Could not figure out which JSON lib to use."
    end
  end
  
  def time
    return Time.now.to_i
  end
  
  def microtime(get_as_float = false)
    microtime = Time.now.to_f
    
    return microtime if get_as_float
    
    splitted = microtime.to_s.split(",")
    return "#{splitted[0]} #{splitted[1]}"
  end
  
  def mktime(hour = nil, min = nil, sec = nil, date = nil, month = nil, year = nil, is_dst = -1)
    cur_time = Time.new
    
    hour = cur_time.hour if hour == nil
    min = cur_time.min if min == nil
    sec = cur_time.sec if sec == nil
    date = cur_time.day if date == nil
    month = cur_time.month if month == nil
    year = cur_time.year if year == nil
    
    return Time.new(year, month, date, hour, min, sec).to_i
  end
  
  def date(date_format, date_input = nil)
    if date_input == nil
      date_object = Time.now
    elsif date_input.respond_to?(:to_time)
      date_object = date_input.to_time
    elsif (Float(date_input) rescue false)
      date_object = Time.at(date_input.to_i)
    elsif date_input.is_a?(Time)
      date_object = date_input
    else
      raise "Unknown date given: '#{date_input}', '#{date_input.class.name}'."
    end
    
    date_format = date_format.gsub("Y", "%Y").gsub("y", "%y").gsub("m", "%m").gsub("d", "%d").gsub("H", "%H").gsub("i", "%M").gsub("s", "%S")
    return date_object.strftime(date_format)
  end
  
  def basename(filepath)
    splitted = filepath.to_s.split("/").last
    return false if !splitted
    
    ret = splitted.split(".")
    ret.delete(ret.last)
    return ret.join(".")
  end
  
  def base64_encode(str)
    #The strict-encode wont do corrupt newlines...
    if Base64.respond_to?("strict_encode64")
      return Base64.strict_encode64(str.to_s)
    else
      return Base64.encode64(str.to_s)
    end
  end
  
  def base64_decode(str)
    return Base64.decode64(str.to_s)
  end
  
  def pathinfo(filepath)
    filepath = filepath.to_s
    
    dirname = File.dirname(filepath)
    dirname = "" if dirname == "."
    
    return {
      "dirname" => dirname,
      "basename" => Php4r.basename(filepath),
      "extension" => filepath.split(".").last,
      "filename" => filepath.split("/").last
    }
  end
  
  def realpath(pname)
    require "pathname"
    
    begin
      return Pathname.new(pname.to_s).realpath.to_s
    rescue => e
      return false
    end
  end
  
  # Returns the scripts current memory usage.
  def memory_get_usage
    # FIXME: This only works on Linux at the moment, since we are doing this by command line - knj.
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i * 1024
    return memory_usage
  end
  
  # Should return the peak usage of the running script, but I have found no way to detect this... Instead returns the currently memory usage.
  def memory_get_peak_usage
    return Php4r.memory_get_usage
  end
  
  def ip2long(ip)
    return IPAddr.new(ip).to_i
  end
  
  # Execute an external program and display raw output.
  def passthru(cmd)
    if RUBY_ENGINE == "jruby"
      IO.popen4(cmd) do |pid, stdin, stdout, stderr|
        tout = Thread.new do
          begin
            stdout.sync = true
            stdout.each do |str|
              $stdout.print str
            end
          rescue => e
            $stderr.puts e.inspect
            $stderr.puts e.backtrace
          end
        end
        
        terr = Thread.new do
          begin
            stderr.sync = true
            stderr.each do |str|
              $stderr.print str
            end
          rescue => e
            $stderr.puts e.inspect
            $stderr.puts e.backtrace
          end
        end
        
        tout.join
        terr.join
      end
    else
      require "open3"
      Open3.popen3(cmd) do |stdin, stdout, stderr|
        tout = Thread.new do
          begin
            stdout.sync = true
            stdout.each do |str|
              $stdout.print str
            end
          rescue => e
            $stderr.puts e.inspect
            $stderr.puts e.inspect
          end
        end
        
        terr = Thread.new do
          begin
            stderr.sync = true
            stderr.each do |str|
              $stderr.print str
            end
          rescue => e
            $stderr.puts e.inspect
            $stderr.puts e.backtrace
          end
        end
        
        tout.join
        terr.join
      end
    end
    
    return nil
  end
  
  # Thanks to this link for the following functions: http://snippets.dzone.com/posts/show/4509
  def long2ip(long)
    ip = []
    4.times do |i|
      ip.push(long.to_i & 255)
      long = long.to_i >> 8
    end
    
    ip.reverse.join(".")
  end
  
  def gzcompress(str, level = 3)
    require "zlib"
    
    zstream = Zlib::Deflate.new
    gzip_str = zstream.deflate(str.to_s, Zlib::FINISH)
    zstream.close
    
    return gzip_str
  end
  
  def gzuncompress(str, length = 0)
    require "zlib"
    
    zstream = Zlib::Inflate.new
    plain_str = zstream.inflate(str.to_s)
    zstream.finish
    zstream.close
    
    return plain_str.to_s
  end
  
  #Sort methods.
  def ksort(hash)
    nhash = hash.sort do |a, b|
      a[0] <=> b[0]
    end
    
    newhash = {}
    nhash.each do |val|
      newhash[val[0]] = val[1][0]
    end
    
    return newhash
  end
  
  #Foreach emulator.
  def foreach(element, &block)
    raise "No or unsupported block given." if !block.respond_to?(:call) or !block.respond_to?(:arity)
    arity = block.arity
    cname = element.class.name.to_s
    
    if element.is_a?(Array) or cname == "Array_enumerator"
      element.each_index do |key|
        if arity == 2
          block.call(key, element[key])
        elsif arity == 1
          block.call(element[key])
        else
          raise "Unknown arity: '#{arity}'."
        end
      end
    elsif element.is_a?(Hash)
      element.each do |key, val|
        if arity == 2
          block.call(key, val)
        elsif arity == 1
          block.call(val)
        else
          raise "Unknown arity: '#{arity}'."
        end
      end
    else
      raise "Unknown element: '#{element.class.name}'."
    end
  end
  
  #Array-function emulator.
  def array(*ele)
    return {} if ele.length <= 0
    
    if ele.length == 1 and ele.first.is_a?(Hash)
      return ele.first
    end
    
    return ele
  end
  
  def array_key_exists(key, arr)
    if arr.is_a?(Hash)
      return arr.key?(key)
    elsif arr.is_a?(Array)
      return true if arr.index(key) != nil
      return false
    else
      raise "Unknown type of argument: '#{arr.class.name}'."
    end
  end
  
  def empty(obj)
    if obj.respond_to?("empty?")
      return obj.empty?
    elsif obj == nil
      return true
    else
      raise "Dont know how to handle object on 'empty': '#{obj.class.name}'."
    end
  end
  
  def trim(argument)
    return argument.to_s.strip
  end
  
  def serialize(argument)
    require "php_serialize" #gem: php-serialize
    return PHP.serialize(argument)
  end
  
  def unserialize(argument)
    require "php_serialize" #gem: php-serialize
    return PHP.unserialize(argument.to_s)
  end
  
  def parse_str(str, hash)
    str.to_s.split("&").each do |value|
      pos = value.index("=")
      
      if pos != nil
        name = value[0..pos-1]
        valuestr = value.slice(pos+1..-1)
        parse_str_name(hash, name, valuestr)
      end
    end
    
    return hash
  end
  def is_array(var)
    var.kind_of?(Array) or var.kind_of?(Hash)
  end
  def addslashes(str)
    str.gsub(/['"\\\x0]/,'\\\\\0');
  end
  def stripslashes(str)
    eval("\"#{str}\"")
  end
  def str_replace(a,b,c)
    if a.respond_to?(:each)
      i = 0
      ret = c
      while i < a.length
        b[i] ||= ''
        ret = str_replace(a[i],b[i],ret)
      end
      return ret
    else
      return c.gsub(a,b)
    end
  end
  def preg_replace(a,b,c)
    if a.respond_to?(:each)
      i = 0
      ret = c
      while i < a.length
        b[i] ||= ''
        ret = str_replace(a[i],b[i],ret)
      end
      return ret
    else
      return c.gsub(eval(a),b)
    end
  end
  def time()
    Time.now.to_i
  end
  def strlen(str)
    str.length
  end
  def range(first_value, limit_value)
    (first_value..limit_value).to_a
  end
  def ord(char)
    char.to_s.ord
  end
  def chr(num)
    num.chr
  end
  
  private
  
  def Php4r.parse_str_name(seton, varname, value)
    if value.respond_to?(:filename) and value.filename
      realvalue = value
    else
      realvalue = Php4r.urldecode(value.to_s)
    end
    
    if varname and varname.index("[") != nil and match = varname.match(/\[(.*?)\]/)
      namepos = varname.index(match[0])
      name = varname.slice(0..namepos - 1)
      seton[name] = {} if !seton.key?(name)
      
      secname, secname_empty = parse_str_secname(seton[name], match[1])
      
      valuefrom = namepos + secname.to_s.length + 2
      restname = varname.slice(valuefrom..-1)
      
      if restname and restname.index("[") != nil
        seton[name][secname] = {} if !seton[name].key?(secname)
        parse_str_name_second(seton[name][secname], restname, value)
      else
        seton[name][secname] = realvalue
      end
    else
      seton[varname] = realvalue
    end
  end
  
  def Php4r.parse_str_secname(seton, secname)
    secname_empty = false
    if secname.length <= 0
      secname_empty = true
      try = 0
      
      loop do
        if !seton.key?(try.to_s)
          break
        else
          try += 1
        end
      end
      
      secname = try.to_s
    end
    
    return [secname, secname_empty]
  end
  
  def Php4r.parse_str_name_second(seton, varname, value)
    if value.respond_to?(:filename) and value.filename
      realvalue = value
    else
      realvalue = value.to_s
    end
    
    match = varname.match(/^\[(.*?)\]/)
    if match
      namepos = varname.index(match[0])
      name = match[1]
      secname, secname_empty = parse_str_secname(seton, match[1])
      
      valuefrom = namepos + match[1].length + 2
      restname = varname.slice(valuefrom..-1)
      
      if restname and restname.index("[") != nil
        seton[secname] = {} if !seton.key?(secname)
        parse_str_name_second(seton[secname], restname, value)
      else
        seton[secname] = realvalue
      end
    else
      seton[varname] = realvalue
    end
  end
  
  module_function(*instance_methods)
end