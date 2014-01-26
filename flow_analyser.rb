Traffic_units= { :k => 10^3, :M => 10^6, :G => 10^9 }

LOOKUP_PREFIX = "dig +short "
LOOKUP_SUFFIX = ".origin.asn.cymru.com TXT"
AS_LOOKUP_SUFFIX = ".asn.cymru.com TXT"

class Host
  attr_accessor :ip_address, :asn, :as_name

  def initialize(args)
    @ip_address = args[:address]
    @asn = args[:asn]    
    @as_name = args[:as_name]    
  end

  def reverse_address
    @ip_address.split(".").reverse.join(".")
  end

  def set_asn
    string = LOOKUP_PREFIX + self.reverse.address + LOOKUP_SUFFIX
    self.asn =  `#{string}`.split("|")[0].strip
  end

  def set_as_name
    string = LOOKUP_PREFIX + @asn + AS_LOOKUP_SUFFIX
    self.as_name = `#{string}`.split("|")[-1].strip
  end
end

class Record
  attr_accessor :host, :traffic_volume

  def initialize(args)
    @host = args[:host]
    @traffic_volume = args[:traffic] * Traffic_units[args[:units]]
  end

  def set_asn
    @host.set_asn
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
  puts record.ip_address +"\t" + record.asn + "\t" + record.as_name
end
