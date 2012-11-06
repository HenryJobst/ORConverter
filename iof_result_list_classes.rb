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
    "#{given_name} #{family_name}"
  end

  def get_position
    if position.nil? || position.empty?
      #puts state.to_s
      if state.to_s == "OK" || state.to_s == "NotCompeting"
        return "AK"
      elsif state.to_s == "MisPunch"
        return "Fehlst"
      elsif state.to_s == "DidNotFinish" || state.to_s == "SportWithdr"
        return "Aufg"
      elsif state.to_s == "DidNotStart" || state.to_s == "Cancelled"
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

  def integer_position
    if position.nil? || position.empty?
      return 9999999
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
    return true if name == "BK" ||  name == "Beg" || name == "BL" || name == "Trim"
  end

  def ignore_in_kristall
    return true if name == "BK" ||  name == "Beg" || name == "BL" || name == "Trim" || name == "H-10" || name == "D-10"
  end

end

class Event
  attr_accessor :name
  attr_accessor :event_classes
end

def filename_from_name(name)
  File.basename(name.gsub("\s", "_").tr("/\000", ""))
end