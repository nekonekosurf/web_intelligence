#!/usr/bin/env ruby
# coding: utf-8
require 'sinatra'
require './yolp'
require "open-uri"
require "json"
require 'active_record'
enable :sessions

ActiveRecord::Base.establish_connection(
  adapter:'sqlite3',
  database:'sandbox.db'
)

class Library_record< ActiveRecord::Base
end




get '/' do
  erb :putInformation
end

get '/result_' do
  yomikomi=20                                       #とってくる検索結果の数
  appid ="jsqAbSa3aKX49y0tRjEY"                     #アプリケーションキー
  key_w="#{params[:key_word]}"                      #検索語
  @key_word = "#{params[:key_word]}"
  session[:kijyun] = "#{params[:address]}"          #sessionで基準点を使いまわし
  baseidURL = "https://ci.nii.ac.jp/books/opensearch/" #キーワードで検索時のURL
  target= baseidURL.gsub(/^http:/,"https:")
  target = baseidURL+"search?title="+key_w+"&format=json&appid="+appid
  hash_title={}                                    #タイトルと住所の組み合わせのハッシュ
  open(target){|f|
      hash = JSON.load(f)
      for n in 1..yomikomi do
        hash_title.store(hash["@graph"][0]["items"][n-1]["title"],hash["@graph"][0]["items"][n-1]["@id"])
      end
  }
  @hash_title = hash_title
  erb :result_search
end

get '/result' do
  yolp = YOLP.new                  #地図を表示させるときに使うようになる
	coord = yolp.coordinate("#{session[:kijyun]}")       #基準点の経度井戸を計算
	@basic_adress = "#{session[:kijyun]}"
	@ido = "#{coord[1]}"
	@keido ="#{coord[0]}"
  book_id = "#{params[:value]}".delete!('http://ci.nii.ac.jp/ncid/') #valueには本のID以外にも余計なものが入っているので削除
  session[:book_id] = book_id
  hash=get_library_name(book_id)  #本のIDで図書館の名前と図書館の住所が入る
  @hash = hash
  array_order = libNmaeAdr_to_arrayOrder(hash,"#{session[:kijyun]}")
  @array_order = array_order
 	 erb :display
end


#距離のアップデート出きるに出きる毎回get書くのは適切でない気がする
get '/update_location' do          # 基準住所をアップデート
  yolp = YOLP.new                  #地図を表示させるときに使うようになる
	coord = yolp.coordinate("#{params[:address_new]}")       #基準点の経度井戸を計算
  @basic_adress = "#{params[:address_new]}"
  @ido = "#{coord[1]}"
  @keido ="#{coord[0]}"
  book_id = "#{session[:book_id]}" #valueには本のID以外にも余計なものが入っているので削除
  hash=get_library_name(book_id)  #本のIDで図書館の名前と図書館の住所が入る


  #データベース用い高速に


  hash.each { |key,value|
    #もし存在しなければ追加
    if !Library_record.where(library_name:key).exists?
      lib= Library_record.new(
        library_name:key,
        library_address:value
      )
      lib.save
    #もし存在すればデータベースから読み出し
    else

      puts key
      puts value
    end
    }






  @hash = hash
  array_order =libNmaeAdr_to_arrayOrder(hash,"#{params[:address_new]}")
  @array_order = array_order
  erb :display

end


def libNmaeAdr_to_arrayOrder(hash,kijyun)  #図書館の名前と住所ハッシュ基準値から距離順並べ配返す
  yolp = YOLP.new                  #地図を表示させるときに使うようになる
	coord = yolp.coordinate("#{session[:kijyun]}")       #基準点の経度井戸を計算
  hash2=Hash.new { |h,k| h[k] = {} }#hashのの情報をすべて距離計算する
    hash.each{|name,address|
     target_library = yolp.coordinate(address)
      dist_=yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])
        hash2[hash[name]]=dist_  #hashとhash2の二重ハッシュ｛図書館の名前＝＞｛図書館の住所＝＞基準との距離｝｝
    }
    temp= []
    temp=hash2.sort {|(k1, v1), (k2, v2)| v1 <=> v2 }#距離順でソートしたのを配列に
    array_order=[]
    for n in temp do
      # p n[0]
      # p hash.invert[n[0]]
      array_order.push(hash.invert[n[0]])  #ソートした距離から図書館の名前を取り出している
    end

  return array_order
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

def get_library_name(key_w)               #本のIDが引数として与えられる
  baseidURL = "https://ci.nii.ac.jp/ncid/"+key_w+".json"
  target= baseidURL.gsub(/^http:/,"https:")
  reHash={}
  open(target){|f|
    hash = JSON.load(f)
    i = 1
    for n in hash["@graph"][0]["bibo:owner"] do
      reHash.store("#{n["foaf:name"]}", get_adrress(n["@id"]))    #図書館の名前=>住所でハッシュ
      i +=1
    end
  }
  return reHash
end
