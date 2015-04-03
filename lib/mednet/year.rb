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

    def initialize(file)
      @file = file
    end

    def parse
      feasts = []
      day = nil
      IO.foreach file do |line|
        if line =~ DAY_REGEX
          day = OpenStruct.new month: $1, day: $2
        elsif line.strip =~ /^\s*<br>(.*)$/
          s           = $1
          feast       = Feast.new.parse s
          feast.month = day.month
          feast.day   = day.day
          feast.line  = s
          feasts << feast
        end
      end
      feasts
    end

  end
end
