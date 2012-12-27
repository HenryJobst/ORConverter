require_relative "cupcalculation"

class FogCupStandardHtmlReport
  attr_accessor :fog_cup
  attr_accessor :external_resources
  attr_accessor :show_detail
  attr_accessor :name1
  attr_accessor :name2

  def initialize(fog_cup, external_resources, show_points, name1=nil, name2=nil)
    @external_resources = external_resources
    @fog_cup = fog_cup
    @show_points = show_points
    @name1 = name1
    @name2 = name2
    run
  end

  def run
    run_event(@fog_cup.cup.cup_final_result, false, "Gesamtwertung")
    @fog_cup.cup.cup_event_results.each do |event|
      run_event(event, true)
    end
  end

  def output_cup_event_with_competitors(doc, event_result)

    doc.h2("Details:")

    clubs_results = event_result.club_event_results.values
    clubs_results.sort! do |a, b|
      [-a.points, a.club_name] <=> [-b.points, b.club_name]
    end
    clubs_results.each do |club_result|
      doc.table() {
        doc.tbody() {
          doc.tr() {
            doc.th(:class => "cl", :colspan => "2") { doc.text(club_result.club_name) }
            doc.th(:class => "pt") { doc.text(club_result.points) }
          }

          contributors = club_result.contributors.values.sort do |a, b|
            [-a.points.to_i, a.full_name.to_s] <=> [-b.points.to_i, b.full_name.to_s]
          end

          contributors.each do |contributor|
            doc.tr() {
              doc.td(:class => "pl") { doc.text(contributor.class.to_s) }
              doc.td(:class => "cl") { doc.text(contributor.full_name) }
              doc.td(:class => "pt") { doc.text(contributor.points.to_i) }
            }
          end
        }
      }
    end
  end

  def run_event(event, simple, alternate_name2=nil)

    local_name2 = alternate_name2 ? alternate_name2 : @name2
	local_name2 = "" if local_name2.nil?

    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head() {
          doc.title("#{name1} - #{local_name2}")
          doc.link(:rel => "stylesheet", :type => "text/css", :href => "cup_printout.css")
        }
        doc.body() {
          doc.div(:id => "page_header") {
            doc.table() {
              doc.tr() {
                doc.th(:id => "cup_name") { doc.nobr { doc.text("#{@name1 ? @name1 : event.event_name}") } }
                doc.th(:id => "date_time") {
                  doc.nobr {
                    doc.text("#{I18n.localize(Time.now, :format => :orchead)}")
                  }
                }
              }
              doc.tr() {
                doc.th(:id => "event_name") { doc.nobr {doc.text("#{local_name2 ? local_name2 : "Ergebnisse"}") } }
                doc.th(:id => "creation_text") { doc.nobr { doc.text("erzeugt mit OR-Converter von Henry Jobst") } }
              }
            }
          }

          doc.div(:id => "club_results") {
            doc.h2("Ergebnisse:")
            doc.table() {
              insert_table_header(doc)
              insert_table_results(doc,
                                   sort_club_results(event.club_event_results.values),
                                   simple, @external_resources)
            }
          }

          doc.div(:id => "detailed_results") {
            if @show_points
              output_cup_event_with_competitors(doc, event)
            end
          }
        }
      }
    end

    new_file_name = "#{prepare_filename(@name1 ? @name1 : event.event_name)}_#{prepare_filename(local_name2)}.html"
    File.open(new_file_name, 'w') do |f|
      f.write builder.to_html
    end

  end

  def insert_table_results(doc, club_results, simple, external_resources)
    place = 0
    count = 0
    points = nil
    club_results.each do |club_result|
      if (points.nil? || club_result.points < points)
        count += 1
        place = count
        points = club_result.points
      else
        count += 1
      end

      if place > 3 || simple
        doc.tr() {
          doc.td(:class=>"pl") { doc.text("%2s." % place) }
          doc.td(:class=>"cl") { doc.text("#{club_result.club_name}") }
          doc.td(:class=>"pt") { doc.text("%3s" % club_result.points) }
        }
      else
        doc.tr() {
          img_link = "./resources/#{place}.jpg"
          img_link = "http://www.kolv.de/bilder/#{place}.jpg" if external_resources
          doc.td(:class=>"pl") { doc.img(:src => img_link, :alt=> "Platz %2s." % place) {} }
          doc.td(:class=>"cl") { doc.strong() { doc.text("#{club_result.club_name}") } }
          doc.td(:class=>"pt") { doc.strong() { doc.text("%3s" % club_result.points) } }
        }
      end
    end
  end

  def insert_table_header(doc)
    doc.tr() {
      doc.th(:class=>"pl") {
          doc.text("Platz")
      }
      doc.th(:class=>"cl") {
          doc.text("Verein")
      }
      doc.th(:class=>"pt") {
        doc.text("Punkte")
      }
    }
  end

end