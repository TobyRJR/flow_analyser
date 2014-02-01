#!/usr/bin/ruby

Traffic_units= { :k => 1000, :M => 1000000, :G => 1000000000, :T => 1000000000000 }

LOOKUP_PREFIX = "dig +short "
LOOKUP_SUFFIX = ".origin.asn.cymru.com TXT"
AS_LOOKUP_SUFFIX = ".asn.cymru.com TXT"

IP_PATTERN = /(\d{1,3}\.){3,3}\d{1,3}/
NUM_PATTERN = /\d+\.?\d*\s?[kKMGT]?/
DATE_PATTERN = /\d{4,4}-\d\d-\d\d\s\d\d:\d\d:\d\d\.?\d*/


class FieldFormat
  attr_accessor :ordered_fields

  def initialize(str)
    #puts str
    fields = { :date_time => ["Date first seen", DATE_PATTERN],
               :host => ["Src IP Addr", IP_PATTERN],
               :duration => ["Duration", /\d+\.?\d*/],
               :protocol => ["Proto", /[A-Za-z]+/],
               :flows => ["Flows", NUM_PATTERN],
               :packets => ["Packets", NUM_PATTERN],
               :bytes => ["Bytes", NUM_PATTERN], 
               :bps => ["bps", NUM_PATTERN],
               :pps => ["pps", NUM_PATTERN],
               :bpp => ["bpp", NUM_PATTERN] }
    str.gsub!("(%)","")
    
    field_sequence = {}
    
    fields.each do |key,value|
      #puts str
      field_sequence[key] = str.index(value[0])
      str = str.gsub(value[0]) { |s| " "*s.length }      
    end
    
    @ordered_fields = field_sequence.sort { |a,b| a[1] <=> b[1] }
    @ordered_fields.collect! { |pair| [pair[0],fields[pair[0]][1]] }    
    #puts ordered_fields.inspect
    #exit

  end
end

class AutoSys
  attr_accessor :number, :name, :bytes, :country

  class << self
    attr_accessor :names_map
    attr_accessor :collection
  end
  
  @names_map = {}
  @collection = {}

  def initialize(num,host)
    #@number = num
    #puts "num is #{num}"
    AutoSys.collection[num] = self 
    string = LOOKUP_PREFIX + host.reverse_address + LOOKUP_SUFFIX
    result =  `#{string}`.slice(1..-2).split("|")
    @number = "AS" + result[0].strip || "<no ASN>"
    @country = result[2] || "<no country>"    
    string = LOOKUP_PREFIX + @number + AS_LOOKUP_SUFFIX
    #puts string
    result = `#{string}`
    unless result =~ /.*\|.*/ then
      #AutoSys.names_map[@number] = "<no AS name>"
      @name = "<no AS name>"
    else
      #AutoSys.names_map[@number] = result.strip.slice(1..-2).split("|")[-1] || "<no AS name>"
      @name = result.strip.slice(1..-2).split("|")[-1] || "<no AS name>"
    end
  end

end

class Host
  attr_accessor :ip_address, :as # :as_country

  def initialize(args)
    @ip_address = args[:address]
    @as = AutoSys.collection[args[:asn]] || AutoSys.new(args[:address],self)    
  end

  def reverse_address
    @ip_address.split(".").reverse.join(".")
  end

  def details
    (ip_address || "nil") + " | " + (as.country || "nil") + " | " + (as.number || "nil") + " | " + (as.name || "nil") 
  end

end


class Record
  attr_accessor :host, :traffic_volume, :bytes

  def initialize(line,format)
    line.gsub!( /\(\s*\d+\.?\d*\s*\)/,"") 
    format.each do |pair|
      set_method = "set_" + pair[0].to_s
      pattern = pair[1]
      value = line.slice!(pattern)
      #puts "#{pair[0]} #{value}"
      if respond_to?(set_method) && value then self.send(set_method,value) end
    end
    #exit
  end

  def details
    unless host.nil?
      host.details + " | " + (bytes.to_s || "nil")
    end
  end

  def set_host(str)
    @host = Host.new(:address => str) 
  end

  def set_bytes(str)
    @bytes = str.split(" ")[0].to_f * (Traffic_units[str.split(" ")[1].intern] || 1).to_i
  end

  def set_asn
    @host.set_asn
  end

  def ip_address
    self.host ? host.ip_address : "<nil>"
  end

  def asn
    self.host ? host.asn : "<nil>"
  end

  def as_country
    self.host ? host.as_country : "<nil>"
  end

  def as_name
    self.host ? host.as_name : "<nil>"
  end

  def details_lookup
    if @host then
      @host.details_lookup
    end
  end

end

config = {}

for i in 0...ARGV.length
  arg = ARGV[i]
  case arg
  when "-c", "--config"
    config[:conf] = ARGV[i+1]
    i= i + 1
  when "-h", "--help"
    puts "Usage: tbc"
    exit
  else 
    config[:file] = arg
  end
end

source_file_name = config[:file] || (puts "No source file!" ; exit)

lines = []

File.open(source_file_name,"r") { |file|
  file.each_line do |line|
    lines << line
  end 
}

records =[]

header = lines.shift

field_format = FieldFormat.new(header).ordered_fields

lines.each do |line|
  records << Record.new(line,field_format)
end

records.each do |record|
  puts record.details
end

