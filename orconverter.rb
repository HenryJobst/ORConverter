#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require "time"
require "nokogiri"
require "optparse"

require_relative "iof_result_list_reader"
require_relative "fog_cup"
require_relative "fog_cup_original_html_report"
require_relative "fog_cup_standard_html_report"
require_relative "standard_html_result_report"

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

actual_year = Time.now.strftime("%Y")

optparse = OptionParser.new do |opts|

  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: ORConverter.[rb|exe] [options] file1 file2 ..."

  # rank mode
  options[:rank_mode] = nil
  opts.on('-r', '--rank_mode [mode]', 'rank mode (nor, kristall)') do |f|
    options[:rank_mode] = (f || "nor").to_sym
  end

  # calculate and present fog cup result
  options[:fog_cup] = nil
  opts.on('-f', '--fog_cup [report-type]', 'calculate fog cup results with optional report type (1 - Original, 2 - Standard)') do |f|
    options[:fog_cup] = f || 1
    @cup_name = "Nebel-Cup #{actual_year}"
  end

  options[:linked_resources] = false
  opts.on('-l', '--linked_resources', 'use external resources (image links) instead of local resources') do
    options[:linked_resources] = true
  end


  # Disable show of NOR-points
  options[:dont_show_points] = false
  opts.on('--dont_show_points', "Don't show points in in simple output") do
    options[:dont_show_points] = true
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

iof_result_list_reader = IofResultListReader.new(ARGV, options[:rank_mode],
                                                 options[:verbose], options[:dont_show_points])

StandardHtmlResultReport.new(iof_result_list_reader, options[:dont_show_points])

if !options[:fog_cup].nil?
  fog_cup = FogCup.new(@cup_name, actual_year, iof_result_list_reader.events,
                       options[:verbose])
  if options[:fog_cup] == 1
    FogCupOriginalHtmlReport.new(fog_cup, options[:linked_resources])
  elsif options[:fog_cup] == 2
    FogCupStandardHtmlReport.new(fog_cup, options[:linked_resources])
  end
end
