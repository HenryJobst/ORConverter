class PersonResult

  attr_accessor :person_id
  attr_accessor :family_name
  attr_accessor :given_name
  attr_accessor :birth_year
  attr_accessor :club_id
  attr_accessor :club_name
  attr_accessor :club_short_name
  attr_accessor :time
  attr_accessor :state
  attr_accessor :position
  attr_accessor :rank_value

  def initialize
    @rank_value = 0
  end

  def full_name
	fname = family_name
	if fname =~ /^\w+$/
		fname.capitalize!
	end
	"#{given_name} #{fname}"
  end

  def get_position
    if position.nil? || position.empty?
      #puts state.to_s
      if ak()
        return "AK"
      elsif state.to_s == "MisPunch"
        return "Fehlst"
      elsif state.to_s == "DidNotFinish" || state.to_s == "SportWithdr"
        return "Aufg"
      elsif did_not_start()
        return "N Ang"
      elsif state.to_s == "Disqualified"
        return "Disq"
      elsif state.to_s == "OverTime"
        return "Lim"
      else
        return state.to_s
      end
    end
    position.to_s
  end

  def did_not_start
    state.to_s == "DidNotStart" || state.to_s == "Cancelled"
  end

  def ak
    state.to_s == "OK" || state.to_s == "NotCompeting"
  end

  def real_position
    return true if get_position =~ /^\d+$/
    false
  end

  def real_or_ak_position
    pos = get_position
    return pos if pos =~ /^\d+$/
    return pos if pos =~ /AK/
    nil
  end

  def real_or_ak_position_to_s
    pos = real_position
    return pos.to_s if pos
    ""
  end

  HIGH_POSITION = 9999999

  def integer_position
    if position.nil? || position.empty?
      return ak ? HIGH_POSITION-1 : (did_not_start ? HIGH_POSITION+1 : HIGH_POSITION)
    end
    position
  end

  def get_club_name
    return club_short_name.to_s if !club_short_name.nil?
    return club_name.to_s if !club_name.nil?
    club_id.to_s
  end
end

class EventClass
  attr_accessor :name
  attr_accessor :best_time
  attr_accessor :results
  attr_accessor :length
  attr_accessor :control_count

  def ignore_in_nor
    return true if name == "BK" ||  name == "Beg" || name == "BL" || name == "Trim" || name == "Beginner Kurz" || name == "Beginner Lang"
  end

  def ignore_in_nebel
    return true if name == "BK" ||  name == "Beg" || name == "BL" || name == "Trimm"
  end

  def ignore_in_kristall
    return true if name == "BK" ||  name == "Beg" || name == "BL" || name == "Trimm"
  end

  def ignore_in_rank_mode(rank_mode)
    ignore_in_nor if rank_mode == :nor
    ignore_in_nebel if rank_mode == :nebel
    ignore_in_kristall if rank_mode == :kristall
  end
end

class Event
  attr_accessor :name
  attr_accessor :event_classes
end

def name_from_filename(name)
  File.basename(name, File.extname(name))
end

def filename_from_name(name)
  prepare_filename(name_from_filename(name))
end

def prepare_filename(name)
  name.gsub("\s", "_").gsub("/","_").gsub("\\","_").downcase
end

