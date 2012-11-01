#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require "time"
require "nokogiri"
require "optparse"


# @param [Time] base_time
# @param [Float] factor
# @return [Time]
def multiply_time(base_time, factor)
  sec, min, hour, day, month, year, wday, yday, isdst, zone = base_time.to_a
  f_sec = sec + min*60 + hour*3600
  f_sec = (f_sec * factor).to_i
  f_hour = (f_sec / 3600).to_i
  f_sec = (f_sec-f_hour*3600).to_i
  f_min = (f_sec / 60).to_i
  f_sec = (f_sec-f_min*60).to_i
  Time.local(f_sec, f_min, f_hour, day, month, year, wday, yday, isdst, zone)
end

# @param [Time] current_time
# @param [Time] best_time
# @return [Integer]
def calculate_points_nor(best_time, current_time)
  if current_time <= best_time
    12
  elsif current_time <= multiply_time(best_time, 1.05)
    11
  elsif current_time <= multiply_time(best_time, 1.10)
    10
  elsif current_time <= multiply_time(best_time, 1.15)
    9
  elsif current_time <= multiply_time(best_time, 1.20)
    8
  elsif current_time <= multiply_time(best_time, 1.25)
    7
  elsif current_time <= multiply_time(best_time, 1.35)
    6
  elsif current_time <= multiply_time(best_time, 1.50)
    5
  elsif current_time <= multiply_time(best_time, 1.70)
    4
  elsif current_time <= multiply_time(best_time, 2.0)
    3
  elsif current_time <= multiply_time(best_time, 3.0)
    2
  else
    1
  end
end

# Classes ###########################
class PersonResult

  attr_accessor :person_id
  attr_accessor :family_name
  attr_accessor :given_name
  attr_accessor :club_id
  attr_accessor :club_name
  attr_accessor :club_short_name
  attr_accessor :time
  attr_accessor :state
  attr_accessor :position
  attr_accessor :rank_value

  def full_name
    "#{given_name} #{family_name}"
  end

  def get_position
    if position.nil? || position.empty?
      #puts state.to_s
      if state.to_s == "OK" || state.to_s == "NotCompeting"
        return "AK"
      elsif state.to_s == "MisPunch"
        return "Fehlst"
      elsif state.to_s == "DidNotFinish" || state.to_s == "SportWithdr"
        return "Aufg"
      elsif state.to_s == "DidNotStart" || state.to_s == "Cancelled"
        return "N Ang"
      elsif state.to_s == "Disqualified"
        return "Disq"
      elsif state.to_s == "OverTime"
        return "Lim"
      else
        return state.to_s
      end
    end
    position.to_s
  end

  def get_integer_position
    if position.nil? || position.empty?
      return 9999999
    end
    position
  end

  def get_club_name
    return club_short_name.to_s if !club_short_name.nil?
    return club_name.to_s if !club_name.nil?
    club_id.to_s
  end
end

class EventClass
  attr_accessor :name
  attr_accessor :best_time
  attr_accessor :results

  def ignore_in_nor
    #return true if name == "BK" || name == "BL"
    false
  end

end

class Event
  attr_accessor :name
  attr_accessor :event_classes
end

class CupContributor
  attr_accessor :given_name
  attr_accessor :family_name
  attr_accessor :class
  attr_accessor :points

  def full_name
    "#{given_name} #{family_name}"
  end

end

class ClubEventResult
  attr_accessor :club_name
  attr_accessor :points
  attr_accessor :contributors
end

class CupEventResult
  attr_accessor :event_name
  attr_accessor :club_event_results
end

class Cup
  attr_accessor :cup_event_results
  attr_accessor :cup_final_result
end

#####################################

