class PointsCalculator
  attr_accessor :events
  attr_accessor :rank_mode

  def initialize(events, rank_mode, verbose)
    @events = events
    @rank_mode = rank_mode

    puts "Rank-Mode: #{rank_mode}" if verbose

    run
  end

  def run
    calculate_nor_points if @rank_mode == :nor
    calculate_nebel_points if @rank_mode == :nebel
    calculate_kristall_points if @rank_mode == :kristall
  end

  def calculate_nor_points
    @events.each do |event|
      event.event_classes.each do |event_class|
        event_class.best_time = nil

        unless event_class.ignore_in_nor
          event_class.results.each do |person_result|
            next if (person_result.time.nil?)
            next if (person_result.position.nil?)
            if event_class.best_time.nil? || event_class.best_time > person_result.time
              event_class.best_time = person_result.time
            end
          end
        end

        event_class.results.each do |person_result|
          if event_class.ignore_in_nor
            person_result.rank_value = 0
          elsif person_result.time.nil? || person_result.position.nil?
            person_result.rank_value = 0
          else
            person_result.rank_value = calculate_points_nor(event_class.best_time, person_result.time)
          end
        end
      end
    end
  end

  def ignore_club_in_kristall(name)
    return true if name.nil?
    return true if name.empty?
    return true if name =~ /ohne/
    return true if name =~ /Volkssport/
    false
  end

  def calculate_kristall_points
    @events.each do |event|
      event.event_classes.each do |event_class|
        clubs = {}
        points = 10
		last_result = nil
        event_class.results.each do |person_result|
          if event_class.ignore_in_kristall
            person_result.rank_value = 0
          elsif person_result.time.nil? || person_result.position.nil?
            person_result.rank_value = 0
          else
            next if ignore_club_in_kristall(person_result.get_club_name)
            next if clubs[person_result.get_club_name.to_sym] # only the first in club counts
            clubs.store(person_result.get_club_name.to_sym, 1)
			if !last_result.nil? && last_result == person_result.time
				# same time, same points
				points += 1
			end
			last_result = person_result.time
            person_result.rank_value = points
            points -= 1 if points > 1
			
          end
        end
      end
    end
  end

  def ignore_club_in_nebel(name)
    return true if name.nil?
    return true if name.empty?
    return true if name =~ /ohne/
    return true if name =~ /Volkssport/
    false
  end

  def calculate_nebel_points
    @events.each do |event|
      event.event_classes.each do |event_class|
        clubs = {}

        event_class.best_time = nil

        unless event_class.ignore_in_nor
          event_class.results.each do |person_result|
            next if (person_result.time.nil?)
            next if (person_result.position.nil?)
            if event_class.best_time.nil? || event_class.best_time > person_result.time
              event_class.best_time = person_result.time
            end
          end
        end

        event_class.results.each do |person_result|
          if event_class.ignore_in_nebel
            person_result.rank_value = 0
          elsif person_result.time.nil? || person_result.position.nil?
            person_result.rank_value = 0
          else
            next if ignore_club_in_nebel(person_result.get_club_name)
            next if clubs[person_result.get_club_name.to_sym] # only the fist in club counts
            clubs.store(person_result.get_club_name.to_sym, 1)
            person_result.rank_value = calculate_points_nor(event_class.best_time, person_result.time)
          end
        end
      end
    end
  end

end