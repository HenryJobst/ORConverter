require_relative "fog_cup"

class FogCupStandardHtmlReport
  attr_accessor :fog_cup
  attr_accessor :external_resources

  def initialize(fog_cup, external_resources)
    @external_resources = external_resources
    @fog_cup = fog_cup
    run
  end

  def run
=begin
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head() {
          doc.title("Ergebnis #{event_result.event_name}")
          #doc.style(".tabelle td {height:30px;}", :type => "text/css")
        }
        doc.body() {
          doc.h1("Ergebnis #{event_result.event_name}")
          doc.table(:style => "margin:auto;") {
            insert_table_header(doc)
            insert_table_results(doc,
                                 sort_club_results(cup.cup_event_results.fetch(0).club_event_results.values),
                                 true, external_resources) if !cup.cup_event_results.empty?
          }
        }
      }
    end

    File.open("ergebnis_#{File.basename(event_result.event_name.gsub("\s", "_").tr("/\000", ""))}.html",'w') do |f|
      f.write builder.to_html
    end
=end
  end
end