require 'pry'
require 'ostruct'
require 'table_print'
require 'thor'
class Osho < Thor
  desc "parse","parse discources"
  def parse
    @books=[];
    path=File.expand_path("~/Documents/Osho/files")+"/"
    Dir["#{path}**/*.txt"].each do |f|
      content=File.read(f).force_encoding("iso-8859-1")
      f = f.partition(path)[2]
      f.match(/^([0-9]\. )([a-zA-Z]+)\/(.*?)- (.*)/)
      match_date = $3
      book = OpenStruct.new(category:$2,name:$4.sub(/\.txt/,""),content:content)
      #      binding.pry #if $4.nil?
      begin
        #        binding.pry if book.category=~/compilatio/i
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
        #puts "#{[rand(127744..127891)].pack("U")} #{f}"
      end
      book.date=date
      @books << book
    end
    @books.each do |book|
      content=book.content.split("\n").delete_if {|d| d=~/^\s*$/}
      content.each_with_index do |l,index|
        if l=~/^\s*Length:.*$/ && index < 20
          puts "#{content[index-15].chomp} --- #{index-15}"
          puts "#{content[index-14].chomp} --- #{index-14}"
          puts content[index-13]
          puts content[index-12]
          puts content[index-11]
          puts content[index-10]
          puts content[index-9]
          puts content[index-8]
          puts content[index-7]
          puts content[index-6]
          puts content[index-5]
          puts content[index-4]
          puts content[index-3]
          puts content[index-2]
          puts content[index-1]
          puts content[index]
          puts "\n"
          if index-15==-2
            book.book_title = content[index-14]
            #     summary missing
            book.discourses_dates = content[index-12]
            book.discourslanguage = content[index-11]
            book.discourschapters = content[index-10]
            book.discourspubdate = content[index-9]
            #     comments missing
          end
          if index-15==-1
            book.book_title = content[index-14]
            book.summary = content[index-13]
            book.discourses_dates = content[index-12]
            book.discourslanguage = content[index-11]
            book.discourschapters = content[index-10]
            book.discourspubdate = content[index-9]
            #     comments missing
          end
          if index-15==0
            book.book_title = content[index-15]
            book.summary = content[index-14]
            book.discourses_dates = content[index-13]
            book.discourslanguage = content[index-12]
            book.discourschapters = content[index-11]
            book.discourspubdate = content[index-10]
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
          if l=~/^\s*Length:.*$/ && index > 20
            #          puts content[index-8]
            #          puts content[index-7]
            #          puts content[index-6]
            #          puts content[index-5]
            #          puts content[index-4]
            #          puts content[index-3]
            #          puts content[index-2]
            #          puts content[index-1]
            #          puts ""
          end
        end
      end
    end
    tp(@books,:name,:date,:category,:content)
  end

  desc "search SOMETHING CONTEXT", "free text search osho"
  #  argument :something,:type=>:string,:desc=>"keyword to search"
  #  argument :context,:type=>:numeric,:desc=>"num of trailing n succeding context",:default=>0,:aliases=>"-C"
  def search(something,context=0)
    parse
    @books.each do |b|
      #  puts "checking #{b.name}"
      co=b.content.split("\n").delete_if {|d| d=~/^\s*$/}
      co.each_with_index do |l,index|
        if l=~ /#{something}/i
          puts("#{b.name.purple} #{b.date.strftime("%B %d, %Y").gray}");
          trailing=""
          (1..context).reverse_each do |y|
            trailing+=co[index-y]
            trailing+="\n"
          end
          trailing=~/#{something}/i && next
          succeeding="\n"
          (1..context).each do |y|
            succeeding+=co[index+y] if co[index+y]
            succeeding+="\n"
          end
          puts("#{(trailing+(l)+succeeding).gsub(/#{something}/i,something.redish)}")
          puts "\n"
        end
      end
    end
  end
end
Osho.start(ARGV)
