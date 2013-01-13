require "i18n"

class StandardHtmlResultReport

  attr_accessor :iof_result_list_reader
  attr_accessor :show_points
  attr_accessor :name1
  attr_accessor :name2

  def initialize(iof_result_list_reader, show_points, name1=nil, name2=nil)
    @iof_result_list_reader = iof_result_list_reader
    @show_points = show_points
    @name1 = name1
    @name2 = name2
    @name2 = "Ergebnisse" if @name2.nil?
    run
  end

  def run

    @iof_result_list_reader.events.each do |event|
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head() {
            doc.title("#{@name1 ? @name1 : event.name} - #{name2 ? name2 : "Ergebnisse"}")
            doc.link(:rel => "stylesheet", :type => "text/css", :href => "printout.css")
          }
          doc.body() {
            doc.div(:id => "page_header") {
              doc.table() {
                doc.tr() {
                  doc.th(:id => "cup_name") { doc.nobr { doc.text("#{@name1 ? @name1 : event.name}") } }
                  doc.th(:id => "date_time") { doc.nobr {
                    doc.text("#{I18n.localize(Time.now, :format => :orchead)}") } }
                }
                doc.tr() {
                  doc.th(:id => "event_name") { doc.nobr {doc.text("#{name2 ? name2 : "Ergebnisse"}") } }
                  doc.th(:id => "creation_text") { doc.nobr { doc.text("erzeugt mit OR-Converter von Henry Jobst") } }
                }
              }
            }

            doc.div(:id => "results") {
              event.event_classes.each do |event_class|
                doc.table(:id=>"classes") {
                  doc.tbody() {

                    doc.tr() {
                      doc.th(:class => "cn") { doc.text(event_class.name) }
                      doc.th(:class => "cs") { doc.text("(%s)" % event_class.results.size) }
                      doc.th(:class => "cl") { doc.text("%s km" % event_class.length) }
                      doc.th(:class => "cc") {
                        if event_class.control_count
                          doc.text("%s P" % event_class.control_count)
                        else
                          doc.text("")
                        end
                      }
                      doc.th(:class => "cb") { doc.text("") }
                    }
                  }
                }
                doc.table(:id => "class_result") {
                  doc.tbody() {

                    last_position_valid = false
                    event_class.results.each do |person_result|
                      #next if person_result.did_not_start
                      pos = person_result.real_or_ak_position.to_s
                      local_position_valid = false
                      local_position_valid = true if person_result.real_position
                      first_invalid = false
                      if last_position_valid && !local_position_valid
                        last_position_valid = false
                        first_invalid = true
                      end

                      last_position_valid = true if local_position_valid
                      doc.tr(:class => "first_invalid_#{first_invalid} realpos_#{person_result.real_position} intpos_#{person_result.integer_position}") {
                        pos += "." if local_position_valid
                        doc.td(:class=>"ps", :nowrap=>""){ doc.text("%s" % pos) }
                        doc.td(:class=>"nm", :nowrap=>""){ doc.text(person_result.full_name) }
                        doc.td(:class=>"by", :nowrap=>""){ doc.text(person_result.birth_year) }
                        doc.td(:class=>"cn", :nowrap=>""){ doc.text(person_result.club_short_name) }
                        if person_result.real_or_ak_position
                          doc.td(:class=>"tm1", :nowrap=>""){
                            doc.text(!person_result.time.nil? ? person_result.time.strftime("%k:%M:%S") : "") }
                        else
                          doc.td(:class=>"tm2", :nowrap=>""){
                            doc.text(person_result.get_position) }
                        end

                        points = (@show_points && person_result.rank_value != 0) ? person_result.rank_value.to_s.strip : ""
                        doc.td(:class => "pts", :nowrap=>"") { doc.text(points.to_s) }
                        doc.td(:class => "bl") { doc.text("") }
                      }
                    end

                  }
                }
              end
            }
          }
        }
      end

      File.open("ergebnisliste_#{filename_from_name(event.name)}.html", 'w') do |f|
        f.write builder.to_html
      end

    end
  end
end
