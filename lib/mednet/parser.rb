# -*- coding: utf-8 -*-
require 'htmlentities'
require 'ostruct'

module Mednet
  class Parser

    FEAST_MODE  = 0
    ATTRS_MODE   = 1
    SOURCE_MODE = 2

    TYPOS = {
      'achoret' => 'anchoret',
      'abbes' => 'abbess'
    }

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

    SOURCES = %w{ HBD BLS GTZ MR PCP WTS HCC PRI 6028 common }

    PUNCTUATION = [ :open_tag,
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

    ATTRIBUTES = [ 'a boy',
                   'abbes',
                   'abbess',
                   'abbot',
                   'abbots',
                   'achoret',
                   'anchoress',
                   'anchoret',
                   'anchorite',
                   'apostle',
                   'apostles',
                   'archangel',
                   'archdeacon',
                   'bishop',
                   'bishops',
                   'canon',
                   'cardinal',
                   'confessor',
                   'confessors',
                   'count',
                   'countess',
                   'deacon',
                   'disciple of Christ',
                   'duchess',
                   'duke',
                   'earl',
                   'emperor',
                   'empress',
                   'evangelist',
                   'friar',
                   'hermit',
                   'king',
                   'lector',
                   'marquis',
                   'martyr',
                   'martyrs',
                   'matron',
                   'monk',
                   'natale',
                   'nun',
                   'patriarchs',
                   'penitent',
                   'pope',
                   'popes',
                   'priest',
                   'priests',
                   'prince',
                   'prior',
                   'proconsul',
                   'prophet',
                   'protomartyr',
                   'queen',
                   'recluse',
                   'soldier',
                   'subdeacon',
                   'virgin',
                   'virgins',
                   'widow'
                 ]


    def parse line
      raise "Can't parse nil" if line.nil?
      lexed = lex_line line
      parsed_line = build_sections lexed
    end

    # Split line into words and punctuation
    def lex_line line
      s = HTMLEntities.new.decode line.strip
      s.chars.chunk{ |c|
        case c
        when /\n/ then :endline
        when /</  then :open_tag
        when />/  then :close_tag
        when /\(/ then :open_paren
        when /\)/ then :close_paren
        when /:/  then :colon
        when /;/  then :semi_colon
        when /\./ then :period
        when /\w/ then :word
        when /,/  then :comma
        when /\[/ then :open_bracket
        when /\]/ then :close_bracket
        end
      }.map { |seg|
        seg[1] = seg.last.join
        seg
      }
    end

    def remove_tag lexed_line
      # puts lexed_line.inspect
      loop do
        (curr = lexed_line.shift).first == :close_tag and break
      end
    end

    def build_sections lexed_line
      name = []
      attrs = []
      sources = []

      state = FEAST_MODE
      while lexed_line.size > 0
        type, value = lexed_line.first
        case
        when type == :open_tag
          remove_tag lexed_line
        when state == FEAST_MODE && type == :word
          name = extract_feast lexed_line
          state = ATTRS_MODE
        when state == ATTRS_MODE
          attrs = extract_attrs lexed_line
          state = SOURCE_MODE
        when state == SOURCE_MODE
          sources = extract_sources lexed_line
        end
      end
      OpenStruct.new name: name, attrs: attrs, sources: sources
    end

    def extract_feast lexed_line
      feast  = []
      loop do
        type, value = lexed_line.first
        if type == :word
          feast << value
          lexed_line.shift
        elsif attribute_next? lexed_line
          break
        elsif source_next? lexed_line
          break
        else
          feast << value
          lexed_line.shift
        end
        # if there's nothing left, bail
        break if lexed_line.size == 0
      end
      format *feast
    end

    def extract_attrs lexed_line
      attrs = []
      curr_attr = []
      loop do
        type, value = lexed_line.first
        # puts "extract_attrs type: #{type.inspect} value: #{value}"
        if ATTRIBUTES.include? value
          curr_attr << value
          lexed_line.shift
        elsif source_next? lexed_line
          attrs << format(*curr_attr) if curr_attr.size > 0
          break
        elsif attribute_next? lexed_line
          attrs << format(*curr_attr) if curr_attr.size > 0
          curr_attr.clear
          lexed_line.shift
        else
          curr_attr << value
          lexed_line.shift
        # elsif PUNCTUATION.include? type
        #   attrs << curr_attr.join(' ')
        #   curr_attr.clear
        #   lexed_line.shift
        end
        break if lexed_line.size == 0
      end
      attrs
    end

    def extract_sources lexed_line
      sources = []
      # consume the rest of the line
      while lexed_line.size > 0
        type, value = lexed_line.shift
        sources << value if type == :word && SOURCES.include?(value)
      end
      sources
    end

    def attribute_next? lexed_line
      lexed_line[0,2].any? { |token|
        type, value = token
        case
        when PUNCTUATION.include?(type)
          # do nothing
        when type == :word && ATTRIBUTES.include?(value)
          true
        end
      }
    end

    def source_next? lexed_line
      lexed_line[0,2].any? { |token|
        type, value = token
        case
        when PUNCTUATION.include?(type)
          # do nothing
        when type == :word && SOURCES.include?(value)
          true
        end
      }
    end

    def format *strings
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
  end
end
