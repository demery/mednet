module Mednet
  class Year
    attr_accessor :file

    MONTHS =  %w{
        January
        February
        March
        April
        May
        June
        July
        August
        September
        October
        November
        December
    }

    MONTH_REGEX = /#{MONTHS.join('|')}/

    DAY_REGEX = /name="\d+">(#{MONTHS.join('|')})\s+(\d{1,2})/

    def initialize file
      @file  = file
      @month = nil
      @day   = nil
    end

    def date
      OpenStruct.new month: @month, day: @day
    end

    def each_feast_line
      return enum_for(:each) unless block_given?

      File.open file, 'r' do |f|
        f.each do |line|
          if line =~ DAY_REGEX
            @month = $1
            @day   = $2
          elsif line =~ /^\s*<br>(.*)$/
            yield line
          end
        end
      end
    end

    def each_feast
      count = 0
      each_feast_line do |feast_line|
        feast       = Feast.new.parse feast_line
        feast.month = date.month
        feast.day   = date.day
        feast.line  = feast_line
        yield feast
      end
    end
  end
end
