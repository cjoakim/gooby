=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class are used to generate the JavaScript for a 
Google map from a configuration yml file, which includes a reference to
a JSON data file created by Gooby.

=end

module Gooby

  class GmapGenerator

    include Gooby::Constants

    attr_accessor :config, :source_type, :json_data, :tkpts, :js_lines

    # The arg is a String like '2006-01-15T13:41:40Z'.
    def initialize(config_filename)
      @config = load_config(config_filename)
      @tkpts, @source_type = [], ''
      if config 
        @json_data = load_json_data
        if json_data
          @source_type = json_data['source_type'].to_sym
          tkpt_hashes  = json_data['trackpoints']
          tkpt_hashes.each { | tkpt_hash |
            tkpts << Gooby::Trackpoint.new(source_type, tkpt_hash)  
          }
          preprocess_trackpoints
          generate_map_js        
        end
      end
    end
    
    def load_config(config_filename)
      Gooby::Config.new(config_filename)
    end
    
    def load_json_data
      json_data_file = config.json_data_file
      if json_data_file
        if File.exist?(json_data_file)
          puts "loading json data file #{json_data_file}"
          JSON::load(File.open(json_data_file))
        else
          puts "ERROR: the json data file does not exist - #{json_data_file}"
          nil
        end
      else
          puts "ERROR: no json data file entry in the configuration yml"
          nil
      end
    end
    
    def preprocess_trackpoints
      approx_max_points = config.approx_max_points
      every_n = tkpts.size / approx_max_points
      next_n  = every_n
      last_idx = tkpts.size - 1
      
      tkpts.each_with_index { | tkpt, idx |
        tkpt.set('include_in_map', false) 
        if (idx == 0) || (idx == last_idx)
          tkpt.set('include_in_map', true)  
        elsif tkpt.is_mile_marker?
          tkpt.set('include_in_map', true)
          next_n = idx + every_n
        elsif idx == next_n 
          tkpt.set('include_in_map', true)
          next_n = next_n + every_n
        end 
      }
      count = 0
      tkpts.each { | tkpt |
        count = count + 1 if tkpt.include_in_map?
      }
      puts "preprocess_trackpoints - total: #{tkpts.size}  approx_max_points: #{approx_max_points}  every: #{every_n}  actual: #{count}"  
    end
    
    def generate_map_js
      @js_lines = []
      generate_googleapis_script
      add "<script type=|text/javascript|>"
      add "  function initialize() {"
      add "    var startImage = 'images/dd-start.png';"
      add "    var endImage   = 'images/dd-end.png';"
      add_map_options
      add "    var map = new google.maps.Map(document.getElementById(|#{config.map_dom_element_id}|), mapOptions);"
      add_route_coordinates
      add_route_polyline
      add_start_and_end_markers
      add_mile_markers
      add ""
      add ""
      add ""
      add "  }"
      add "</script>" 
      puts "---"
      
      #js_lines.each { | line | puts line }
      write_javascript_file
    end
    
    def add_map_options
      tkpt1 = tkpts[0]
      add "    var mapOptions = {"
      add "      mapTypeId: google.maps.MapTypeId.#{config.gmap_type}, // ROADMAP, SATELLITE, HYBRID, or TERRAIN"
      add "      center: new google.maps.LatLng(#{tkpt1.get('lat')}, #{tkpt1.get('lon')}),"
      add "      disableDefaultUI: true,"
      add "      panControl: true,"
      add "      scaleControl: true,"
      add "      streetViewControl: true,"
      add "      overviewMapControl: false,"

      add "      mapTypeControl: true,"
      add "      mapTypeControlOptions: {"
      add "        style: google.maps.MapTypeControlStyle.DROPDOWN_MENU"
      add "      },"

      add "      zoom: #{config.gmap_zoom_level}, // 0=Earth, 23=dirt"
      add "      zoomControl: true,"
      add "      zoomControlOptions: {"
      add "        style: google.maps.ZoomControlStyle.DEFAULT // SMALL, LARGE, DEFAULT"
      add "      }"
      add "    };"
    end
    
    def generate_googleapis_script
      add "<script type=|text/javascript| src=|http://maps.googleapis.com/maps/api/js?key=#{config.gmap_api_key}&sensor=false|>"
      add "</script>" 
    end
    
    def add_route_coordinates
      add "    var routeCoordinates = ["
      tkpts.each { | tkpt |
        if tkpt.include_in_map?
          add "      #{tkpt.as_LatLng}"
        end
      }
      add "    ];"
    end
    
    def add_route_polyline
      add "    var route = new google.maps.Polyline({"
      add "      path:          routeCoordinates,"
      add "      strokeColor:   |##{config.gmap_route_color}|,"
      add "      strokeOpacity: #{config.gmap_route_opacity},"
      add "      strokeWeight:  #{config.gmap_route_weight}"
      add "    });"
      add "    route.setMap(map);"
    end

    def add_start_and_end_markers
      if config.include_start_finish_markers?
        add_marker('start',  tkpts[0],  config.start_marker_color, tkpts[0].start_marker_title(config))
        add_marker('finish', tkpts[-1], config.finish_marker_color, tkpts[-1].finish_marker_title(config))
      end
    end
    
    def add_mile_markers
      if config.include_mile_markers?
        tkpts.each { | tkpt |
          if tkpt.include_in_map? && tkpt.is_mile_marker?
            mile = tkpt.get('mile_marker').to_i.to_s
            add_marker("mile_#{mile}", tkpt, config.mile_marker_color, tkpt.mile_marker_title(config))
          end
        }
      end
    end
    
    def add_marker(name, tkpt, color, title)
      add ""
      add "    var marker_latlng_#{name} = new google.maps.LatLng(#{tkpt.get('lat')}, #{tkpt.get('lon')});"
      add "    var marker_#{name} = new google.maps.Marker({"
      add "      position: marker_latlng_#{name},"
      add "      map: map,"
      add "      icon: {"
      add "        path: google.maps.SymbolPath.CIRCLE, "
      add "        fillOpacity: 1.0,"
      add "        strokeOpacity: 1.0,"
      add "        strokeColor: |#{color}|,"
      add "        strokeWeight: 2.0,"
      add "        scale:        3"
      add "      },"
      add "      title: |#{title}|"
      add "    });"
    end
    
    def add(line)
      @js_lines << line.tr('|','"') if line
    end

    def js_filename
      idx = config.json_data_file.rindex('.')
      if idx
        "#{config.json_data_file.slice(0, idx)}.js"
      else
        "#{config.json_data_file}.js"
      end
    end
    
    def write_javascript_file
      sio = StringIO.new
      js_lines.each { | line | sio << "#{line}\n" }
      out_name = js_filename
      out = File.new out_name, "w+"
      out.write sio.string
      out.flush
      out.close
      puts "file written: #{out_name}"
    end

  end

end
  