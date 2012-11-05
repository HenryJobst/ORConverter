require_relative "fog_cup"

class FogCupOriginalHtmlReport

  attr_accessor :fog_cup
  attr_accessor :external_resources

  def initialize(fog_cup, external_resources)
    @external_resources = external_resources
    @fog_cup = fog_cup
    run
  end

  def run
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head() {
          doc.title("Ergebnis #{@fog_cup.cup.cup_name}")
          doc.style(".tabelle td {height:30px;}", :type => "text/css")
        }
        doc.body() {
          doc.table(:border => "1", :style => 'width:950px;text-align:center;') {
            doc.tr {
              doc.td(:style => "vertical-align:top; text-align:center; vertical-align:middle; width:50%;font:x-large arial;") {
                img_link = "./resources/nebelcup_logo.jpg"
                img_link = "http://www.kolv.de/bilder/nebelcup_logo.jpg" if @external_resources
                doc.img(:src => img_link, :alt => "#{@fog_cup.cup.cup_name}", :title => "#{@fog_cup.cup.cup_name}")
                doc.br()
                doc.text(@fog_cup.actual_year)
                doc.br()
              }
              doc.td(:style => "vertical-align:top; width:50%;") {
                doc.pre() {
                  doc.h1("Gesamtwertung #{fog_cup.cup.cup_name}") {}
                  doc.table(:style => "margin:auto;") {
                    insert_table_header(doc)
                    insert_table_results(doc,
                                         sort_club_results(@fog_cup.cup.cup_final_result.club_event_results.values),
                                         false, @external_resources)
                  }
                }
              }
            }

            doc.tr() {
              doc.td(:style => "vertical-align:top") {
                doc.pre() {
                  doc.h2("Nachtlauf") {}
                  doc.table(:style => "margin:auto;") {
                    insert_table_header(doc)
                    insert_table_results(doc,
                                         sort_club_results(fog_cup.cup.cup_event_results.fetch(0).club_event_results.values),
                                         true, @external_resources) if !@fog_cup.cup.cup_event_results.empty?
                  }
                }
              }

              doc.td(:style => "vertical-align:top") {
                doc.pre() {
                  doc.h2("Taglauf") {}
                  doc.table(:style => "margin:auto;") {
                    insert_table_header(doc)
                    insert_table_results(doc,
                                         sort_club_results(@fog_cup.cup.cup_event_results.fetch(1).club_event_results.values),
                                         true, @external_resources) if @fog_cup.cup.cup_event_results.size > 1
                  }
                }
              }

            }
          }
        }
      }
    end

    File.open("ergebnis_#{File.basename(@fog_cup.cup.cup_name.gsub("\s", "_").tr("/\000", ""))}.html",'w') do |f|
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