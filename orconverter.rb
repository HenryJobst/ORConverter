#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require "time"
require "nokogiri"
require "optparse"

#load "iof_result_list_reader.rb"
load "fog_cup.rb"

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do |opts|

  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: ORConverter.[rb|exe] [options] file1 file2 ..."

  # calculate and present fog cup result
  options[:fog_cup] = nil
  opts.on('-f', '--fog_cup [cupname]', 'calculate fog cup results with optional cup name') do |f|
    options[:fog_cup] = f || "Cup"
  end

  puts options[:fog_cup].to_s


  # Disable show of NOR-points
  options[:dont_show_nor_points] = false
  opts.on('--dont_show_nor_points', "Don't show NOR points") do
    options[:dont_show_nor_points] = true
  end

  # Define the options, and what they do
  options[:verbose] = false
  opts.on('-v', '--verbose', 'Output more information') do
    options[:verbose] = true
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

puts "Being verbose" if options[:verbose]

iof_result_list_reader = IofResultListReader.new

ARGV.each do |filename|
  iof_result_list_reader.parse_xml_file(filename)
end

iof_result_list_reader.sort_by_position
iof_result_list_reader.calculate_nor_points
iof_result_list_reader.simple_output(options[:dont_show_nor_points])

if !options[:fog_cup].nil?
  fogCup = FogCup.new(options[:fog_cup], iof_result_list_reader.events)
  fogCup.simple_output_cup
end
