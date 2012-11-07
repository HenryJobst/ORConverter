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
    run
  end

  def run

    @iof_result_list_reader.events.each do |event|
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head() {
            doc.title("#{name1} - #{name2}")
            doc.style(:type=>"text/css") {
              doc.text("body { color: #000; background-color: #fff; font: 10pt/1.2 Arial, Helvetica, sans-serif; } ")
              doc.text("table { border-collapse: collapse; border-spacing: 2px 2px; font-size: 10pt; margin: 1em;}")
              doc.text(".page_header_table { font-size: 12pt; }")
              doc.text("th { padding: 0px 0px 0px 0px; }")
              doc.text(".eventclassresult { padding: 1px 15px 1px 5px; }")
              doc.text(".eventclass { padding: 15px 15px 10px 5px; }")
              doc.text("td { padding: 2px 15px 2px 5px; }")
              doc.text(".intpos_1 { font-size: 110%; padding-bottom: 15px; }")
              doc.text(".intpos_2 { font-size: 110%; padding-bottom: 15px; }")
              doc.text(".intpos_3 { font-size: 110%; padding-bottom: 25px; }")
              doc.text(".realpos_false { font-size: 90%; }")
              doc.text("#page_header { font-weight: bold; padding: 0; border: none; margin: 0; width: 100%; }")
            }
          }
          doc.body() {
            doc.div(:id => "page_header") {
              doc.table(:class => "page_header_table", :width => "600px", :style => "table-layout:auto;") {
                doc.tr() {
                  doc.th(:align => "left") { doc.nobr() { doc.text("#{name1 ? name1 : event.name}") } }
                  doc.th(:align => "right") { doc.text("#{Time.now.strftime("%d.%m.%Y %H:%M")}") }
                }
                doc.tr() {
                  doc.th(:align => "left") { doc.text("#{name2 ? name2 : "Ergebnisse"}") }
                  doc.th(:align => "right") { doc.text("") }
                }
              }
              doc.hr()
            }

            event.event_classes.each do |event_class|
              doc.table(:class=>"eventclass", :width => "600px", :cellspacing=>"2") {
                doc.tbody() {
                  doc.tr(:class => "eventclass") {
                    doc.th(event_class.name, :width => "20", :align => "left")
                    doc.th("(%s)" % event_class.results.size, :width => "80", :align => "left")
                    doc.th("%s km" % event_class.length, :width => "100", :align => "left")
                    doc.th("%s P" % event_class.control_count, :width => "100", :align => "left")
                    doc.th()
                  }
                }
              }
              doc.table(:class=>"eventclassresult", :width => "600px", :cellspacing=>"2") {
                last_position_valid = false
                event_class.results.each do |person_result|
                  #next if person_result.did_not_start
                  pos = person_result.real_or_ak_position.to_s
                  local_position_valid = false
                  local_position_valid = true if person_result.real_position

                  if last_position_valid && !local_position_valid
                    last_position_valid = false
                    # empty row
                    doc.tr() { doc.td() { } }
                    doc.tr() { doc.td() { } }

                  end

                  last_position_valid = true if local_position_valid
                  doc.tr(:class=>"eventclassresult realpos_#{person_result.real_position} intpos_#{person_result.integer_position}") {
                    doc.td(:width => "10", :align => "right") { }
                    pos += "." if local_position_valid
                    doc.td("%s" % pos, :width => "60", :align => "right")
                    doc.td("", :width => "5", :align => "right")
                    doc.td(person_result.full_name, :width => "180", :align => "left", :nowrap => "")
                    doc.td(person_result.birth_year, :width => "12", :align => "right")
                    doc.td("", :width => "5", :align => "right")
                    doc.td(person_result.club_short_name, :width => "220", :align => "left", :nowrap => "")
                    if person_result.real_or_ak_position
                      doc.td(!person_result.time.nil? ? person_result.time.strftime("%k:%M:%S") : "", :width => "30", :align => "left")
                    else
                      doc.td(person_result.get_position, :width => "30", :align => "left")
                    end

                    doc.td((@show_points && person_result.rank_value != 0) ? person_result.rank_value.to_s : "",
                           :width => "30", :align => "right")
                    doc.td()
                  }
                end
              }
              doc.br()
            end
          }
        }
      end

      File.open("ergebnisliste_#{filename_from_name(event.name)}.html", 'w') do |f|
        f.write builder.to_html
      end

    end
  end
end
