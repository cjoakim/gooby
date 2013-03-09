=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class represent a Date and Time as parsed from a value
such as '2006-01-15T13:41:40Z' in an XML file produced by a GPS device.
It wrappers a Time object.

=end

module Gooby

  class Config

    include Gooby::Constants
    
    attr_reader :filename, :values

    def initialize(config_filename='config/gooby.yml')
      @filename = config_filename
      if File.exist?(filename)
        puts "loading configuration file #{filename}"
        @values = YAML::load(File.open(filename))
        true
      else
        @values = {}
        puts "ERROR: the configuration file does not exist - #{filename}"
        false
      end
    end
    
    def json_data_file
      @values['json_data_file'] ||= ''  
    end
    
    def approx_max_points
      @values['approx_max_points'] ||= 200  
    end
    
    def map_dom_element_id
      @values['map_dom_element_id'] ||= 'map_canvas'  
    end

    def gmap_api_key
      @values['gmap_api_key'] ||= ''  
    end

    def gmap_type
      @values['gmap_type'] ||= 'TERRAIN'  
    end
    
    def gmap_route_color
      @values['gmap_route_color'] ||= '#FF0000' # TODO - remove #
    end     

    def gmap_route_opacity
      @values['gmap_route_opacity'] ||= 0.6
    end
    
    def gmap_route_weight
      @values['gmap_route_weight'] ||= 2 
    end
    
    def gmap_zoom_level
      @values['gmap_zoom_level'] ||= 14 
    end
    
    def include_start_finish_markers?
      @values['include_start_finish_markers'] ||= false
    end
    
    def include_mile_markers?
      @values['include_mile_markers'] ||= false
    end
    
    def start_marker_color
      @values['start_marker_color'] ||= '00FF00' 
    end

    def finish_marker_color
      @values['finish_marker_color'] ||= 'FF0000' 
    end
    
    def mile_marker_color
      @values['mile_marker_color'] ||= '0000FF' 
    end
    
    def mile_marker_title_detail
      @values['mile_marker_title_detail'] ||= 'miles,elapsed,pace' 
    end
    
  end

end
