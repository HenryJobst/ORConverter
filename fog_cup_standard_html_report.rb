require_relative "fog_cup"

class FogCupStandardHtmlReport
  attr_accessor :fog_cup
  attr_accessor :external_resources
  attr_accessor :show_detail
  attr_accessor :name1
  attr_accessor :name2

  def initialize(fog_cup, external_resources, show_points, name1=nil, name2=nil)
    #puts name1 + ", " + name2
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
      doc.table(:class => "competitor_table", :width => "300px" ) {
        doc.tbody() {
          doc.tr() {
            doc.th(:width => "30", :align => "right") { doc.text("") }
            doc.th(:width => "160", :align => "left") { doc.text(club_result.club_name) }
            doc.th(:width => "30", :align => "right") { doc.text(club_result.points) }
          }
          doc.tr() {
            doc.td(:width => "30", :align => "right") { doc.text("") }
            doc.td(:width => "160", :align => "left") { doc.text("") }
            doc.td(:width => "30", :align => "right") { doc.text("") }
          }

          contributors = club_result.contributors.values.sort do |a, b|
            [-a.points.to_i, a.full_name.to_s] <=> [-b.points.to_i, b.full_name.to_s]
          end

          contributors.each do |contributor|
            doc.tr() {
              doc.td(:width => "30", :align => "right") { doc.text(contributor.class.to_s) }
              doc.td(:width => "160", :align => "left") { doc.text(contributor.full_name) }
              doc.td(:width => "30", :align => "right") { doc.text(contributor.points.to_i) }
            }
          end

          doc.tr() {
            doc.td(:width => "30", :align => "right") { doc.text("") }
            doc.td(:width => "160", :align => "left") { doc.text("") }
            doc.td(:width => "30", :align => "right") { doc.text("") }
          }
        }
      }
    end
  end

  def run_event(event, simple, alternate_name2=nil)

    local_name2 = alternate_name2 ? alternate_name2 : @name2

    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head() {
          doc.title("#{name1} - #{local_name2}")
          doc.style(:type => "text/css") {
            doc.text("body { color: #000; background-color: #fff; font: 10pt/1.2 Arial, Helvetica, sans-serif; } ")
            doc.text("table { border-collapse: collapse; border-spacing: 2px 2px; font-size: 10pt; margin: 1em;}")
            doc.text(".page_header_table { font-size: 12pt; }")
            doc.text("th { padding: 0px 0px 0px 0px; }")
            doc.text(".competitor_table { padding: 15px 15px 10px 5px; }")
            doc.text("td { padding: 2px 15px 2px 5px; }")
            doc.text(".competitor_table { padding: 15px 15px 10px 5px; }")
            doc.text("#page_header { font-weight: bold; padding: 0; border: none; margin: 0; width: 100%; }")
          }
        }
        doc.body() {
          doc.div(:id => "page_header") {
            doc.table(:class => "page_header_table", :width => "600px", :style => "table-layout:auto;") {
              doc.tr() {
                doc.th(:align => "left") { doc.nobr() { doc.text("#{@name1 ? @name1 : event.name}") } }
                doc.th(:align => "right") { doc.text("#{Time.now.strftime("%d.%m.%Y %H:%M")}") }
              }
              doc.tr() {
                doc.th(:align => "left") { doc.text("#{local_name2 ? local_name2 : "Ergebnisse"}") }
                doc.th(:align => "right") { doc.text("") }
              }
            }
            doc.hr()
          }

          doc.div() {
            doc.table(:style => "margin:auto;") {
              insert_table_header(doc)
              insert_table_results(doc,
                                   sort_club_results(event.club_event_results.values),
                                   simple, @external_resources)
            }
            doc.hr()
          }

          doc.div() {
            if @show_points
              output_cup_event_with_competitors(doc, event)
            end
          }
        }
      }
    end

    new_file_name = "#{prepare_filename(@name1)}_#{prepare_filename(local_name2)}.html"
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
          doc.td(:style => "text-align:right") { doc.text("%2s." % place) }
          doc.td(:style => "padding : 0 10 px;") { doc.text("#{club_result.club_name}") }
          doc.td(:style => "text-align:right") { doc.text("%3s" % club_result.points) }
        }
      else
        doc.tr(:style => "height:48px;font:large arial;") {
          img_link = "./resources/#{place}.jpg"
          img_link = "http://www.kolv.de/bilder/#{place}.jpg" if external_resources
          doc.td() { doc.img(:src => img_link, :alt=> "Platz %2s." % place) {} }
          doc.td(:style => "padding : 0 10 px;") { doc.strong() { doc.text("#{club_result.club_name}") } }
          doc.td(:style => "text-align:right") { doc.strong() { doc.text("%3s" % club_result.points) } }
        }
      end
    end
  end

  def insert_table_header(doc)
    doc.tr(:style => "text-align:left") {
      doc.td(:style => "48px;") {
        doc.font(:size => "+1") {
          doc.text("Platz")
        }
      }
      doc.td(:style => "padding: 0 10px;text-align:center") {
        doc.font(:size => "+1") {
          doc.text("Verein")
        }
      }
      doc.td(:style => "text-align:right") {
        doc.font(:size => "+1") {
          doc.text("Punkte")
        }
      }
    }
  end

end