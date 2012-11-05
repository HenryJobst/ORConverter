#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require "time"
require "nokogiri"
require "optparse"

require_relative "iof_result_list_reader"
require_relative "fog_cup"
require_relative "fog_cup_original_html_output"

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

actual_year = Time.now.strftime("%Y")

optparse = OptionParser.new do |opts|

  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: ORConverter.[rb|exe] [options] file1 file2 ..."

  # calculate and present fog cup result
  options[:fog_cup] = nil
  opts.on('-f', '--fog_cup [cupname]', 'calculate fog cup results with optional cup name') do |f|
    options[:fog_cup] = f || "Nebel-Cup #{actual_year}"
  end

  options[:linked_resources] = false
  opts.on('-l', '--linked_resources', 'use external resources (image links) instead of local resources') do
    options[:linked_resources] = true
  end


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

iof_result_list_reader = IofResultListReader.new(ARGV)
iof_result_list_reader.simple_output(options[:dont_show_nor_points]) if options[:verbose]

if !options[:fog_cup].nil?
  cup_name = options[:fog_cup]
  fog_cup = FogCup.new(cup_name, actual_year, iof_result_list_reader.events)
  fog_cup.simple_output_cup if options[:verbose]
  FogCupOriginalHtmlOutput.new(options[:linked_resources])
  fog_cup.html_output_cup(options[:linked_resources])
end