def parse_xml_file(filename)
  puts "\nProcess file: #{filename}"

  doc = Nokogiri::XML(IO.read(filename))

  return if doc.nil?

  root_node = doc.root

  if root_node.name != "ResultList"
    puts "The file #{filename} is not a valid result list."
    return
  end

  event = Event.new
  event.event_classes = Array.new
  event.name = nil
  @events.push(event)

  root_node.children.each do |child|
    if child.name == "EventId"
      event.event_name = child.content
    elsif child.name == "Event"
      event.name = child.content
    elsif child.name == "ClassResult"
      class_result = EventClass.new
      class_result.results = Array.new
      event.event_classes.push(class_result)
      child.children.each do |class_child|
        if class_child.name == "ClassId"
          class_result.name = class_child.content
        elsif class_child.name == "ClassShortName"
          class_result.name = class_child.content
        elsif class_child.name == "EventClass"
          class_result.name = class_child.content
        elsif class_child.name == "PersonResult"
          person_result = PersonResult.new
          class_result.results.push(person_result)
          class_child.children.each do |person_result_child|
            if person_result_child.name == "Person"
              person_result_child.children.each do |personChild|
                if personChild.name == "PersonName"
                  family = personChild.search("Family").first
                  person_result.family_name = family.content if family
                  given = personChild.search("Given").first
                  person_result.given_name = given.content if given
                elsif personChild.name == "PersonId"
                  person_result.person_id = personChild.content
                end
              end
            elsif person_result_child.name == "PersonId"
              person_result.person_id = person_result_child.content
            elsif person_result_child.name == "Club"
              person_result_child.children.each do |clubChild|
                if clubChild.name == "ClubId"
                  person_result.club_id = clubChild.content
                elsif clubChild.name == "Name"
                  person_result.club_name = clubChild.content
                elsif clubChild.name == "ShortName"
                  person_result.club_short_name = clubChild.content
                end
              end
            elsif person_result_child.name == "ClubId"
              person_result.club_id = person_result_child.content
            elsif person_result_child.name == "Result"
              person_result_child.children.each do |resultChild|
                if resultChild.name == "Time"
                  person_result.time = Time.parse(resultChild.content) if !resultChild.content.empty?
                elsif resultChild.name == "ResultPosition"
                  person_result.position = resultChild.content if !resultChild.content.empty?
                elsif resultChild.name == "CompetitorStatus"
                  person_result.state = resultChild.attribute("value")
                end
              end
            end
          end
        end
      end
    end
  end

  event.name = filename if event.name.nil?

end

def sort_by_position
  @events.each do |event|
    event.event_classes.each do |event_class|
      event_class.results.sort! do |a, b|
        [a.get_integer_position.to_i, a.time.to_s, a.family_name, a.given_name] <=> [b.get_integer_position.to_i, b.time.to_s, b.family_name, b.given_name]
      end
    end
  end
end

def calculate_nor_points
  @events.each do |event|
    event.event_classes.each do |event_class|
      event_class.best_time = nil

      unless event_class.ignore_in_nor
        event_class.results.each do |person_result|
          next if (person_result.time.nil?)
          next if (person_result.position.nil?)
          if event_class.best_time.nil? || event_class.best_time > person_result.time
            event_class.best_time = person_result.time
          end
        end
      end

      event_class.results.each do |person_result|
        if event_class.ignore_in_nor
          person_result.rank_value = 0
        elsif person_result.time.nil? || person_result.position.nil?
          person_result.rank_value = 0
        else
          person_result.rank_value = calculate_points_nor(event_class.best_time, person_result.time)
        end
      end
    end
  end
end

def simple_output(dont_show_nor_points)
  @events.each do |event|
    puts "\n---------------------------------------"
    puts "Event: #{event.name}" if event.name
    event.event_classes.each do |event_class|
      puts "\n* #{event_class.name}"
      event_class.results.each do |person_result|
        rank = person_result.get_position
        printf "%8s %-40s %-40s %9s %2s\n" % [rank,
                                              person_result.full_name,
                                              person_result.club_short_name,
                                              !person_result.time.nil? ? person_result.time.strftime("%H:%M:%S") : "",
                                              person_result.rank_value!=0 ?
                                                  dont_show_nor_points ? "" : person_result.rank_value.to_s
                                              : ""]
      end
    end
  end
end

