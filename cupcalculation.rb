require_relative "iof_result_list_classes"

class CupContributor
  attr_accessor :given_name
  attr_accessor :family_name
  attr_accessor :class
  attr_accessor :points

  def full_name
    "#{@given_name} #{@family_name}"
  end
  
  def full_name_with_class
    "# #{@class} {@given_name} #{@family_name}"
  end
  
  def to_s
    "#{@class} - #{@given_name} #{@family_name} : #{@points}"
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
  attr_accessor :classes

  def initialize(name)
    @club_event_results = Hash.new
    @classes = Hash.new
    @event_name = name
  end
end

class Cup
  attr_accessor :cup_name
  attr_accessor :cup_event_results
  attr_accessor :cup_final_result

  def initialize(name)
    @cup_name = name
  end
end

def sort_club_results(club_results)
  sorted_club_results = club_results
  sorted_club_results.sort! do |a, b|
    [-a.points, a.club_name] <=> [-b.points, b.club_name]
  end
  sorted_club_results
end

class CupCalculation

  attr_accessor :cup
  attr_accessor :actual_year
  attr_accessor :events
  attr_accessor :rank_mode

  def initialize(cup_name, actual_year, events, verbose, rank_mode)
    @cup = Cup.new(cup_name)
    @actual_year = actual_year
    @events = events
    @rank_mode = rank_mode

    calculate_cup

    simple_output_cup if verbose
  end

  def calculate_cup

    @cup.cup_event_results = Array.new

    @events.each do |event|

      # create & initialize cup event result
      cup_event_result = CupEventResult.new(event.name)

      event.event_classes.each do |event_class|
        class_name = event_class.name
        act_class = cup_event_result.classes[class_name.to_sym]
        if act_class.nil?
          if !event_class.ignore_in_rank_mode(@rank_mode)
            # create & store
            cup_event_result.classes.store(class_name.to_sym, nil)
            act_class = cup_event_result.classes[class_name.to_sym]
          end
        end
        event_class.results.each do |person_result|
          next if person_result.rank_value == 0
          club_name = person_result.get_club_name
          next if club_name.match("Volkssport")
          next if club_name.match("ohne Verein")
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
    cup_final_result = CupEventResult.new(cup.cup_name)
    cup.cup_final_result = cup_final_result

    # Merge event results
    cup.cup_event_results.each do |event_result|

      event_result.classes.keys.each do |act_class|
        cup_final_result.classes[act_class] = nil
      end

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
          final_contributor = club_final_result.contributors[contributor.full_name_with_class.to_sym]
          if final_contributor.nil?
            # add contributor
            final_contributor = CupContributor.new
            final_contributor.given_name = contributor.given_name
            final_contributor.family_name = contributor.family_name
            final_contributor.class = contributor.class
            final_contributor.points = contributor.points
            club_final_result.contributors.store(contributor.full_name_with_class.to_sym, final_contributor)
          else
            final_contributor.points += contributor.points
          end
        end
      end
    end
  end

  def simple_output_cup_event(event_result)
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
        [-a.points.to_i, a.full_name.to_s, a.class.to_s] <=> [-b.points.to_i, b.full_name.to_s, b.class.to_s]
      end
      contributors.each do |contributor|
          printf " %8s %s %d\n" % [contributor.class.to_s,
                                   contributor.full_name,
                                   contributor.points.to_i]
      end
    end
  end

  def simple_output_cup
    cup.cup_event_results.each do |event_result|
      simple_output_cup_event(event_result)
    end
    simple_output_cup_event(cup.cup_final_result)
  end
end