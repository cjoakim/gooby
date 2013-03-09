=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

=end

module Gooby

  module Constants

    UOM_MILES           = "m"
    UOM_KILOMETERS      = "k"
    UOM_YARDS           = "y"
    KILOMETERS_PER_MILE = 1.61290322581
    METERS_PER_MILE     = KILOMETERS_PER_MILE * 1000
    YARDS_PER_MILE      = 1760.0
    MILES_PER_KILOMETER = 0.62
    YARDS_PER_KILOMETER = 1091.2
    METERS_PER_FOOT     = 3.281
    SECONDS_PER_HOUR    = 3600.0
    TCX_TRACKPOINT_TAGS = %w(time latitudedegrees longitudedegrees altitudemeters distancemeters)
    GPX_TRACKPOINT_TAGS = %w(time ele)
  end

end
