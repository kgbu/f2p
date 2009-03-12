require 'json'
require 'nkf'
require 'xsd/mapping'
require 'erb'


module GoogleMaps
  module HashUtils
    def v(hash, *keywords)
      keywords.inject(hash) { |r, k|
        r.respond_to?(k) ? r.send(k) : r[k] if r
      }
    end
  end

  class Point
    attr_reader :address, :lat, :long

    def initialize(address, lat, long)
      @address = address
      @lat = lat
      @long = long
    end

    def ambiguous?
      false
    end
  end

  class Candidates
    attr_reader :candidates

    def initialize(candidates)
      @candidates = candidates
    end

    def ambiguous?
      true
    end
  end

  class GeocodingJpGeocoder
    include HashUtils

    URL = 'http://www.geocoding.jp/api/'

    def initialize(httpclient)
      @httpclient = httpclient
      @last = nil
    end

    def search(str, hl = 'ja')
      raise if hl != 'ja'
      query = { 'q' => str, 'v' => 1.1 }
      result = XSD::Mapping.xml2obj(@httpclient.get_content(URL, query))
      if result.nil? or v(result, 'error')
        nil
      elsif choices = v(result, 'choices', 'choice')
        Candidates.new(choices.uniq)
      else
        address = v(result, 'google_maps')
        address = nil if address.is_a?(SOAP::Mapping::Object)
        address = nil if address and address.empty?
        c = v(result, 'coordinate')
        lat = v(c, 'lat')
        long = v(c, 'lng')
        if address and lat and long
          Point.new(address, lat, long)
        end
      end
    end
  end

  class GoogleGeocoder
    URL = 'http://maps.google.com/maps/geo'

    def initialize(httpclient, key)
      @httpclient = httpclient
      @key = key
    end

    def search(str, hl = 'ja')
      query = {
        'q' => str,
        'output' => 'json',
        'hl' => hl,
        'key' => @key
      }
      result = JSON.parse(NKF.nkf('-wm0', @httpclient.get_content(URL, query)))
      # TODO: need to construct Point or Candidates.
      nil
    end
  end

  class URLGenerator
    def initialize(key = nil)
      @key = key
    end

    def staticmap_url(maptype, lat, long, opt = {})
      zoom = opt[:zoom] || 12
      width = opt[:width] || 160
      height = opt[:height] || 80
      url = "http://maps.google.com/staticmap?zoom=#{zoom}&size=#{width}x#{height}&maptype=#{maptype}&markers=#{lat},#{long}"
      if @key
        url += "&key=#{@key}"
      end
      url
    end

    def link_url(lat, long, title = nil)
      if title
        title = title.gsub(/[\r\n]+/, ' ')
        title = '+' + ERB::Util.u("(#{unwrap_title(title)})")
      else
        title = ''
      end
      "http://maps.google.com/maps?q=#{lat},#{long}#{title}"
    end

  private

    def unwrap_title(title)
      if /\((.+)\)/ =~ title
        $1
      else
        title
      end
    end
  end
end


if $0 == __FILE__
  require 'httpclient'
  require 'pp'
  pp GoogleMaps::Geocoder.new(HTTPClient).search('日本、東京駅')
end
