Traffic_units= { :k => 1000, :M => 1000000, :G => 1000000000 }

LOOKUP_PREFIX = "dig +short "
LOOKUP_SUFFIX = ".origin.asn.cymru.com TXT"
AS_LOOKUP_SUFFIX = ".asn.cymru.com TXT"

class Host
  attr_accessor :ip_address, :asn, :as_name, :as_country

  def initialize(args)
    @ip_address = args[:address]
    @asn = args[:asn]    
    @as_name = args[:as_name]    
  end

  def reverse_address
    @ip_address.split(".").reverse.join(".")
  end

  def set_asn
    string = LOOKUP_PREFIX + self.reverse_address + LOOKUP_SUFFIX
    self.asn =  "AS" + `#{string}`.slice(1..-2).split("|")[0].strip || "<no ASN>"
  end

  def set_as_name
    string = LOOKUP_PREFIX + @asn + AS_LOOKUP_SUFFIX
    self.as_name = `#{string}`.split("|")[-1] || "<no AS name>"
  end

  def details_lookup
    string = LOOKUP_PREFIX + self.reverse_address + LOOKUP_SUFFIX
    as_lookup = `#{string}`.slice(1..-2).split("|")
    self.asn = "AS" + as_lookup[0].strip || "<no ASN>"
    self.as_country = as_lookup[2] || "<no country>"
    string = LOOKUP_PREFIX + @asn + AS_LOOKUP_SUFFIX
    #puts "#{string}"
    #puts `#{string}`
    self.as_name = `#{string}`.slice(1..-2).split("|")[-1] || "<no AS name>"    
  end
end

class Record
  attr_accessor :host, :traffic_volume

  def initialize(args)
    #puts args
    @host = args[:host]
    #puts "#{args[:traffic]}  #{args[:units]}  #{Traffic_units[args[:units].to_sym]}"
    #puts 19.6 * 1000000000
    #puts Traffic_units[args[:units].to_sym]
    #puts args[:traffic] * Traffic_units[args[:units].to_sym]
    @traffic_volume = (args[:traffic].to_f * Traffic_units[args[:units].to_sym]).to_i
    #@traffic_volume = 19.6 * 1000000000
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

  def as_name
    self.host ? host.as_name : "<nil>"
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
  lines << line.gsub(/[(][^A-Za-z]*[)]/,'')    
  end 
}

records =[]

lines.each do |line|
  fields = line.split(" ") || next
  #puts fields.to_s
  #puts fields[4] + "\t" + fields[6] + fields[7]
  records << Record.new(:host => Host.new(:address => fields[4]), :traffic => fields[6], :units => fields[7])
end

records.each do |record|
  #record.host.set_asn
  #record.host.set_as_name
  record.host.details_lookup
  puts record.ip_address + "\t" + record.asn + "\t" + record.as_name + record.traffic_volume.to_s
end
