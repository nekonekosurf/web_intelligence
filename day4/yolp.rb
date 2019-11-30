#!/usr/bin/env ruby
# encoding: utf-8
require "json"
require "open-uri"
require "uri"

class YOLP
  def initialize(app_id= "dj0zaiZpPWxPNFl0STFYSDE0cSZzPWNvbnN1bWVyc2VjcmV0Jng9Njg-")
    @app_id = app_id
    # Hubenyの式による距離計算用パラメータ
    #rx:長半径（赤道）,ry:短半径（極）
    # Wikipedia 測地学(WGS84)
    # https://ja.wikipedia.org/wiki/%E6%B8%AC%E5%9C%B0%E5%AD%A6
    @rx = 6378137.000
    @ry = 6356752.314245
    @e = Math.sqrt(1-(@ry/@rx)**2)
    @rdRatio = Math::PI/180
  end
  def coordinate(address)
    coord = nil
    open("http://geo.search.olp.yahooapis.jp/OpenLocalPlatform/V1/geoCoder?query=#{URI.escape(address)}&appid=#{@app_id}&output=json"){|f|
      json = JSON.parse(f.read)
      if json['ResultInfo']['Count'] > 0
        coord = json['Feature'][0]['Geometry']['Coordinates'].split(/,/)
        if coord.length == 2
          coord[0] = coord[0].to_f
          coord[1] = coord[1].to_f
        end
      end
    }
    coord
  end
  def address(coord)
    address = nil
    cArray = coord
    if !coord.is_a?(Array)
      cArray = coord.split(/\s*,\s*/)
    end
    open("http://reverse.search.olp.yahooapis.jp/OpenLocalPlatform/V1/reverseGeoCoder?lat=#{cArray[0]}&lon=#{cArray[1]}&appid=#{@app_id}&output=json"){|f|
      json = JSON.parse(f.read)
      if json['ResultInfo']['Count'] > 0
        address = json['Feature'][0]['Property']['Address']
      end
    }
    address
  end
  def distance(coord1, coord2)
    rlat1 = @rdRatio  * coord1[0]
    rlat2 = @rdRatio  * coord2[0]
    dy = rlat1 - rlat2
    rlon1 = @rdRatio  * coord1[1]
    rlon2 = @rdRatio  * coord2[1]
    dx = rlon1 - rlon2
    p= (rlat1+rlat2)/2
    w= Math.sqrt(1-(@e*Math.sin(p))**2)
    m = @rx*(1-@e**2)/(w**3)
    n = @rx/w
    return Math.sqrt((dy*m)**2+(dx*n*Math.cos(p))**2)
    
  end
end
