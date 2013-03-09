=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

This is the superclass of Gooby::TcxDocument and Gooby::GpxDocument.

=end

module Gooby

  class XmlDocument < Nokogiri::XML::SAX::Document

    include Gooby::Constants

    attr_reader :trackpoints, :heirarchy, :start_time, :start_datetime
    attr_reader :curr_text, :curr_tkpt, :verbose
    attr_reader :in_trackpoint, :end_tag_reached, :end_reached

    def initialize
      @trackpoints, @start_time = [], nil
      @curr_text, @curr_tkpt, @verbose = '', nil, true
      @in_trackpoint, @end_tag_reached, @end_reached = false, false, false
    end

    def end_document
      @end_reached = true
      @start_datetime = Gooby::DateTime.new(start_time)
      if parsed?
        latest_values = Hash.new('')
        trackpoints.each_with_index { | tkpt, idx |
          tkpt.finish_parsing(idx, latest_values, start_datetime)
          keys = tkpt.values.keys
          keys.each { | key |
            val = tkpt.values[key]
            if val
              latest_values[key] = val
            end
          }
        }
        next_mile_marker = 1.0
        trackpoints.each { | tkpt |
          m = tkpt.get('miles')
          if m && m.to_f >= next_mile_marker
            tkpt.set('mile_marker', next_mile_marker)
            next_mile_marker = next_mile_marker + 1.0
          end
        }
      end
    end

    def cdata_block(s)
      text(s)
    end

    def characters(s)
      text(s)
    end

    def warning(msg)
      puts "document warning: #{msg}"
    end

    def current_text
      (curr_text.nil?) ? '' : curr_text
    end

    def parsed?
      end_tag_reached && end_reached
    end

    def text(s)
      if s
        if @curr_text.nil?
          @curr_text = s
        else
          @curr_text << s
        end
      end
    end

  end

end