def calculate_fog_cup(cup_name)

  @cup.cup_event_results = Array.new

  @events.each do |event|

    # create & initialize cup event result
    cup_event_result = CupEventResult.new
    cup_event_result.club_event_results = Hash.new
    cup_event_result.event_name = event.name

    event.event_classes.each do |event_class|
      event_class.results.each do |person_result|
        club_name = person_result.get_club_name
        next if club_name.match("Volkssport")
        club_event_result = cup_event_result.club_event_results[club_name.to_sym]
        if club_event_result.nil?
          # create & store
          club_event_result = ClubEventResult.new
          club_event_result.contributors = Hash.new
          club_event_result.club_name = club_name
          club_event_result.points = 0
          cup_event_result.club_event_results.store(club_event_result.club_name.to_sym, club_event_result)
        end

        next if person_result.rank_value == 0

        contributor = club_event_result.contributors[event_class.name.to_sym]
        if contributor.nil?
          # add contributor
          contributor = CupContributor.new
          contributor.given_name = person_result.given_name
          contributor.family_name = person_result.family_name
          contributor.class = event_class.name
          contributor.points = person_result.rank_value
          club_event_result.contributors.store(contributor.class.to_sym, contributor)
          club_event_result.points += contributor.points
        end
      end
    end

    @cup.cup_event_results.push(cup_event_result)

  end

  # create & initialize cup final result
  cup_final_result = CupEventResult.new
  cup_final_result.club_event_results = Hash.new
  cup_final_result.event_name = cup_name
  @cup.cup_final_result = cup_final_result

  # Merge event results
  @cup.cup_event_results.each do |event_result|

    event_result.club_event_results.values.each do |club_event_result|

      club_final_result = cup_final_result.club_event_results[club_event_result.club_name.to_sym]

      if club_final_result.nil?
        # create & store
        club_final_result = ClubEventResult.new
        club_final_result.contributors = Hash.new
        club_final_result.club_name = club_event_result.club_name
        club_final_result.points = club_event_result.points
        cup_final_result.club_event_results.store(club_final_result.club_name.to_sym, club_final_result)
      else
        club_final_result.points += club_event_result.points
      end

      club_event_result.contributors.values.each do |contributor|
        final_contributor = club_final_result.contributors[contributor.full_name.to_sym]
        if final_contributor.nil?
          # add contributor
          final_contributor = CupContributor.new
          final_contributor.given_name = contributor.given_name
          final_contributor.family_name = contributor.family_name
          final_contributor.class = contributor.class
          final_contributor.points = contributor.points
          club_final_result.contributors.store(contributor.full_name.to_sym, final_contributor)
        else
          final_contributor.points += contributor.points
        end
      end
    end
  end

end

def simple_output_cup_event(event_result, with_class)
  puts "\n---------------------------------------"
  puts "Event name: #{event_result.event_name}"
  puts "\n"
  clubs_results = event_result.club_event_results.values
  clubs_results.sort! do |a, b|
    [-a.points, a.club_name] <=> [-b.points, b.club_name]
  end
  clubs_results.each do |club_event_result|
    puts "\n#{club_event_result.club_name} -> #{club_event_result.points}"
    puts "\n"
    contributors = club_event_result.contributors.values.sort do |a, b|
      [-a.points.to_i, a.full_name.to_s] <=> [-b.points.to_i, b.full_name.to_s]
    end
    contributors.each do |contributor|
      if with_class
        printf " %8s %s %d\n" % [contributor.class.to_s,
                                 contributor.full_name,
                                 contributor.points.to_i]
      else
        printf " %s %d\n" % [contributor.full_name,
                             contributor.points.to_i]
      end
    end
  end
end

def simple_output_cup
  @cup.cup_event_results.each do |event_result|
    simple_output_cup_event(event_result, true)
  end

  simple_output_cup_event(@cup.cup_final_result, false)

end

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

@events = Array.new

ARGV.each do |filename|
  parse_xml_file(filename)
end

sort_by_position
calculate_nor_points
simple_output(options[:dont_show_nor_points])

if !options[:fog_cup].nil?
  # create & initialize cup
  @cup = Cup.new

  calculate_fog_cup(options[:fog_cup])

  simple_output_cup
end

