# -*- coding: utf-8 -*-
require 'htmlentities'
require 'ostruct'
require 'pp'

module Mednet
  class Feast

    FEAST_MODE  = 0
    ATTRS_MODE  = 1
    MODS_MODE   = 2
    SOURCE_MODE = 4

    # The various abbreviations that appear in the entry above
    # indicate the sources from which the information was drawn. The
    # sources consulted for this project were:
    #
    #     HBD: F.G. Holweck, A Biographical Dictionary of the Saints
    #     (St. Louis: B. Herder, 1924. Reprint. Detroit: Gale
    #     Research, 1969).
    #
    #     BLS: Alban Butler, The Lives of the Fathers, Martyrs, and
    #     other Principal Saints (London: Virtue, [1936?]).
    #
    #     GTZ: Hermann Grotefend, Taschenbuch der Zeitrechnung des
    #     Deutschen Mittelalters und der Neuzeit, 10th edition
    #     (Hannover: Hahnsche Buchhandlung, 1960). See online version.
    #
    #     MR: Missale Romanum (Vatican City: Libreria Editrice
    #     Vaticana, 1975).
    #
    #     PCP: Paul Perdrizet, Le Calendrier Parisien à la fin du
    #     moyen âge, d'après le bréviaire et les livres d'heures
    #     (Paris: Les Belles Lettres, 1933).
    #
    #     WTS: Roger Wieck, Time Sanctified: The Book of Hours in
    #     Medieval Art and Life (New York: George Braziller, in
    #     association with the Walters Art Gallery, Baltimore, 1988).
    #
    # Some entries still contain references to sources used in an
    # experimental phase of this project. These are:
    #
    #
    #     HCC: The Hours of Catherine of Cleves, introduction and
    #     commentaries by John Plummer (New York: George Braziller,
    #     n.d.).
    #
    #     PRI: The Primer, or Office of the Blessed Virgin Mary, in
    #     Latin and English (Antwerp: Arnold Conings, 1599).
    #
    #     6082: Biblioteca Apostolica Vaticana, Vat. lat. 6082, a
    #     twelfth-century Benedictine manuscript from southern Italy.
    #
    # If a feast is listed as "common," that means that it appears on
    # that date in most of the sources consulted. If no source is
    # given for a particular listing, that means the feast is pretty
    # much universal.
    SOURCES = %w{ HBD BLS GTZ MR PCP WTS HCC PRI 6082 common }

    # ATTRIBUTES does not include typos: achoret, abbes
    # see the TYPOS hash below, which has corrections
    ATTRIBUTES =  %w{
      Doctors
      abbess
      abbot
      abbots
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

    MODS = %w{
      Advent
      Assumption
      Beheading
      Candlemass
      Canonization
      Commemoration
      Conception
      Conversion
      Death
      Deposition
      Display
      Elevation
      Exceptio
      Impression
      Ingression
      Invention
      Miracle
      Nativity
      Obitus
      Octave
      Ordination
      Portatio
      Purification
      Reception
      Recollection
      Relatio
      Revelation
      Subvention
      Transitus
      Translation
      Vigil
    }

    ATTRIBUTES_REGEX = /#{ATTRIBUTES.join('|')}/

    MODS_REGEX       = /#{MODS.join('|')}/

    SOURCES_REGEX    = /^#{SOURCES.join('|')}$/

    # punctuation token types
    PUNCTUATION      = [ :open_tag,
                         :close_tag,
                         :open_paren,
                         :close_paren,
                         :open_bracket,
                         :close_bracket,
                         :colon,
                         :semi_colon,
                         :period,
                         :comma
                       ]

    # word token types
    WORDS            = [ :attribute,
                         :source,
                         :mod,
                         :word
                       ]

    TYPOS = { 'achoret' => 'anchoret', 'abbes' => 'abbess' }

    def parse line
      raise "Can't parse nil" if line.nil?
      lexed = lex_line line
      parsed_line = build_sections lexed
    end

    # Split line into words and punctuation
    def lex_line line
      s = HTMLEntities.new.decode line.strip
      s.scan(/[[:alpha:]]+|[[:punct:]<>]/).map { |x|
        fix_typo(x) # fix any typos
      }.chunk{ |token|
        case token
        when /\n/             then :endline
        when /</              then :open_tag
        when />/              then :close_tag
        when /\(/             then :open_paren
        when /\)/             then :close_paren
        when /:/              then :colon
        when /;/              then :semi_colon
        when /\./             then :period
        when /,/              then :comma
        when /\[/             then :open_bracket
        when /\]/             then :close_bracket
        when 'of'             then :of
        when 'and'            then :and
        when ATTRIBUTES_REGEX then :attribute
        when SOURCES_REGEX    then :source
        when MODS_REGEX       then :mod
        when /[[:alpha:]]+/             then :word
        end
      }.to_a
    end

    def remove_tag lexed_line
      loop do
        (curr = lexed_line.shift).first == :close_tag and break
      end
    end

    def build_sections lexed_line
      name = []
      attrs = []
      sources = []
      mods = []
      state = FEAST_MODE
      while lexed_line.size > 0
        type, token = lexed_line.first
        case
        when type == :open_tag
          remove_tag lexed_line
        when state == FEAST_MODE
          name = extract_feast lexed_line
          state = ATTRS_MODE
        when state == ATTRS_MODE
          attrs = extract_attrs lexed_line
          state = MODS_MODE
        when state == MODS_MODE
          mods = extract_mods lexed_line
          state = SOURCE_MODE
        when state == SOURCE_MODE
          sources = extract_sources lexed_line
        end
      end
      OpenStruct.new name: name, attrs: attrs, mods: mods, sources: sources
    end

    def extract_feast lexed_line
      feast  = []
      loop do
        type, tokens = lexed_line.first
        if attribute_next? lexed_line
          break
        elsif mod_next? lexed_line
          break
        elsif source_next? lexed_line
          break
        elsif type == :open_tag
          remove_tag lexed_line
        else
          tokens.each { |t| feast << t }
          lexed_line.shift
        end
        # if there's nothing left, bail
        break if lexed_line.size == 0
      end
      format feast
    end

    def extract_attrs lexed_line
      attrs = []
      curr_attr = []
      loop do
        type, tokens = lexed_line.first
        if type == :attribute
          tokens.each { |t| curr_attr << t }
          lexed_line.shift
        elsif type == :open_tag
          remove_tag lexed_line
        elsif source_next? lexed_line
          attrs << format(curr_attr) if curr_attr.size > 0
          break
        elsif mod_next? lexed_line
          attrs << format(curr_attr) if curr_attr.size > 0
          break
        elsif attribute_next? lexed_line
          attrs << format(curr_attr) if curr_attr.size > 0
          curr_attr.clear
          lexed_line.shift
        else
          tokens.each { |t| curr_attr << t }
          lexed_line.shift
        end
        break if lexed_line.size == 0
      end
      attrs
    end

    def extract_mods lexed_line
      mods = []
      curr_mod = []
      paren_level = 0
      loop do
        type, tokens = lexed_line.first
        if type == :open_paren
          tokens.each { |t|
            curr_mod << t if paren_level > 0
            paren_level += 1
          }
          lexed_line.shift
        elsif type == :open_tag
          remove_tag lexed_line
        elsif type == :close_paren
          tokens.each { |t|
            curr_mod << t if paren_level > 1
            paren_level -= 1
          }
          lexed_line.shift
        elsif type == :mod
          tokens.each  { |t| curr_mod << t }
          lexed_line.shift
        elsif source_next? lexed_line
            mods << format(curr_mod) if curr_mod.size > 0
          break
        elsif mod_next? lexed_line
          mods << format(curr_mod) if curr_mod.size > 0
          curr_mod.clear
          lexed_line.shift
        else
          tokens.each { |t| curr_mod << t }
          lexed_line.shift
        end
        break if lexed_line.size == 0
      end
      mods
    end

    def extract_sources lexed_line
      sources = []
      # consume the rest of the line
      while lexed_line.size > 0
        type, tokens = lexed_line.shift
        tokens.each { |t| sources << t } if type == :source
      end
      sources
    end

    def attribute_next? lexed_line
      first, second = lexed_line[0,2].map &:first
      [ first, second ] == [ :comma, :attribute ] ||
        [first, second ] == [ :and, :attribute]
    end

    def mod_next? lexed_line
      first, second = lexed_line[0,2].map &:first
      [ first, second ]  == [ :open_paren, :mod ]
    end

    def source_next? lexed_line
      first, second = lexed_line[0,2].map &:first
      [ first, second ]  == [ :open_bracket, :source ]
    end

    def format strings=[]
      strings.reduce([]) { |map,token|
        case token
        when /[\(\[]/ # :no_space_after
          map << token
        when /[,\)\]\.:;]/ # :no_space_before
          map.pop if map.last == ' '
          map << token
          map << ' '
        else # it's a word
          map << token
          map << ' '
        end
      }.join.strip
    end

    # If there's a type for word, return it; otherwise, return word
    def fix_typo word
      TYPOS[word] || word
    end
  end
end
