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

class String
  def trii(mutation, *args)
    xx = send(mutation, *args)
    xx.nil? ? self : xx
  end
end

class Osho < Thor
  def initialize(*args)
    super *args
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = ""
    @log.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
  end

  desc "reconcile", "reconcile discources"
  def reconcile
    @books=[];
    load_books
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
    @books_compilation.shuffle!.each do |book|
      content=book.content.split(/\n|\. /).delete_if { |d| d=~/^\s*$/ }
      content = content[10..-1]
      content.each do |l|
        if (l =~ /^\*\*\*/) || (l.include?("--- End ---"))
          # if !l.include? "Do you feel the way the press report"
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
    @log.debug "searching for #{line.co_fg_gray}"
    line2=line.gsub(/([a-zA-Z])(?:\x85|\x97)([a-zA-Z])/, '\1 \2')
    # line2=line.gsub(/(?:\x85|\x97)/, ' ')
    line2=line2.split(/(?:\x85|\x97|\xA0)+[\S]+[0-9]{1,2}$|(?:\x85|\x97|\xA0)\.$|\.$|(?:\x85|\x97|\xA0)/)[0]
    # line2.sub("([a-z][A-Z]) --","\1...")
    # line2.sub("([a-z][A-Z]) --","\1 ...")
    # line2.gsub!(/(;|\.|,|\*| --| *\.\.\.)/,"")
    line2.gsub!(/;|,|\.|\?|\"|'|:|`/, "")
    @books_real.each do |b|
      content2=b.content.split("\n").delete_if { |d| d=~/^\s*$/ }

      #check next line of last successful hit first
      if @books_real.first == b && b.index && b.index > 0
        puts "checking next line"
        if content2[b.index].upcase.include?(line2.upcase)
          # .chomp.gsub(" --", "").gsub("...", "").gsub(/;|,|\.|\?|\"|`|'|:/, "").upcase.include?(line2.upcase)
          @log.debug "#{orgbook.name}  -- line_found in #{b.name.co_fg_magenta}"
          @log.debug "#{line.co_bg_gray.co_fg_black} "
          @log.debug "matched line #{content2[b.index].gsub(line2, line2.co_bg_gray.co_fg_black)}"
          @log.debug "===="
          @log.debug "===="
          @log.debug "===="

          # optimize search by tracking the index of last search hit n then starting the search from there
          b.index = b.index
          puts "working in current line!!"
          # sleep 3
          return
        elsif content2[b.index+1].trii(:chomp!, nil).trii(:gsub!, " --", "").trii(:gsub!, "...", "").trii(:gsub!, /;|,|\.|\?|\"|`|'|:/, "").upcase.include?(line2.upcase)
          @log.debug "#{orgbook.name}  -- line_found in #{b.name.co_fg_magenta}"
          @log.debug "#{line.co_bg_gray} "
          @log.debug "matched line #{content2[b.index+1].gsub(line2, line2.co_bg_gray)}"
          @log.debug "===="
          @log.debug "===="
          @log.debug "===="

          # optimize search by tracking the index of last search hit n then starting the search from there
          b.index = b.index+1
          puts "working in next line!!"
          # sleep 3
          return
        else
          puts "not found in current n next line"
          # sleep 2
        end
      end
      content2.each_with_index do |l, index|
        l.chomp!
        binding.pry if l.nil?
        l.gsub!(" --", "")
        l.gsub!("...", "")
        l.gsub!(/;|,|\.|\?|\"|`|'|:/, "")
        # gsub!(/;|,|\.|\?|\"|`|'|:| --|.../, "")
        #l.gsub!(/(`([^tsm])|'([^tsm]))/, "\"\1")
        if l.upcase.include? line2.upcase
          @log.debug "#{orgbook.name}  -- line_found in #{b.name.co_fg_magenta}"
          @log.debug "#{line.co_bg_gray.co_fg_black} "
          @log.debug "matched line #{l.gsub(line2, line2.co_bg_gray.co_fg_black)}"
          @log.debug "===="
          @log.debug "===="
          @log.debug "===="

          # optimize search by tracking the index of last search hit n then starting the search from there
          @books_real.first.index = 0
          b.index = index

          # move the book in which the line was found to the top for faster search
          @books_real.delete(b)
          @books_real.unshift(b)
          return
        end
      end
    end
    @log.debug "searching for #{line2.co_fg_red}"
    @log.debug "===="
    sleep 3
  end

  desc "parse", "parse discources"
  def parse
    @books=[];
    load_books
    createDB
    @books.each do |book|
      # if book.chapters.size == 0
      # content=book.content.split("\n").delete_if { |d| d=~/^\s*$/ }
      # content.each_with_index do |l, index|
      # binding.pry if (l=~/^\s*Video:.*$/)
      # @log.debug "-----------------> #{book.name}"
    end
  end

  # tp(@books, :name, :date, :category, :content)

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
  def load_books
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
  end

  def createDB
    @books.each do |book|
      book.chapters = []
      content=book.content.split("\n").delete_if { |d| d=~/^\s*$/ }
      content.each_with_index do |l, index|
        # beginning of book
        if (l=~/^\s*Video:.*$/) && (content[index-9].chomp =~ /Chapter[s]*$/ ||
            content[index-10].chomp =~ /Chapter[s]*$/ ||
            content[index-11].chomp =~ /Chapter[s]*$/ ||
            content[index-12].chomp =~ /Chapter[s]*$/)

          if index==9
            book.book_title = content[index-9]
            book.summary = content[index-8]
            book.dates = content[index-7]
            book.total_chapters = content[index-5]
            book.pubdate = content[index-4]
            book.comments = content[index-3]
            book.language = "Miscellaneous"
          end
          if index==12
            book.book_title = content[index-12]
            #     summary missing
            book.dates = content[index-11]
            if content[index-10] =~ /Darshan Diary/
              #     summary missing
              book.language = "#{content[index-10]} series"
              book.summary = content[index-10]
              book.total_chapters = content[index-9]
              book.pubdate = content[index-8]
              #     comments missing
            else
              if content[index-4] =~ /Chapter title/
                book.summary = content[index-7]
              end
              book.language = content[index-10]
              book.total_chapters = content[index-9]
              book.pubdate = content[index-8]
              #     comments missing
            end
          end
          if index==13
            book.book_title = content[index-13]
            if content[index-12] =~ /Talks given from/
              # summary missing
              book.dates = content[index-12]
              if content[index-11] =~ /Darshan Diary/i
                book.language = "#{content[index-11]} series"
                book.total_chapters = content[index-10]
                book.pubdate = content[index-9]
                book.comments = content[index-8]
              else
                book.language = content[index-11]
                book.total_chapters = content[index-10]
                book.pubdate = content[index-9]
                book.comments = content[index-8]
              end
            else
              book.summary= content[index-12]
              book.dates = content[index-11]
              book.language = content[index-10]
              book.total_chapters = content[index-9]
              book.pubdate = content[index-8]
              #comments missing
            end
          end
          if index==14
            book.book_title = content[index-14]
            if content[index-12] =~ /Talks given from/ || content[index-12] =~ /talks from the early days/
              book.summary = content[index-13]
              book.dates = content[index-12]
              book.language = content[index-11]
              book.total_chapters = content[index-10]
              book.pubdate = content[index-9]
              book.comments = content[index-8]
            else
              #summary missing
              # 2 comments
              book.dates = content[index-13]
              book.language = content[index-12]
              book.total_chapters = content[index-11]
              book.pubdate = content[index-10]
              book.comments = content[index-9]
              book.comments+= '\n'+content[index-8]
            end
          end
          if index==15
            # 2 line comments
            book.book_title = content[index-15]
            book.summary = content[index-14]
            book.dates = content[index-13]
            book.language = content[index-12]
            book.total_chapters = content[index-11]
            book.pubdate = content[index-10]
            book.comments = content[index-9]
            book.comments+= "\n"+content[index-8]
            #     comments missing
          end
          if index==16
            # 3 line comments
            book.book_title = content[index-16]
            book.summary = content[index-15]
            book.dates = content[index-14]
            book.language = content[index-13]
            book.total_chapters = content[index-12]
            book.pubdate = content[index-11]
            book.comments = content[index-10]
            book.comments+= '\n'+content[index-9]
            book.comments = '\n'+content[index-8]
          end
          binding.pry if book.dates !~ /Talks given from/ && book.dates !~ /talks from the early days/
          binding.pry if book.language !~ /series/ && book.language !~ /hindi/i && book.language !~ /Miscellaneous/i
          binding.pry if book.pubdate !~ /published/
          binding.pry if book.total_chapters !~ /Chapter/i
          # binding.pry if book.comments !~ /Chapter/

          # log_chapter_parsing(content, index, true)
        end
        # chapters in a book
        if (l=~/^\s*Video/i) && (content[index-9] !~ /^Chapter/ && content[index-10] !~ /^Chapter/)
          chapter = OpenStruct.new
          chapter.book = book
          book.chapters << chapter
          if index ==5
            chapter.number = content[index-4]
            chapter.title = content[index-3]
            chapter.date = "Date Unknown"
            chapter.archive_code = "no archive code"
            chapter.short_title = content[index-2]
            chapter.audio = content[index-1]
            chapter.video = content[index]
          elsif index == 9
            chapter.title = content[index-6]
            chapter.number = content[index-5]
            chapter.date = content[index-7]
            chapter.archive_code = "no archive code"
            chapter.short_title = content[index-2]
            chapter.audio = content[index-1]
            chapter.video = content[index]
          elsif content[index-4] =~ /Chapter title/
            chapter.book_title2 = content[index-7]
            chapter.number = content[index-5]
            chapter.title = content[index-4]
            chapter.date = "Date Unknown"
            chapter.archive_code = content[index-3]
            chapter.short_title = content[index-2]
            chapter.audio = content[index-1]
            chapter.video = content[index]
          else
            chapter.book_title2 = content[index-7]
            if content[index-6] =~ /Wisdom of Folly/
              chapter.number = "Chapter #0"
            else
              chapter.number = content[index-6]
            end
            chapter.title = content[index-5]
            chapter.date = content[index-4]
            chapter.archive_code = content[index-3]
            chapter.short_title = content[index-2]
            chapter.audio = content[index-1]
            chapter.video = content[index]
          end
          if content[index+1] =~ /^\s*Length:.*$/
            chapter.length = content[index+1]
          end
          @log.debug "#{chapter.title}"
          # sleep 1
          binding.pry if chapter.number !~ /(Chapter|Appendix|Series)/
          binding.pry if chapter.date !~ /(pm|am|January|February|May|June|July|October|September|November|Date [uU]nk[n]*own|Mt. Abu|1972|1984)/
          binding.pry if chapter.archive_code !~ /(archive|1971)/i
          binding.pry if chapter.short_title !~ /shorttitle/i
          binding.pry if chapter.audio !~ /audio/i
          # log_chapter_parsing(content, index, false, chapter)
        end
      end
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

  def log_chapter_parsing(content, index, header, chapter=nil)
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
    @log.debug content[index+1] if content[index+1] =~ /^\s*Length:.*$/
    @log.debug "\n"
    # sleep 0.01
  end

end

Osho.start(ARGV)