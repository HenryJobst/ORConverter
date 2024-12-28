require_relative "iof_result_list_classes"

require 'tzinfo'
require 'tzinfo/data'

TZInfo::DataSource.set(:ruby)

# @param [Time] base_time
# @param [Float] factor
# @return [Time]
def multiply_time(base_time, factor)
  sec, min, hour, day, month, year, wday, yday, isdst, zone = base_time.to_a
  f_sec = sec + min * 60 + hour * 3600
  f_sec = (f_sec * factor).to_i
  f_hour = (f_sec / 3600).to_i
  f_sec = (f_sec - f_hour * 3600).to_i
  f_min = (f_sec / 60).to_i
  f_sec = (f_sec - f_min * 60).to_i
  if zone == TZInfo::Timezone.get('UTC')
    Time.utc(f_sec, f_min, f_hour, day, month, year, wday, yday, isdst, zone)
  else
    Time.local(f_sec, f_min, f_hour, day, month, year, wday, yday, isdst, zone)
  end
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

  attr_accessor :events

  def initialize(filenames, verbose)
    @events = Array.new

    filenames.each do |filename|
      parts = filename.split(/#/)
      file_title = parts.size > 1 ? parts[1] : nil
      parse_xml_file(parts[0], file_title)
    end

    sort_by_position

  end

  def parse_xml_file_v3(doc, file_title)
    root_node = doc.root

    event = Event.new
    event.event_classes = Array.new
    event.name = file_title.nil? ? nil : file_title
    @events.push(event)

    root_node.children.each do |child|
      if child.name == "EventId"
        event.name = child.content
      elsif child.name == "Event"
        event.name = child.at("Name").content
      elsif child.name == "ClassResult"
        class_result = EventClass.new
        class_result.results = Array.new
        event.event_classes.push(class_result)
        child.children.each do |class_child|
          if class_child.name == "Class"
            class_result.name = class_child.at("ShortName").content
          elsif class_child.name == "Course"
            class_child.children.each do |class_class_child|
              if class_class_child.name == "Length"
                class_result.length = (class_class_child.content.to_f / 1000).round(1).to_s
              elsif class_class_child.name == "NumberOfControls"
                class_result.control_count = class_class_child.content
              end
            end
          elsif class_child.name == "PersonResult"
            person_result = PersonResult.new
            class_result.results.push(person_result)
            class_child.children.each do |person_result_child|
              if person_result_child.name == "Person"
                person_result_child.children.each do |personChild|
                  if personChild.name == "Name"
                    family = personChild.search("Family").first
                    person_result.family_name = family.content if family
                    given = personChild.search("Given").first
                    person_result.given_name = given.content if given
                  elsif personChild.name == "PersonId"
                    person_result.person_id = personChild.content
                  elsif personChild.name == "BirthDate"
                    if personChild.first_element_child
                      if personChild.first_element_child.name == "Date"
                        year = personChild.first_element_child.content
                        (year = year[-2..-1]) if year.length > 2
                        person_result.birth_year = year
                      end
                    else
                      year = personChild.content
                      (year = year[-2..-1]) if year.length > 2
                      person_result.birth_year = year
                    end
                  end
                end
              elsif person_result_child.name == "PersonId"
                person_result.person_id = person_result_child.content
              elsif person_result_child.name == "Organisation"
                person_result_child.children.each do |clubChild|
                  if clubChild.name == "Id"
                    person_result.club_id = clubChild.content
                  elsif clubChild.name == "Name"
                    person_result.club_name = clubChild.content
                  elsif clubChild.name == "ShortName"
                    person_result.club_short_name = clubChild.content
                  end
                end
              elsif person_result_child.name == "Result"
                person_result_child.children.each do |resultChild|
                  if resultChild.name == "Time"
                    unless resultChild.content.empty?
                      time = if resultChild.content =~ /^\d+$/
                               Time.at(resultChild.content.to_i, in: TZInfo::Timezone.get('UTC'))
                             else
                               Time.parse(prepare_time(resultChild.content))
                             end
                      person_result.time = time
                    end
                  elsif resultChild.name == "Position"
                    person_result.position = resultChild.content unless resultChild.content.empty?
                  elsif resultChild.name == "Status"
                    person_result.state = resultChild.attribute("value")
                  elsif !class_result.length && resultChild.name == "CourseLength"
                    unless resultChild.content.empty?
                      class_result.length = resultChild.content
                      if class_result.length =~ /^\d+$/
                        class_result.length = (class_result.length.to_i / 1000.0).round(1).to_s
                      end
                    end
                  elsif resultChild.name == "SplitTime"
                    split = resultChild.attribute("sequence").to_s.to_i
                    class_result.control_count = split if class_result.control_count.nil? || split > class_result.control_count
                  elsif resultChild.name == "Course"
                    unless class_result.length
                      resultChild.children.each do |class_class_child|
                        if class_class_child.name == "Length"
                          class_result.length = (class_class_child.content.to_f / 1000).round(1).to_s
                        elsif class_class_child.name == "NumberOfControls"
                          class_result.control_count = class_class_child.content
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    event.name = name_from_filename(filename) if event.name.nil?

  end

  def parse_xml_file_v2(doc, file_title)
    root_node = doc.root

    if root_node.name != "ResultList"
      puts "The file #{filename} is not a valid result list."
      return
    end

    event = Event.new
    event.event_classes = Array.new
    event.name = file_title.nil? ? nil : file_title
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
                  elsif personChild.name == "BirthDate"
                    if personChild.first_element_child
                      if personChild.first_element_child.name == "Date"
                        year = personChild.first_element_child.content
                        (year = year[-2..-1]) if year.length > 2
                        person_result.birth_year = year
                      else
                        year = personChild.content
                        (year = year[-2..-1]) if year.length > 2
                        person_result.birth_year = year
                      end
                    end
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
                    unless resultChild.content.empty?
                      person_result.time = resultChild.content =~ /^\d+$/ ? Time.at(resultChild.content.to_i) : Time.parse(prepare_time(resultChild.content))
                    end
                  elsif resultChild.name == "ResultPosition"
                    person_result.position = resultChild.content if !resultChild.content.empty?
                  elsif resultChild.name == "CompetitorStatus"
                    person_result.state = resultChild.attribute("value")
                  elsif !class_result.length && resultChild.name == "CourseLength"
                    unless resultChild.content.empty?
                      class_result.length = resultChild.content
                      if class_result.length =~ /^\d+$/
                        class_result.length = (class_result.length.to_i / 1000.0).round(1).to_s
                      end
                    end
                  elsif resultChild.name == "SplitTime"
                    split = resultChild.attribute("sequence").to_s.to_i
                    class_result.control_count = split if class_result.control_count.nil? || split > class_result.control_count
                  end
                end
              end
            end
          end
        end
      end
    end

    event.name = name_from_filename(filename) if event.name.nil?
  end

  def parse_xml_file(filename, file_title)
    puts "\nProcess file: #{filename} - #{file_title}"

    doc = Nokogiri::XML(IO.read(filename))

    return if doc.nil?

    root_node = doc.root

    if root_node.name != "ResultList"
      puts "The file #{filename} is not a valid result list."
      return
    end

    iof_version = root_node.attribute("iofVersion")
    if iof_version
      puts "The file has IOFdata version: #{iof_version}."
      if iof_version.to_s == '3.0'
        parse_xml_file_v3(doc, file_title)
      else
        parse_xml_file_v2(doc, file_title)
      end
    end
  end

  def prepare_time(time_string)
    (time_string = "00:" + time_string) if time_string =~ /^\d+:\d+($|\.\d+$)/
    time_string
  end

  def sort_by_position
    @events.each do |event|
      event.event_classes.each do |event_class|
        event_class.results.sort! do |a, b|
          [a.integer_position.to_i, a.time.to_s, a.family_name, a.given_name] <=> [b.integer_position.to_i, b.time.to_s, b.family_name, b.given_name]
        end
      end
    end
  end

  def simple_output(show_nor_points)
    @events.each do |event|
      puts "\n---------------------------------------"
      puts "Event: #{event.name}" if event.name
      event.event_classes.each do |event_class|
        printf "\n%s  (%s)       %s km     %s P\n" %
                   [event_class.name, event_class.results.size, event_class.length, event_class.control_count]
        event_class.results.each do |person_result|
          rank = person_result.get_position
          printf "%8s %-40s %2s %-40s %9s %2s\n" % [rank,
                                                person_result.full_name,
                                                person_result.birth_year,
                                                person_result.club_short_name,
                                                !person_result.time.nil? ? person_result.time.strftime("%H:%M:%S") : "",
                                                person_result.rank_value!=0 ?
                                                                            (show_nor_points ? person_result.rank_value.to_s : "")
                                                : ""]
        end
      end
    end
  end

end