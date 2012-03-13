require 'yaml'

module Okura
  module Serializer
    class FormatInfo
      attr_accessor :word_dic
      attr_accessor :unk_dic
      attr_accessor :features
      attr_accessor :char_types
      attr_accessor :matrix

      def compile io
        YAML.dump({
          word_dic: word_dic,
          unk_dic: unk_dic,
          features: features,
          char_types: char_types,
          matrix: matrix
        },io)
      end
      def self.load io
        data=YAML.load(io)
        fi=FormatInfo.new
        fi.word_dic=data[:word_dic]
        fi.unk_dic=data[:unk_dic]
        fi.features=data[:features]
        fi.char_types=data[:char_types]
        fi.matrix=data[:matrix]
        fi
      end
    end
    module Features
      class Marshal
        def compile(input,output)
          parser=Okura::Parser::Feature.new input
          features=Okura::Features.new
          parser.each{|id,text|
            features.add id,text
          }
          ::Marshal.dump(features,output)
        end
        def load(io)
          ::Marshal.load(io)
        end
      end
    end
    module WordDic
      class Naive
        def compile(features,input,output)
          parser=Okura::Parser::Word.new(input)
          dic=Okura::WordDic::Naive.new
          parser.each{|surface,lid,rid,cost|
            word=Okura::Word.new(
              surface,
              features.from_id(lid),
              features.from_id(rid),
              cost
            )
            dic.define word
          }
          Marshal.dump(dic,output)
        end
        def load(io)
          Marshal.load(io)
        end
      end
      class DoubleArray
        def compile(features,input,output)
          parser=Okura::Parser::Word.new(input)
          dic=Okura::WordDic::DoubleArray::Builder.new
          parser.each{|surface,lid,rid,cost|
            word=Okura::Word.new(
              surface,
              features.from_id(lid),
              features.from_id(rid),
              cost
            )
            dic.define word
          }
          data=dic.data_for_serialize
          Marshal.dump(data,output)
        end
        def load(io)
          data=Marshal.load(io)
          Okura::WordDic::DoubleArray::Builder.build_from_serialized data
        end
      end
    end
    module CharTypes
      class Marshal
        def compile(input,output)
          cts=Okura::CharTypes.new

          parser=Okura::Parser::CharType.new
          parser.on_chartype_def{|name,invoke,group,length|
            cts.define_type(name,invoke,group,length)
          }
          parser.on_mapping_single{|char,type,ctypes|
            cts.define_map char,cts.named(type),ctypes.map{|ct|cts.named(ct)}
          }
          parser.on_mapping_range{|from,to,type,ctypes|
            (from..to).each{|char|
              cts.define_map char,cts.named(type),ctypes.map{|ct|cts.named(ct)}
            }
          }
          parser.parse_all input

          ::Marshal.dump(cts,output)
        end
        def load(io)
          ::Marshal.load(io)
        end
      end
    end
    module UnkDic
      class Marshal
        def compile(char_types,features,input,output)
          unk=Okura::UnkDic.new char_types
          parser=Okura::Parser::UnkDic.new input
          parser.each{|type_name,lid,rid,cost|
            unk.define type_name,features.from_id(lid),features.from_id(rid),cost
          }
          ::Marshal.dump(unk,output)
        end
        def load(io)
          ::Marshal.load(io)
        end
      end
    end
  end
end