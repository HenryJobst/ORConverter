#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require "time"
require "nokogiri"
require "optparse"
require "i18n"

require_relative "iof_result_list_reader"
require_relative "points_calculator"
require_relative "cupcalculation"
require_relative "fog_cup_original_html_report"
require_relative "fog_cup_standard_html_report"
require_relative "kristall_cup_standard_html_report"
require_relative "standard_html_result_report"

I18n.load_path = Dir.glob("config/locales/*.yml")
I18n.locale = "de"

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
  opts.on('-r', '--rank-mode [mode]', [:nebel, :nor, :kristall], 'rank mode (nebel, nor, kristall)') do |t|
    options[:rank_mode] = t || :nor
  end

  # calculate and present fog cup result
  options[:fog_cup] = nil
  opts.on('-f', '--fog-cup [TYPE]', [:original, :standard], 'calculate fog cup results with optional report type (original, standard)') do |t|
    options[:fog_cup] = t || :standard
    options[:cup_name] = "Nebel-Cup #{actual_year}"
  end

  # calculate and present kristall cup result
  options[:kristall_cup] = nil
  opts.on('-k', '--kristall-cup [TYPE]', [:original, :standard], 'calculate kristall cup results with optional report type (original, standard)') do |t|
    options[:kristall_cup] = t || :original
    options[:cup_name] = "Kristall-Cup #{actual_year}"
  end

  options[:linked_resources] = false
  opts.on('-l', '--linked-resources', 'use external resources (image links) instead of local resources') do
    options[:linked_resources] = true
  end


  # Show of points in reports
  options[:show_points] = true
  opts.on('-s', '--no-showpoints', "Show points in standard reports") do |v|
    options[:show_points] = v
    puts v
  end

  # Define the options, and what they do
  options[:verbose] = false
  opts.on('-v', '--verbose', 'Output more information') do
    options[:verbose] = true
  end

  # report name for the cup report
  options[:cup_name] = nil
  opts.on('--cup-name name', 'Cup name') do |n|
    options[:cup_name] = n
  end
  puts options[:cup_name] if (options[:verbose] && !options[:cup_name].nil?)

  # report name row 1
  options[:name1] = nil
  opts.on('--name1 name', 'Name 1 (first row) for a report, eg. event name)') do |n|
    options[:name1] = n
  end
  puts options[:name1] if (options[:verbose] && !options[:name1].nil?)

  # report name row 2
  options[:name2] = nil
  opts.on('--name2 Name', 'Name 2 (second row) for a report, eg. report name)') do |n|
    options[:name2] = n
  end
  puts options[:name2] if (options[:verbose] && !options[:name2].nil?)

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

iof_result_list_reader = IofResultListReader.new(ARGV, options[:verbose])

PointsCalculator.new(iof_result_list_reader.events, options[:rank_mode], options[:verbose])

iof_result_list_reader.simple_output(options[:show_points]) if options[:verbose]

StandardHtmlResultReport.new(iof_result_list_reader, options[:show_points], options[:name1], options[:name2])

unless options[:fog_cup].nil?
  puts "Process fog cup ..."
  cup = CupCalculation.new(options[:cup_name],
                           actual_year, iof_result_list_reader.events,options[:verbose], options[:rank_mode])
  if options[:fog_cup] == :original
    FogCupOriginalHtmlReport.new(cup, options[:linked_resources])
  elsif options[:fog_cup] == :standard
    FogCupStandardHtmlReport.new(cup, options[:linked_resources],
                                 options[:show_points], options[:name1], options[:name2])
  end
end

unless options[:kristall_cup].nil?
  puts "Process kristall cup ..."
  cup = CupCalculation.new(options[:cup_name],
                           actual_year, iof_result_list_reader.events, options[:verbose], options[:rank_mode])
  if options[:kristall_cup] == :original
    KristallCupOriginalHtmlReport.new(cup, options[:linked_resources], options[:name1], options[:name2])
  end
end
