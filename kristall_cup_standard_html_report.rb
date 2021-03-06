require_relative "cupcalculation"

class KristallCupOriginalHtmlReport
  attr_accessor :cup
  attr_accessor :external_resources
  attr_accessor :show_detail
  attr_accessor :name1
  attr_accessor :name2
  attr_accessor :inline_css

  def initialize(cup, external_resources, name1=nil, name2=nil, inline_css=nil)
    @external_resources = external_resources
    @cup = cup
    @name1 = name1
    @name2 = name2
    @inline_css = inline_css
    @name2 = "Vereinswertung" if @name2.nil?
    run
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

  def build_filename(name1, name2)
    str = "#{prepare_filename(name1)}"
    str += "_#{prepare_filename(name2)}" if (!name2.nil? && !name2.empty?)
    str += ".html"
  end

  def run()

		style_text = ""
    if @inline_css 
		  File.open("kcup_printout.css").each_line do |line|
        style_text += line
      end
    end
    local_name2 = @name2	
	  local_name2 = local_name2 ? local_name2 : "Ergebnisse"

    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head() {
          doc.title("#{@cup.cup.cup_name} - #{local_name2}")
          if @inline_css
            doc.style(:type => "text/css") { 
              doc.text("#{style_text}") 
            }
          else  
            doc.link(:rel => "stylesheet", :type => "text/css", :href => "kcup_printout.css")
          end
        }
        doc.body() {
          doc.div(:id => "page_header") {
            doc.table() {
              doc.tr() {
                doc.th(:id => "cup_name") { doc.nobr { doc.text("#{@cup.cup.cup_name}") } }
                doc.th(:id => "date_time") {
                  doc.nobr {
                    doc.text("#{I18n.localize(Time.now, :format => :orchead)}")
                  }
                }
              }
              doc.tr() {
                doc.th(:id => "event_name") { doc.nobr {doc.text("#{local_name2}") } }
                doc.th(:id => "creation_text") { doc.nobr { doc.text("erzeugt mit OR-Converter von Henry Jobst") } }
              }
            }
          }

          doc.div(:id => "club_results") {
            #doc.h2("")
            doc.table() {
              insert_table_header(doc)
              insert_table_results(doc)
            }
          }
        }
      }
    end

    new_file_name = build_filename(@cup.cup.cup_name, local_name2)
    File.open(new_file_name, 'w') do |f|
      f.write builder.to_html
    end

  end

  def sort_classes(classes)
    sorted_classes = classes
    sorted_classes.sort! do |a, b|
      a <=> b
    end
    sorted_classes
  end

  def insert_table_header(doc)
    doc.tr() {
      doc.th(:class=>"top") {
          doc.text("Verein/Klassen")
      }
      doc.th(:class=>"sum") {
          doc.text("Gesamt")
      }

      sort_classes(@cup.cup.cup_final_result.classes.keys).each do |act_class|
        doc.th(:class=>"cl") {
          doc.text(act_class)
        }
      end

      @cup.cup.cup_event_results.each do |event|
        doc.th(:class=>"ev") {
          doc.text(event.event_name)
        }
      end
    }
  end

  def insert_table_results(doc)
    club_results = sort_club_results(@cup.cup.cup_final_result.club_event_results.values)
    club_results.each do |club_result|
      doc.tr() {
        doc.td(:class=>"cb") { doc.text("#{club_result.club_name}") }
        doc.td(:class=>"sum") { doc.text("#{club_result.points}") }

        sort_classes(@cup.cup.cup_final_result.classes.keys).each do |act_class|
          points = 0
          club_result.contributors.values.each do |contributor|
            if contributor.class == act_class.to_s
              points += contributor.points
            end
          end
          if points > 0
			doc.td(:class => "cl") {
              doc.text(points)
            }
		  else
            doc.td(:class => "cl") {
              doc.text("")
            }
          end
        end

        @cup.cup.cup_event_results.each do |event|
          found = false
          event.club_event_results.values.each do |club|
            if club.club_name == club_result.club_name
              doc.td(:class => "ev") {
                doc.text(club.points)
              }
              found = true
              break
            end
          end
          if !found
            doc.td(:class => "ev") {
              doc.text("")
            }
          end
        end

      }
    end
  end
end
