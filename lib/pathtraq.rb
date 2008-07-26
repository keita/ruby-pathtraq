require "open-uri"
require "simple-rss"

module Pathtraq
  VERSION = "000"

  class Item
    attr_reader :title
    attr_reader :link
    attr_reader :description
    attr_reader :hits

    def initialize(data)
      @title = data.title
      @link = data.link
      @description = data.description
      @hits = data.pathtraq_hits.to_i
    end
  end

  class Feed < DelegateClass(Array)
    def self.request(params = {})
      params ||= {}
      new(SimpleRSS.new(Request.new(self::URL, params).send))
    end

    attr_reader :title
    attr_reader :link

    def initialize(data)
      __setobj__([])
      data.channel.items.each do |i|
        self << Item.new(i)
      end
      @title = data.title
      @link = data.link
    end
  end

  class NewsRanking < Feed
    URL = "http://api.pathtraq.com/news_ja"
    PARAMS = [:genre, :m]
    GENRES = [:national, :sports, :business, :politics, :international,
              :academic, :culture ]
    class << self
      GENRES.each do |genre|
        define_method(genre) do |*params|
          params = (params.first || Hash.new)
          params[:genre] = genre
          request(params)
        end
      end
    end
  end

  class CategoryRanking < Feed
    URL = "http://api.pathtraq.com/popular"
    PARAMS = [:category, :m]
    CATEGORIES = [:politics, :business, :society, :showbiz, :music, :movie,
                  :anime, :game, :sports, :motor, :education, :reading,
                  :science, :art, :foods, :travel, :mobile, :computer, :web ]
    class << self
      CATEGORIES.each do |cat|
        define_method(cat) do |*params|
          params = (params.first || Hash.new)
          params[:category] = cat
          request(params)
        end
      end
    end
  end

  class KeywordSearch < Feed
    URL = "http://api.pathtraq.com/pages"
    PARAMS = [:m, :url]
  end

  module PageCounter
    URL = "http://api.pathtraq.com/page_counter"
    PARAMS = [:m, :url]

    def self.request(params)
      params[:api] = "json"
      res = Request.new(URL, params).send
      if md = /count:\s*(\d+)/.match(res)
        md[1].to_i
      else
        raise Error.new(res, params)
      end
    end
  end

  module PageChart
    URL = "http://api.pathtraq.com/page_chart"
    PARAMS = [:url, :scale]

    def self.request(params)
      params[:api] = "json"
      res = Request.new(URL, params).send
      if md = /plots:\s*\[\s*([\d\s,]+)\s*\]/.match(res)
        return md[1].gsub!(" ", "").split(",").map{|s| s.to_i }
      else
        raise Error.new(res, params)
      end
    end

    def self.url(url, scale=:"24h")
      request(:url => url, :scale => scale)
    end
  end

  class Error < StandardError
    def initialize(res, params)
      @result = res
      @params = params
    end

    def message
      "Maybe caused by invalid query: #{@params}"
    end
  end

  class Request
    def initialize(url, params)
      @uri = URI(url)
      @params = params.map {|key, val| "#{key}=#{val}" }.join("&")
      @uri.query = URI.escape(@params) if @params.size > 0
    end

    def send
      STDERR.puts "Pathtraq: request to #{@uri}" if $DEBUG

      begin
        res = @uri.read
        STDERR.puts "#{res.status.join(" ")} #{res.content_type}" if $DEBUG
        return res
      rescue OpenURI::HTTPError
        raise Error.new(res, @params)
      end
    end
  end
end

SimpleRSS.item_tags << :'pathtraq:hits'
