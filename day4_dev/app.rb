#!/usr/bin/env ruby
# coding: utf-8
require 'sinatra'
require './yolp'
require "open-uri"
require "json"

enable :sessions

get '/' do
  erb :putInformation
end

get '/result_' do
  yomikomi=20                                        #とってくる検索結果の数
  appid ="jsqAbSa3aKX49y0tRjEY"                      #アプリケーションキー
  key_w="#{params[:key_word]}"
  @key_word = "#{params[:key_word]}"
  session[:kijyun] = "#{params[:address]}"
  baseidURL = "https://ci.nii.ac.jp/books/opensearch/"
  target= baseidURL.gsub(/^http:/,"https:")
  target = baseidURL+"search?title="+key_w+"&format=json&appid="+appid
  file = File.open('result.json', "w");
  hash_title={} #タイトル入れ配列
  open(target){|f|
      hash = JSON.load(f)
      file.puts(hash)
      for n in 1..yomikomi do
        hash_title.store(hash["@graph"][0]["items"][n-1]["title"],hash["@graph"][0]["items"][n-1]["@id"])
      end
  }
  @hash_title = hash_title
  puts hash_title
  file.close
  erb :result_search
end

get '/result' do

  puts "value :"+"#{params[:value]}"
  yolp = YOLP.new
	coord = yolp.coordinate("#{session[:kijyun]}")
	@basic_adress = "#{session[:kijyun]}"
	@ido = "#{coord[1]}"
	@keido ="#{coord[0]}"
  book_id = "#{params[:value]}".delete!('http://ci.nii.ac.jp/ncid/')
  # book_id = "BB21074902"
  p book_id
  # hash=get_library_name_new("#{params[:book_id]}")
  hash=get_library_name(book_id)

  @hash = hash
  hash2=Hash.new { |h,k| h[k] = {} }
    hash.each{|name,address|
     target_library = yolp.coordinate(address)
    	dist_=yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])
		#	puts "#{name} と#{address} との距離 #{yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])}"
			  hash2[hash[name]]=dist_
		}
		temp= []
		temp=hash2.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }#
		p temp[0]
		array_order=[]
		for n in temp do
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
  target= baseidURL.gsub(/^http:/,"https:")
  target= target+".json"
  open(target){|f|
    hash = JSON.load(f)
    p hash["@graph"][0]["v:adr"]["v:label"]
    return hash["@graph"][0]["v:adr"]["v:label"]
  }
end


def get_library_name_new(key_w) #ncid検かける
  baseidURL = key_w+".json"
  target= baseidURL.gsub(/^http:/,"https:")
  # file = File.open('result.json', "w");

  reHash={}
  open(target){|f|
    hash = JSON.load(f)
    # file.puts(hash)
    i = 1
    for n in hash["@graph"][0]["bibo:owner"] do
      #puts i
      #puts n["foaf:name"]
      # reHash[n["foaf:name"]]= get_adrress(n["@id"])
      reHash.store("#{n["foaf:name"]}", get_adrress(n["@id"]))
    #  puts reHash
      # get_adrress(n["@id"])
      puts
      i +=1
    end

  }
  return reHash
end










def get_library_name(key_w)
  baseidURL = "https://ci.nii.ac.jp/ncid/"+key_w+".json"
  target= baseidURL.gsub(/^http:/,"https:")
  reHash={}
  open(target){|f|
    hash = JSON.load(f)
    i = 1
    for n in hash["@graph"][0]["bibo:owner"] do
      #puts i
      #puts n["foaf:name"]
      # reHash[n["foaf:name"]]= get_adrress(n["@id"])
      reHash.store("#{n["foaf:name"]}", get_adrress(n["@id"]))
    #  puts reHash
      # get_adrress(n["@id"])
      puts
      i +=1
    end

  }
  return reHash
end




















get '/select_document' do

  @value = "#{params[:value]}"
  puts "#{params[:value]}"
  name = get_library_name_new("#{params[:value]}")
  puts name






  puts "-------------------------------"
  puts
    @hash = hash
    yolp = YOLP.new
    coord = yolp.coordinate("#{params[:value]}")
    hash2=Hash.new { |h,k| h[k] = {} }
      name.each{|name,address|
       target_library = yolp.coordinate(address)
      	dist_=yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])
  		#	puts "#{name} と#{address} との距離 #{yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])}"
  			  hash2[hash[name]]=dist_
  		}
  		temp= []
  		temp=hash2.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }#
  		p temp[0]
  		array_order=[]
  		for n in temp do
  			p n[0]
  			p hash.invert[n[0]]
  			array_order.push(hash.invert[n[0]])
  		end
  		puts
      puts array_order
   		@array_order = array_order
   	 erb :display

     erb :last_view
   end
