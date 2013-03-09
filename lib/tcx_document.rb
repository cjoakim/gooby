=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class are used to parse a *.tcx file.

=end

module Gooby

  class TcxDocument < Gooby::XmlDocument

    def source_type
      :tcx
    end

    def start_element(tagname, attrs=[])
      tagname.downcase!
      @curr_text = nil
      if tagname == 'trackpoint'
        @in_trackpoint = true
        @curr_tkpt = Trackpoint.new(source_type)
        attrs.each { | pair | curr_tkpt.set(pair[0], pair[1]) }
      end
    end

    def end_element(tagname)
      tagname.downcase!
      if tagname == 'id'
        @start_time = current_text
      elsif tagname == 'trackpoint'
        @in_trackpoint = false
        @trackpoints << curr_tkpt
      elsif tagname == 'trainingcenterdatabase'
        @end_tag_reached = true
      elsif TCX_TRACKPOINT_TAGS.include?(tagname)
        if curr_tkpt && in_trackpoint
          curr_tkpt.set(tagname, current_text)
        end
      end
      @curr_text = nil
    end

    def to_json(pretty=false)
      hash, array = {}, []
      trackpoints.each { | tkpt |
        array << tkpt.json_hash
      }
      hash['source_type'] = source_type
      hash['start_time']  = start_time
      hash['start_epoch'] = start_datetime.to_i
      hash['trackpoint_count'] = array.size
      hash['trackpoints'] = array
      if pretty
        JSON.pretty_generate(hash)
      else
        hash.to_json
      end
    end

  end

end
