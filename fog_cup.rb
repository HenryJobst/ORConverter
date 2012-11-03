require_relative "iof_result_list_classes"

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

class FogCup

  def initialize(cup_name, actual_year, events)
    @events = events
    @cup = Cup.new
    @cup_name = cup_name
    @actual_year = actual_year
    calculate_fog_cup
  end

  def calculate_fog_cup

    @cup.cup_event_results = Array.new

    @events.each do |event|

      # create & initialize cup event result
      cup_event_result = CupEventResult.new
      cup_event_result.club_event_results = Hash.new
      cup_event_result.event_name = event.name

      event.event_classes.each do |event_class|
        event_class.results.each do |person_result|
          next if person_result.rank_value == 0
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
    cup_final_result.event_name = @cup_name
    @cup.cup_final_result = cup_final_result

    # Merge event results
    @cup.cup_event_results.each do |event_result|

      event_result.club_event_results.values.each do |club_result|

        club_final_result = cup_final_result.club_event_results[club_result.club_name.to_sym]

        if club_final_result.nil?
          # create & store
          club_final_result = ClubEventResult.new
          club_final_result.contributors = Hash.new
          club_final_result.club_name = club_result.club_name
          club_final_result.points = club_result.points
          cup_final_result.club_event_results.store(club_final_result.club_name.to_sym, club_final_result)
        else
          club_final_result.points += club_result.points
        end

        club_result.contributors.values.each do |contributor|
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
    clubs_results.each do |club_result|
      puts "\n#{club_result.club_name} -> #{club_result.points}"
      puts "\n"
      contributors = club_result.contributors.values.sort do |a, b|
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

  def erwins_original_html_output
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head() {
          doc.title("Ergebnis #{@cup_name}")
          doc.style(".tabelle td {height:30px;}", :type => "text/css")
        }
        doc.body() {
          doc.table(:border => "1", :style => 'width:950px;text-align:center;') {
            doc.tr {
              doc.td(:style => "vertical-align:top; text-align:center; vertical-align:middle; width:50%;font:x-large arial;") {
                doc.img(:src => "http://kolv.de/bilder/nebelcup_logo.jpg", :alt => "Nebel-Cup", :title => "Nebel-Cup")
                doc.br()
                doc.text(@actual_year)
                doc.br()
              }
              doc.td(:style => "vertical-align:top; width:50%;") {
                doc.pre() {
                  doc.h3("Gesamtwertung #{@cup_name}") {}
                  doc.table(:style => "margin:auto;") {
                    insert_table_header(doc)
                    insert_table_results(doc,
                                         sort_club_results(@cup.cup_final_result.club_event_results.values),
                                         false)
                  }
                }
              }
            }

            doc.tr() {
              doc.td(:style => "vertical-align:top") {
                doc.pre() {
                  doc.h3("Nachtlauf") {}
                  doc.table(:style => "margin:auto;") {
                    insert_table_header(doc)
                    insert_table_results(doc,
                                         sort_club_results(@cup.cup_event_results.fetch(0).club_event_results.values),
                                         true) if !@cup.cup_event_results.empty?
                  }
                }
              }

              doc.td(:style => "vertical-align:top") {
                doc.pre() {
                  doc.h3("Taglauf") {}
                  doc.table(:style => "margin:auto;") {
                    insert_table_header(doc)
                    insert_table_results(doc,
                                         sort_club_results(@cup.cup_event_results.fetch(1).club_event_results.values),
                                         true) if @cup.cup_event_results.size > 1
                  }
                }
              }

            }
          }
        }
      }
    end

    File.open("ergebnis_#{@cup_name.gsub("\s", "_")}.html",'w'){|f| f.write builder.to_html}

  end

  def sort_club_results(club_results)
    sorted_club_results = club_results
    sorted_club_results.sort! do |a, b|
      [-a.points, a.club_name] <=> [-b.points, b.club_name]
    end
    sorted_club_results
  end

  def insert_table_results(doc, club_results, simple)
    place = 0
    points = nil
    club_results.each do |club_result|
      if (points.nil? || club_result.points < points)
        place += 1
        points = club_result.points
      end

      if place > 3 || simple
        doc.tr() {
          doc.td(:style => "text-align:right") { doc.text("#{place}. ") }
          doc.td(:style => "padding : 0 10 px;") { doc.text("#{club_result.club_name}") }
          doc.td() { doc.text("#{club_result.points}") }
        }
      else
        doc.tr(:style => "height:48px;font:large arial;") {
          doc.td() { doc.img(:src => "./resources/#{place}.jpg", :alt=> "Platz #{place}. ") {} }
          doc.td(:style => "padding : 0 10 px;") { doc.strong() { doc.text("#{club_result.club_name}") } }
          doc.td() { doc.strong() { doc.text("#{club_result.points}") } }
        }
      end

    end
  end

  def insert_table_header(doc)
    doc.tr() {
      doc.td(:style => "48px;") {
        doc.text("Platz")
      }
      doc.td(:style => "padding: 0 10px;") {
        doc.text("Verein")
      }
      doc.td("Punkte") {}
    }
  end

end