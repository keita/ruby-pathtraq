# This spec is written in bacon DSL.
# Please execute the folloing command if you don't know bacon:
#
# % sudo gem install bacon

require "bacon"

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

$KCODE = "UTF-8"

URL = "http://d.hatena.ne.jp/keita_yamaguchi/"

require "pathtraq"
include Pathtraq

shared "feed" do
  it 'should send a request' do
    proc { @feedclass.request(@default_params) }.should.not.raise
  end

  it 'should send a request with parameters' do
    proc do
      @feedclass.request(@parameters)
    end.should.not.raise
  end

  it 'should be an array of items' do
    res = @feedclass.request(@default_params)
    res.should.kind_of Array
    res.each {|item| item.should.kind_of Item }
  end

  it 'should have title and link' do
    feed = @feedclass.request(@default_params)
    feed.title.should.not.nil
    feed.link.should.not.nil
  end
end

describe "Pathtraq::NewsRanking" do
  before do
    @feedclass = NewsRanking
    @parameters = { :m => :hot, :genre => :sports }
  end

  behaves_like "feed"

  it 'should send a request with parameters' do
    proc do
      NewsRanking.request(:m => :hot, :genre => :sports)
    end.should.not.raise
  end

  it 'should be callable by genre' do
    NewsRanking::GENRES.each do |genre|
      proc { NewsRanking.send(genre) }.should.not.raise
    end
  end
end

describe "Pathtraq::CategoryRanking" do
  before do
    @feedclass = CategoryRanking
    @parameters = { :m => :hot, :genre => :politics }
  end

  behaves_like "feed"

  it 'should be callable by category' do
    CategoryRanking::CATEGORIES.each do |cat|
      proc { CategoryRanking.send(cat) }.should.not.raise
    end
  end
end

describe "Pathtraq::KeywordSearch" do
  before do
    @feedclass = KeywordSearch
    @parameters = { :m => :hot, :url => URL }
    @default_params = { :url => "ruby"}
  end

  behaves_like "feed"
end

describe "Pathtraq::PageCounter" do
  it 'should return counter' do
    PageCounter.request(:url => URL).should >= 0
  end
end

describe "Pathtraq::PageChart" do
  it 'should return access numbers' do
    res = PageChart.request(:url => URL)
    res.size.should > 0
    res.each {|i| i.should >=0 }
  end
end
