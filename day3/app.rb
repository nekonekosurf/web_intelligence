#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require './yolp'
require 'open-uri'
require 'json'
get '/' do
  erb :putInformation
end

get '/result' do
  yolp = YOLP.new
  coord = yolp.coordinate(params[:address].to_s)
  redirect '/' if (params[:address].to_s == '') || coord.nil?

  @basic_adress = params[:address].to_s
  @ido = (coord[1]).to_s
  @keido = (coord[0]).to_s

  # @library_name=get_library_name("BB21074902")
  # hash=get_library_name("AA12007953")     #ここで図書館の名前と住所をハッシュに入れている
  hash = get_library_name(params[:book_id].to_s) # ここで図書館の名前と住所をハッシュに入れている
  # 図書館名=>住所
  # {"公立はこだて未来大学 情報ライブラリー"=>"函館市亀田中野町116-2", "三重大学 附属図書館"=>"三重県津市栗真町屋町 1577", "大阪電気通信大学 図書館"=>"大阪府寝屋川市初町18-8"}

  @hash = hash
  hash2 = Hash.new { |h, k| h[k] = {} }
  hash.each do |name, address|
    target_library = yolp.coordinate(address)
    if target_library.nil?
      puts 'nillllllllll!'
      next
    end

    dist_ = yolp.distance([coord[1], coord[0]], [target_library[1], target_library[0]])
    #  puts "#{name} と#{address} との距離 #{yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])}"
    hash2[hash[name]] = dist_
  end
  temp = []
  temp = hash2.sort { |(_k1, v1), (_k2, v2)| v1 <=> v2 }
  p temp[0]
  array_order = []
  temp.each do |n|
    p n[0]
    p hash.invert[n[0]]
    array_order.push(hash.invert[n[0]])
  end
  puts
  puts array_order
  @array_order = array_order
  erb :display
end

def get_adrress(id)
  baseidURL = id
  target = baseidURL.gsub(/^http:/, 'https:')
  target += '.json'
  begin
    open(target) do |f|
      hash = JSON.load(f)
      p hash['@graph'][0]['v:adr']['v:label']
      return hash['@graph'][0]['v:adr']['v:label']
    end
  rescue StandardError => e
    puts e
  end
end

def get_library_name(key_w)
  baseidURL = 'https://ci.nii.ac.jp/ncid/' + key_w + '.json'
  target = baseidURL.gsub(/^http:/, 'https:')
  file = File.open('result.json', 'w')
  reHash = {}
  begin
    open(target) do |f|
      hash = JSON.load(f)
      i = 1
      hash['@graph'][0]['bibo:owner'].each do |n|
        # puts i
        # puts n["foaf:name"]
        # reHash[n["foaf:name"]]= get_adrress(n["@id"])
        reHash.store((n['foaf:name']).to_s, get_adrress(n['@id']))
        #  puts reHash
        # get_adrress(n["@id"])
        puts
        i += 1
      end
    end
  rescue StandardError => e
    puts e
    redirect '/'
  end
  reHash
end
