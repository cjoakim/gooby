=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class are used to parse a *.gpx file.

NOTE: *.gpx files are not officially supported in Gooby version 3.0.0.

=end

module Gooby

  class GpxDocument < Gooby::XmlDocument

    def source_type
      :gpx
    end

    def start_element(tagname, attrs=[])
      @curr_text = ''
      if tagname == 'trkpt'
        @in_trackpoint = true
        @curr_tkpt = Trackpoint.new(source_type)
        attrs.each { | pair | curr_tkpt.set(pair[0], pair[1]) }
      end
    end

    def end_element(tagname)
      if tagname == 'name'
        @start_time = current_text
      elsif tagname == 'trkpt'
        @in_trackpoint = false
        @trackpoints << curr_tkpt
      elsif tagname == 'gpx'
        @end_tag_reached = true
      elsif GPX_TRACKPOINT_TAGS.include?(tagname)
        if curr_tkpt && in_trackpoint
          curr_tkpt.set(tagname, current_text)
        end
      end
      @curr_text = ''
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
