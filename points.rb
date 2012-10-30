require 'time'
require 'optparse'
require 'nokogiri'

def mpl(t, f)
  sec, min, hour, day, month, year, wday, yday, isdst, zone = t.to_a
  fsec = sec + min*60 + hour*3600
  fsec = (fsec * f).to_i
  fhour = (fsec / 3600).to_i
  fsec = (fsec-fhour*3600).to_i
  fmin =  (fsec / 60).to_i
  fsec = (fsec-fmin*60).to_i
  Time.local(fsec,fmin,fhour,day,month,year,wday,yday,isdst,zone)
end

def calculatePointsNOR(bestTime, currentTime)
  if currentTime <= bestTime
    return 12
  elsif currentTime <= mpl(bestTime, 1.05)
    return 11
  elsif currentTime <= mpl(bestTime, 1.10)
    return 10
  elsif currentTime <= mpl(bestTime, 1.15)
    return 9
  elsif currentTime <= mpl(bestTime, 1.20)
    return 8
  elsif currentTime <= mpl(bestTime, 1.25)
    return 7
  elsif currentTime <= mpl(bestTime, 1.35)
    return 6
  elsif currentTime <= mpl(bestTime, 1.50)
    return 5
  elsif currentTime <= mpl(bestTime, 1.70)
    return 4
  elsif currentTime <= mpl(bestTime, 2.0)
    return 3
  elsif currentTime <= mpl(bestTime, 3.0)
    return 2
  else
    return 1
  end
end

# Classes ###########################
 class PersonResult
        attr_accessor :personId
        attr_accessor :familyName
        attr_accessor :givenName
        attr_accessor :clubId
        attr_accessor :clubName
        attr_accessor :clubShortName
        attr_accessor :time
        attr_accessor :state
        attr_accessor :position
        attr_accessor :rankValue
        
  def getPosition
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
    return position.to_s
  end
end

class EventClass
  attr_accessor :name
  attr_accessor :bestTime
  attr_accessor :results
  
  def ignoreInNOR
    if name == "BK" || name == "BL"
      return true
    end
    return false
  end
  
end

class Event
  attr_accessor :name
  attr_accessor :eventClasses
end
#####################################

def parse(filename)
  puts "Process file: #{filename}"

  doc = Nokogiri::XML(IO.read(filename))
  
  return if doc.nil?
  
  #validateResult = doc.validate
  #if !validateResult.nil?
  #  puts "The file #{filename} don't fit against it's DTD."
  #  validateResult.each do | line |
  #    puts line
  #  end
  #end
 rootNode = doc.root
 
 if rootNode.name != "ResultList"
   puts "The file #{filename} is not a valid result list."
   return
 end
 
  event = Event.new
  event.eventClasses = Array.new
  @events.push(event)

rootNode.children.each do |child|
  if child.name == "EventId"
    event.name = child.content
  elsif child.name == "Event"
    event.name = child.content
  elsif child.name == "ClassResult"
    classResult = EventClass.new
    classResult.results = Array.new
    event.eventClasses.push(classResult)
    child.children.each do |classChild|
      if classChild.name == "ClassId"
        classResult.name = classChild.content
      elsif classChild.name == "ClassShortName"
        classResult.name = classChild.content
      elsif classChild.name == "EventClass"
        classResult.name = classChild.content
      elsif classChild.name == "PersonResult"
        personResult = PersonResult.new
        classResult.results.push(personResult)
        classChild.children.each do |personResultChild|
            if personResultChild.name == "Person"
                personResultChild.children.each do |personChild|
                    if personChild.name == "PersonName"
                        family = personChild.search("Family").first
                        personResult.familyName = family.content if family
                        given = personChild.search("Given").first
                        personResult.givenName = given.content if given
                    elsif personChild.name == "PersonId"
                        personResult.personId = personChild.content
                    end
                end
            elsif personResultChild.name == "PersonId"
                personResult.personId = personResultChild.content
            elsif personResultChild.name == "Club"
                 personResultChild.children.each do |clubChild|
                     if clubChild.name == "ClubId"
                        personResult.clubId = clubChild.content
                     elsif clubChild.name == "Name"
                        personResult.clubName = clubChild.content
                     elsif clubChild.name == "ShortName"
                        personResult.clubShortName = clubChild.content
                     end
                 end
            elsif personResultChild.name == "ClubId"
                personResult.club = personResultChild.content
            elsif personResultChild.name == "Result"
                personResultChild.children.each do |resultChild|
                    if resultChild.name == "Time"
                        personResult.time = Time.parse(resultChild.content) if !resultChild.content.empty?
                    elsif resultChild.name == "ResultPosition"
                        personResult.position = resultChild.content if !resultChild.content.empty?
                    elsif resultChild.name == "CompetitorStatus"
                        personResult.state = resultChild.attribute("value")
                    end
                end    
            end
        end
      end
    end
  end
end
end


def sortByPosition
  @events.each do |event|
    event.eventClasses.each do |eventClass|
      existsAtLeastOnePosition = false
      eventClass.results.each do |personResult|
        if !personResult.position.nil? 
          existsAtLeastOnePosition = true
        end
      end
      if existsAtLeastOnePosition
        eventClass.results.sort do |a,b|
          [a.getPosition, a.familyName, a.givenName] <=> [b.getPosition, b.familyName, b.givenName]
        end
      else
        eventClass.results.sort do |a,b|
          [a.time, a.familyName, a.givenName] <=> [b.time, b.familyName, b.givenName]
        end
      end
    end
  end
end

def calculateNORPoints
  @events.each do |event|
    event.eventClasses.each do |eventClass|
      eventClass.bestTime = nil
      
      if !eventClass.ignoreInNOR
        eventClass.results.each do |personResult|
          next if (personResult.time.nil?)
          next if (personResult.position.nil?)
          if eventClass.bestTime.nil? || eventClass.bestTime > personResult.time
            eventClass.bestTime = personResult.time
          end
        end
      end
      
      eventClass.results.each do |personResult|
        if eventClass.ignoreInNOR
          personResult.rankValue = 0
        elsif personResult.time.nil? || personResult.position.nil?
          personResult.rankValue = 0
        else
          personResult.rankValue = calculatePointsNOR(eventClass.bestTime, personResult.time)
        end
      end
    end
  end
end

def simpleOutput
    @events.each do |event|
        puts "Event: #{event.name}" if event.name
        event.eventClasses.each do |eventClass|
            puts "\n* #{eventClass.name}"
            eventClass.results.each do |personResult|
                rank = personResult.getPosition
                printf "%8s %-30s %-40s %9s %2s\n" % [rank,
                   "#{personResult.givenName} #{personResult.familyName}", personResult.clubShortName,
                   !personResult.time.nil? ? personResult.time.strftime("%H:%M:%S") : "",
                   personResult.rankValue!=0 ? personResult.rankValue.to_s : ""]
            end
        end
    end
end
# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do|opts|
# Set a banner, displayed at the top
# of the help screen.
  opts.banner = "Usage: points.rb [options] file1 file2 ..."

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
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

ARGV.each do|filename|
  # parse results from xml file
  parse(filename)
  sortByPosition
  calculateNORPoints
  simpleOutput
end

# calculate points for every competitor
# calculate points for cup etc.
# export results or cup list

#bestTime="72:07"
#currentTime="80:23"

#points = calculatePointsNOR(Time.parse(bestTime), Time.parse(currentTime))

#puts "BestTime: #{bestTime}, CurrentTime: #{currentTime}, Points: #{points}"

