require_relative "iof_result_list_classes"

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

class IofResultListReader

  def initialize(filenames)
    @events = Array.new

    filenames.each do |filename|
      parse_xml_file(filename)
    end

    sort_by_position
    calculate_nor_points

  end

  def events
    @events
  end

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
        event.name = child.content
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
                    if !resultChild.content.empty?
                      person_result.time = Time.parse(prepare_time(resultChild.content))
                    end
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

  def prepare_time(time_string)
    (time_string = "00:" + time_string) if time_string =~ /^\d+:\d+($|\.\d+$)/
    time_string
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

end