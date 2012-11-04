class PersonResult

  attr_accessor :person_id
  attr_accessor :family_name
  attr_accessor :given_name
  attr_accessor :club_id
  attr_accessor :club_name
  attr_accessor :club_short_name
  attr_accessor :time
  attr_accessor :state
  attr_accessor :position
  attr_accessor :rank_value

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

  def get_integer_position
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

  def ignore_in_nor
    return true if name == "BK" ||  name == "Beg" || name == "BL" || name == "Trim"
  end

end

class Event
  attr_accessor :name
  attr_accessor :event_classes
end