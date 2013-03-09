=begin

Gooby = Google APIs + Ruby.  Copyright 2012 by Chris Joakim.
Gooby is available under GNU General Public License (GPL) license.

---

Instances of this class are used to parse an XML file, such as a *.tcx.

=end

module Gooby

  class XmlParser < Object

    include Gooby::Constants

    attr_accessor :filename
    attr_reader   :document, :sax_parser

    def initialize
    end

    def parse_tcx(file)
      puts "parsing tcx file #{file}"
      @document, @filename = Gooby::TcxDocument.new, "#{file}".strip
      parse
      write_json_file
    end

    # def parse_gpx(file)
    #   puts "parsing gpx file #{file}"
    #   @document, @filename = Gooby::GpxDocument.new, "#{file}".strip
    #   parse
    #   write_json_file
    # end

    def json_filename
      idx = filename.downcase.rindex('.')
      if idx
        "#{filename.slice(0, idx)}.json"
      else
        "#{filename}.json"
      end
    end

    private

    def parse
      @sax_parser = Nokogiri::XML::SAX::Parser.new(document)
      sax_parser.parse(File.open(filename))
    end

    def write_json_file
      out_name = json_filename
      out = File.new out_name, "w+"
      out.write document.to_json(true)
      out.flush
      out.close
      puts "file written: #{out_name}"
    end

  end

end
