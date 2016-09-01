require "csv"
require "json"
require 'optparse'
require 'ostruct'

options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-j', '--json JSON_FILE', 'The json file') { |o| options.json = o }
  opt.on('-c', '--csv CSV_FILE', 'The CSV file') { |o| options.csv = o }
end.parse!

CSV.open(options.csv, "w") do |csv|
  JSON.parse(File.open(options.json).read).each do |hash|
  	csv << hash.values
  end
end

#puts csv_string
