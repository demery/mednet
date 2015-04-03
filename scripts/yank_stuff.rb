#!/usr/bin/env ruby
require 'htmlentities'

ATTRIBUTES =  %w{
      abbes
      abbess
      abbot
      abbots
      achoret
      anchoress
      anchoret
      anchorite
      apostle
      apostles
      archangel
      archdeacon
      bishop
      bishops
      boy
      canon
      cardinal
      confessor
      confessors
      count
      countess
      deacon
      disciple
      duchess
      duke
      earl
      emperor
      empress
      evangelist
      friar
      friars
      hermit
      host
      king
      kings
      lector
      marquis
      martyr
      martyrs
      matron
      monk
      nun
      patriarchs
      penitent
      pope
      popes
      priest
      priests
      prince
      prior
      proconsul
      prophet
      protomartyr
      queen
      recluse
      soldier
      subdeacon
      tribune
      virgin
      virgins
      widow
    }

ATTRIBUTES_REGEX = /#{ATTRIBUTES.join('|')}/i

# ARGF.each do |line|
#   if line =~ /^\s*<br>/
#     s = HTMLEntities.new.decode(line.strip)
#     # trash tags
#     s.gsub!(/<[^>]+>/, '')
#     s.strip!
#     # spit out the brackets
#     s.scan(/\[[^\]]+\]/).each { |x| puts x }
#     # kill any [...]
#     s.gsub!(/\[[^\]]+\]/, '')
#     s.strip!
#     # spit out the parentheticals
#     s.scan(/\([^\)]+\)/).each { |x| puts x }
#     # remove the parentheticals
#     s.gsub! /\([^\)]+\)/, ''
#     s.gsub! /[[:punct:]\s]+/, ' '
#     s.split.each { |x| puts x }
#   end
# end

ARGF.each do |line|
  if line =~ /\(of [A-Z][^\)]*\)/
    puts line.sub /\((of [A-Z][^\)]*)\)/, "<<\\1>>"
    # puts "#{$`}<<#{$&}>>#{$'}"
  end
end
