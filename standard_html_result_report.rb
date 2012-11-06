class StandardHtmlResultReport

  attr_accessor :iof_result_list_reader
  attr_accessor :dont_show_points

  def initialize(iof_result_list_reader, dont_show_points)
    @iof_result_list_reader = iof_result_list_reader
    @dont_show_points = dont_show_points
    run
  end

  def run

    @iof_result_list_reader.events.each do |event|
      builder = Nokogiri::HTML::Builder.new do |doc|
        doc.html {
          doc.head() {
            doc.title("Ergebnis #{event.name}")
          }
          doc.body() {
            doc.h1("Ergebnis #{event.name}")

            event.event_classes.each do |event_class|
              doc.table(:borders => "1", :width => "500px", :cellspacing=>"3", :cellpadding=>"3") {
                doc.tr() {
                  doc.td(event_class.name, :width => "20", :align => "left")
                  doc.td("(%s)" % event_class.results.size, :width => "80", :align => "left")
                  doc.td("%s km" % event_class.length, :width => "100", :align => "left")
                  doc.td("%s P" % event_class.control_count, :width => "100", :align => "left")
                  doc.td()
                }
              }
              doc.table(:borders => "1") {
                last_position_valid = false
                event_class.results.each do |person_result|
                  pos = person_result.real_or_ak_position.to_s
                  local_position_valid = false
                  local_position_valid = true if person_result.real_position

                  if last_position_valid && !local_position_valid
                    last_position_valid = false
                    # empty row
                    doc.tr() { doc.td() { } }
                  end

                  last_position_valid = true if local_position_valid

                  doc.tr() {
                    doc.td("", :width => "10", :align => "right")
                    pos += "." if local_position_valid
                    doc.td("%s" % pos, :width => "60", :align => "right")
                    doc.td("", :width => "5", :align => "right")
                    doc.td(person_result.full_name, :width => "180px", :align => "left", :nowrap => "")
                    doc.td(person_result.birth_year, :width => "12px", :align => "right")
                    doc.td("", :width => "5", :align => "right")
                    doc.td(person_result.club_short_name, :width => "180px", :align => "left", :nowrap => "")
                    if person_result.real_or_ak_position
                      doc.td(!person_result.time.nil? ? person_result.time.strftime("%H:%M:%S") : "", :width => "30px", :align => "left")
                    else
                      doc.td(person_result.get_position, :width => "30px", :align => "left")
                    end

                    doc.td((!@dont_show_points && person_result.rank_value != 0) ? person_result.rank_value.to_s : "",
                           :width => "10px", :align => "right")
                    doc.td()
                  }
                end
                doc.tr() { doc.td() { } }
                doc.tr() { doc.td() { } }
                doc.tr() { doc.td() { } }
              }
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
