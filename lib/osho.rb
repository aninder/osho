require 'pry'
require 'ostruct'
require 'table_print'
require 'thor'
require 'logger'

module Kernel
  def try method,str
    if self.is_a? Date
      send(method,str)
    else
      self
    end
  end
end

class Osho < Thor
  def initialize(*args)
    super *args
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  desc "parse","parse discources"
  def parse
    @books=[];
    path=File.expand_path("~/Documents/Osho/files")+"/"
    Dir["#{path}**/*.txt"].each do |f|
      content=File.read(f).force_encoding("iso-8859-1")
      f = f.partition(path)[2]
      f.match(/^([0-9]\. )([a-zA-Z]+)\/(.*?)- (.*)/)
      match_date = $3
      book = OpenStruct.new(category: $2,name: $4.sub(/\.txt/, ""),content: content)
      begin
        if match_date=~/^#/
          date = match_date
        else
          date=DateTime.parse(match_date.rstrip)
        end
      rescue ArgumentError
        if (match_date=~/^0000/)
          date=match_date
        else
          date=Date.new(match_date.to_i)
        end
      end
      book.date=date
      @books << book
    end
    @books.each do |book|
      content=book.content.split("\n").delete_if {|d| d=~/^\s*$/}
      content.each_with_index do |l,index|
        if (l=~/^\s*Length:.*$/) && (content[index-10].chomp =~ /Chapter[s]*$/ || content[index-11].chomp =~ /Chapter[s]*$/)
          log_chapter_parsing(content, index, true)
          if index==13
            book.book_title = content[index-14]
            #     summary missing
            book.dates = content[index-12]
            book.language = content[index-11]
            book.chapters = content[index-10]
            book.pubdate = content[index-9]
            #     comments missing
          end
          if index==14
            book.book_title = content[index-14]
            book.summary = content[index-13]
            book.dates = content[index-12]
            book.language = content[index-11]
            book.chapters = content[index-10]
            book.pubdate = content[index-9]
            #     comments missing
          end
          if index==15
            book.book_title = content[index-15]
            book.summary = content[index-14]
            book.dates = content[index-13]
            book.language = content[index-12]
            book.chapters = content[index-11]
            book.pubdate = content[index-10]
            book.comments = content[index-9]
          end
          book_title2 = content[index-8]
          chapter_number = content[index-7]
          chapter_title = content[index-6]
          chapter_date = content[index-5]
          archive_code = content[index-4]
          short_title =  content[index-3]
          audio = content[index-2]
          video = content[index-1]
          video = content[index]
          #          x=index-15
          #          case x
          #          when -1
          #            sleep 1
          #          when -2
          #            sleep 2
          #          when -3
          #            sleep 5
          #          when x < -3
          #            sleep 100
          #          end
        end
        if (l=~/^\s*Length:.*$/) && (content[index-10] !~ /^Chapter/ && content[index-11] !~ /^Chapter/)
          # log_chapter_parsing(content, index, false)
        end
      end
    end
    # tp(@books, :name, :date, :category, :content)
  end

  desc "search SOMETHING CONTEXT", "free text search osho"
  method_option :context, :type => :numeric, :desc => "num of trailing n succeding context", :default => 0, :aliases => "-C"
  def search(something)
    parse
    @books.each do |b|
      co=b.content.split("\n").delete_if { |d| d=~/^\s*$/ }
      co.each_with_index do |l, index|
        if l=~ /#{something}/i
          puts("#{b.name.purple} #{b.date.try(:strftime, "%B %d, %Y").gray}");
          trailing=""
          (1..options[:context]).reverse_each do |y|
            trailing+=co[index-y]
            trailing+="\n"
          end
          trailing=~/#{something}/i && next
          succeeding="\n"
          (1..options[:context]).each do |y|
            succeeding+=co[index+y] if co[index+y]
            succeeding+="\n"
          end
          puts("#{(trailing+(l)+succeeding).gsub(/#{something}/i, something.redish)}")
          puts "\n"
        end
      end
    end
  end

  private
  def log_chapter_parsing(content, index, header)
    if header
      @log.debug "#{content[index-15].chomp} --- #{(index-15).to_s.co_bg_red}"
      @log.debug "#{content[index-14].chomp} --- #{index-14}"
      @log.debug content[index-13]
      @log.debug content[index-12]
      @log.debug content[index-11]
      @log.debug content[index-10]
      @log.debug content[index-9]
    end
    @log.debug "#{content[index-8].chomp} #{index-8} "
    @log.debug content[index-7]
    @log.debug content[index-6]
    @log.debug content[index-5]
    @log.debug content[index-4]
    @log.debug content[index-3]
    @log.debug content[index-2]
    @log.debug content[index-1]
    @log.debug content[index]
    @log.debug "\n"
    sleep 1
  end
end
Osho.start(ARGV)
