=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class represent a Date and Time as parsed from a value
such as '2006-01-15T13:41:40Z' in an XML file produced by a GPS device.
It wrappers a Time object.

=end

module Gooby

  class DateTime

    include Gooby::Constants

    @@months = Hash.new('')

    attr_accessor :time, :valid

    # The arg is a String like '2006-01-15T13:41:40Z'.
    def initialize(raw)
      @valid = false
      if raw
        begin
          @time  = Time.parse(raw)
          @valid = true if @time
        rescue Exception => e
          @valid = false
        end
      end
    end

    def to_i
      (@time) ? @time.to_i : invalid_time
    end

    def valid?
      valid
    end

    def invalid_time
      return -99999999
    end

    def yyyy_mm_dd
      time.strftime("%Y-%m-%d")
    end

    def yyyy_mm_dd_hh_mm_ss(delim=' ')
      time.strftime("#{yyyy_mm_dd}#{delim}#{hh_mm_ss}")
    end

    def hh_mm_ss
      time.strftime("%H:%M:%S")
    end

    def seconds_diff(another_dttm)
      if another_dttm
        to_i - another_dttm.to_i
      else
        invalid_time
      end
    end

    def hhmmss_diff(another_dttm)
      if another_dttm
        secs = seconds_diff(another_dttm).abs
        hh   = (secs / SECONDS_PER_HOUR).to_i
        rem  = secs - (hh * SECONDS_PER_HOUR)
        mm   = (rem / 60).to_i
        ss   = rem - (mm * 60).to_i
        ss   = 59 if ss > 59
        "#{hh}:#{zero_pad(mm)}:#{zero_pad(ss.to_i)}"
      else
        '?:??:??'
      end
    end

    def to_s
      "#{yyyy_mm_dd} #{hh_mm_ss} #{to_i}"
    end

    private

    def zero_pad(val)
      if (val.to_i < 10)
        return '0' + val.to_s
      else
        return '' + val.to_s
      end
    end

  end

end
