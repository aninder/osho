# encoding: ISO-8859-1
require 'pry'
require 'ostruct'
require 'table_print'
require 'thor'
require 'logger'

module Kernel
  def try(method, str)
    if self.is_a? Date
      send(method, str)
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

  desc "parse", "parse discources"
  def parse2
    @books=[];
    path=File.expand_path("~/Documents/Osho/files")+"/"
    Dir["#{path}**/*.txt"].each do |f|
      content=File.read(f, external_encoding: "ISO8859-1")
      f = f.partition(path)[2]
      f.match(/^([0-9]\. )([a-zA-Z]+)\/(.*?)- (.*)/)
      match_date = $3
      book = OpenStruct.new(category: $2, name: $4.sub(/\.txt/, ""), content: content)
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
      if (!book.date.is_a?(Date) && !(book.date =~ /0000/))
        @books_compilation ||= []
        @books_compilation << book
      elsif !book.date.is_a?(Date) && book.date =~ /0000/
        @books_meta ||= []
        @books_meta << book
      else
        @books_real ||= []
        @books_real << book
      end
    end
    @books_compilation.each do |book|
      content=book.content.split(/\n|\. /).delete_if { |d| d=~/^\s*$/ }
      content.each do |l|
        if l =~ /^\*\*\*/
          @log.debug "skipping                  #{l}"
          next
        else
          _find(l.chomp, book)
        end
      end
    end
  end

  desc "", ""
  def _find(line, orgbook)
    line2=line.gsub(/([a-zA-Z])(?:\x85|\x97)([a-zA-Z])/, '\1 -- \2')
    line2 = line2.split(/\.*(?:\x85|\x97|\xA0)+[\S]+[0-9]{1,2}$|(?:\x85|\x97|\xA0)\.$|\.$|(?:\x85|\x97|\xA0)/)[0]
    @books_real.each do |b|
      content2=b.content.split("\n").delete_if { |d| d=~/^\s*$/ }
      content2.each do |l|
        if l.chomp.upcase.include? line2.upcase
          @log.debug "#{orgbook.name}  -- line_found in #{b.name.co_fg_magenta}"
          @log.debug "#{line.co_bg_gray.co_fg_black} "
          @log.debug "matched line #{l.chomp.gsub(line2,line2.co_bg_gray.co_fg_black)}"
          @log.debug "===="
          @log.debug "===="
          @log.debug "===="
          # move the book in which the line was found to the top for faster search
          bb = @books_real.delete(b)
          @books_real.unshift(bb)
          return
        end
      end
    end
    @log.debug "line not found #{line.co_fg_red}"
    @log.debug "line not found #{line2.co_fg_red}"
    @log.debug "===="
  end

  desc "parse", "parse discources"

  def parse
    @books=[];
    load_parse_books
    @books.each do |book|
      book.chapters = []
      content=book.content.split("\n").delete_if { |d| d=~/^\s*$/ }
      content.each_with_index do |l, index|
        # beginning of book
        if (l=~/^\s*Video:.*$/) && (content[index-9].chomp =~ /Chapter[s]*$/ ||
            content[index-10].chomp =~ /Chapter[s]*$/ ||
            content[index-11].chomp =~ /Chapter[s]*$/ ||
            content[index-12].chomp =~ /Chapter[s]*$/)
          # log_chapter_parsing(content, index, true)
          if index==12
            book.book_title = content[index-13]
            #     summary missing
            book.dates = content[index-11]
            book.language = content[index-10]
            book.total_chapters = content[index-9]
            book.pubdate = content[index-8]
            #     comments missing
          end
          if index==13
            book.book_title = content[index-13]
            book.summary = content[index-12]
            book.dates = content[index-11]
            book.language = content[index-10]
            book.total_chapters = content[index-9]
            book.pubdate = content[index-8]
            #     comments missing
          end
          if index==14
            book.book_title = content[index-14]
            book.summary = content[index-13]
            book.dates = content[index-12]
            book.language = content[index-11]
            book.total_chapters = content[index-10]
            book.pubdate = content[index-9]
            book.comments = content[index-8]
          end
          chapter = OpenStruct.new
          chapter.book = book
          book.chapters << chapter
          chapter.book_title2 = content[index-8]
          chapter.number = content[index-7]
          chapter.title = content[index-6]
          chapter.date = content[index-5]
          chapter.archive_code = content[index-4]
          chapter.short_title = content[index-3]
          chapter.audio = content[index-2]
          chapter.video = content[index-1]
          chapter.video = content[index]
          if content[index+1] =~ /^\s*Length:.*$/
            chapter.lenght = content[index+1]
          end
          # chapters in a book
          if (l=~/^\s*Video:.*$/) && (content[index-9] !~ /^Chapter/ && content[index-10] !~ /^Chapter/)
            # log_chapter_parsing(content, index, false)
          end
        end
      end
    end
    @books.each do |book|
      if book.chapters.size == 0
        # content=book.content.split("\n").delete_if { |d| d=~/^\s*$/ }
        # content.each_with_index do |l, index|
        # binding.pry if (l=~/^\s*Video:.*$/)
        # @log.debug "-----------------> #{book.name}"
      end
    end
    # tp(@books, :name, :date, :category, :content)
  end

  desc "search SOMETHING CONTEXT", "free text search osho"
  method_option :context, type: :numeric, desc: "num of trailing n succeding context", default: 0, aliases: "-C"
  method_option :sortasc, type: :boolean, default: false, desc: "sort result in order", aliases: "-a"

  def search(something)
    parse

    @books_without_date, @books = @books.partition { |b| b.date.is_a? String }
    options[:sortasc] ? @books.sort_by! { |b| b.date } : @books.sort_by! { |b| b.date }.reverse!
    @books_without_date.sort_by! { |b| b.date }

    @books_without_date.each do |b|
      find_it(b, something)
    end
    @books.each do |b|
      find_it(b, something)
    end
  end

  private
  def load_parse_books
    path=File.expand_path("~/Documents/Osho/files")+"/"
    Dir["#{path}**/*.txt"].each do |f|
      content=File.read(f).force_encoding("iso-8859-1")
      f = f.partition(path)[2]
      f.match(/^([0-9]\. )([a-zA-Z]+)\/(.*?)- (.*)/)
      match_date = $3
      book = OpenStruct.new(category: $2, name: $4.sub(/\.txt/, ""), content: content)
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
  end

  def find_it(b, something)
    co=b.content.split("\n").delete_if { |d| d=~/^\s*$/ }
    co.each_with_index do |l, index|
      if l=~ /#{something}/i
        @log.info("#{b.name.purple} #{b.date.try(:strftime, "%B %d, %Y").gray}");
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
        @log.info("#{(trailing+(l)+succeeding).gsub(/(#{something})/i, '\1'.redish)}")
        @log.info "\n"
      end
    end
  end

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
  end
end

Osho.start(ARGV)