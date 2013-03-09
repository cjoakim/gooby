=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class represent a parsed trackpoint within a route.
This class additionally contains methods related to calculating distance,
elapsed time, pace, mph, etc.

=end

module Gooby

  class Trackpoint

    include Gooby::Constants

    attr_reader :source_type, :values

    def initialize(type = :tcx, json_hash_values=nil)
      @source_type, @values = type, Hash.new('')
      if json_hash_values
        json_hash_values.keys.each { | k | 
          @values[k] = json_hash_values[k]
        }   
      end
    end

    def finish_parsing(idx, latest_values, start_datetime)
      set('seq', idx + 1)
      if tcx?
        TCX_TRACKPOINT_TAGS.each { | tag |
          if values[tag] == ''
            set(tag, latest_values[tag])
          end
        }
      elsif gpx?
        GPX_TRACKPOINT_TAGS.each { | tag |
          if values[tag] == ''
            set(tag, latest_values[tag])
          end
        }
      end
      calculate_elapsed_time(start_datetime)
      calculate_elapsed_miles
      compute_pace_and_mph(start_datetime)
    end

    def set(key, val)
      values[key.downcase] = val if key && val
    end

    def get(name)
      values[name]
    end
    
    def sequence
      values['seq']
    end

    def to_s
      values.inspect
    end

    def latitude
      l = get('latitudedegrees')
      if l.size < 1
        l = get('lat')
      end
      l
    end

    def longitude
      l = get('longitudedegrees')
      if l.size < 1
        l = get('lon')
      end
      l
    end

    def altitude
      a = get('altitudemeters')
      if a.size < 1
        a = get('ele')
      end
      if a.size < 1
        a = get('alt')
      end
      a
    end

    def altitude_ft
      (altitude.to_f) * METERS_PER_FOOT
    end
    
    def miles
      get('miles').to_f  
    end

    def tcx?
      source_type == :tcx
    end

    def gpx?
      source_type == :gpx
    end

    def is_mile_marker?
      values['mile_marker'].to_i > 0
    end
    
    def include_in_map?
      values['include_in_map'] == true  
    end
    
    def start_marker_title(config)
      "Start, #{time}"
    end
    
    def finish_marker_title(config)
      sio = StringIO.new
      sio << "Finish"
      mile_marker_detail(config, sio)
      sio.string
    end

    def mile_marker_title(config)
      sio = StringIO.new
      sio << "Mile #{get('miles').to_i}"
      mile_marker_detail(config, sio)
      sio.string
    end
    
    def mile_marker_detail(config, sio)
      detail_fields = config.mile_marker_title_detail.split(',')
      return if detail_fields.include?('none')
      detail_fields.each { | field |
        if field.strip == 'time'
          sio << ", #{time}" 
        elsif field.strip == 'miles'
          sio << ", #{sprintf("%3.4f", miles)}" 
        else
          sio << ", #{get(field.strip)}"
        end  
      }
    end
    
    def time
      get('time').tr('TZ','  ').strip
    end

    def json_hash
      hash = {}
      hash['seq']     = sequence
      hash['time']    = values['time']
      hash['epoch']   = values['epoch']
      hash['elapsed'] = values['elapsed']
      hash['miles']   = values['miles']
      hash['pace']    = values['pace']
      hash['mph']     = values['mph']
      hash['mile_marker'] = values['mile_marker'] if values['mile_marker'].to_s.size > 0
      hash['lat']     = latitude
      hash['lon']     = longitude
      hash['alt']     = altitude
      if tcx?
        hash['dist_meters'] = values['distancemeters']
      end
      hash
    end
    
    def as_LatLng
      "new google.maps.LatLng(#{values['lat']}, #{values['lon']}), // #{values['seq']} #{values['mile_marker']}"
    end

    def calculate_elapsed_time(start_datetime) # an instance of Gooby::DateTime
      if start_datetime && start_datetime.valid?
        t = Gooby::DateTime.new(values['time'])
        if t && t.valid?
          values['epoch'] = t.to_i
          values['elapsed'] = start_datetime.hhmmss_diff(t)
        end
      end
    end

    def calculate_elapsed_miles
      meters = get('distancemeters')
      if meters && meters.to_f > 0.0
        set('miles', meters.to_f / METERS_PER_MILE)
      else
        set('miles', 0.0)
      end
    end

    def same_location?(another_tkpt)
      if another_tkpt
        return false if latitude  != another_tkpt.latitude
        return false if longitude != another_tkpt.longitude
        true
      else
        false
      end
    end

    def degrees_diff(another_tkpt)
      if another_tkpt
        lat_diff = latitude.to_f  - another_tkpt.latitude.to_f
        lng_diff = longitude.to_f - another_tkpt.longitude.to_f
        lat_diff.abs + lng_diff.abs
      else
        360.0
      end
    end

    def proximity(another_tkpt, uom='m')
      if same_location?(another_tkpt)
        return 0.0
      end
      if another_tkpt
        arg1  = latitude.to_f
        arg2  = another_tkpt.latitude.to_f
        arg3  = latitude.to_f
        arg4  = another_tkpt.latitude.to_f
        theta = longitude.to_f - another_tkpt.longitude.to_f
        res1  = Math.sin(deg2rad(arg1)).to_f
        res2  = Math.sin(deg2rad(arg2)).to_f
        res3  = Math.cos(deg2rad(arg3)).to_f
        res4  = Math.cos(deg2rad(arg4)).to_f
        res5  = Math.cos(deg2rad(theta.to_f))
        dist  = ((res1 * res2).to_f + (res3 * res4 * res5).to_f).to_f
        # puts "proximity #{another_tkpt.sequence} a1: #{arg1} a2: #{arg2} a3: #{arg3} a4: #{arg4} t: #{theta} r1: #{res1} r2: #{res2} r3: #{res3} r4: #{res4} r5: #{res5} #{dist}"
        if !dist.nan?
          dist = Math.acos(dist.to_f)
          if (!dist.nan?)
            dist = rad2deg(dist)
            if !dist.nan?
              dist = dist * 60.0 * 1.1515;
              if !dist.nan?
                if uom == "km"
                   dist = dist * 1.609344;
                elsif uom == "n"
                   dist = dist * 0.8684;
                end
              end
            end
          end
          return dist.to_f
        else
          return 0.0
        end
      else
        return 0.0
      end
    end

    def deg2rad(degrees)
      (((0.0 + degrees.to_f) * Math::PI) / 180.0)
    end

    def rad2deg(radians)
      (((0.0 + radians.to_f) * 180.0) / Math::PI)
    end

    def compute_pace_and_mph(first_tkpt_dttm)
      if miles > 0.0
        dttm = Gooby::DateTime.new(values['time'])
        secs_diff  = dttm.seconds_diff(first_tkpt_dttm)
        secs_mile  = ((secs_diff.to_f) / miles)
        mins_mile  = (secs_mile / 60.0)
        whole_mins = mins_mile.floor
        fract_mins = mins_mile - (whole_mins.to_f)
        fract_secs = fract_mins * 60.0
        if fract_secs < 10
          pace = sprintf("%d:0%2.2f", whole_mins, fract_secs)
        else
          pace = sprintf("%d:%2.2f", whole_mins, fract_secs)
        end
        set('pace', pace)
        hours = secs_diff / 3600.0
        mph   = sprintf("%5.3f", miles / hours)
        set('mph', sprintf("%5.3f", mph))
      else
        set('pace', '0:00')
        set('mph',  '0.00')
      end
    end

  end

end
