require 'strscan'

class Tracksperanto::Import::ShakeScript < Tracksperanto::Import::Base
  
  # Since Shake uses a C-like language for it's scripts we rig up a very sloppy
  # but concise C-like parser to cope
  class Lexer
    
    EndSubexpr = RuntimeError
    
    attr_reader :stack
    
    def initialize(with_io)
      @io, @stack, @buf  = with_io, [], ''
      begin
        parse until @io.eof?
      rescue EndSubexpr
      end
      in_comment? ? consume_comment!("\n") : consume_atom!
    end
    
    private
    
    def in_comment?
      (@buf =~ /^(\s+?)\/\//) ? true : false
    end
    
    def buf_has_data?
      @buf.strip.empty?
    end
    
    def consume_comment!(c)
      if c == "\n" # Comment
        @stack << [:comment, @buf.gsub(/(\s+?)\/\/{1}/, '')]
        @buf = ''
      else
        @buf << c
      end
    end
    
    def parse
      c = @io.read(1)
      return consume_comment!(c) if in_comment? 
      
      if !@buf.empty? && (c == "(") # Funcall
        @stack << ([:funcall, @buf.strip] + self.class.new(@io).stack)
        @buf = ''
      elsif c == "[" # Array, booring
        @stack << ([:arr] + self.class.new(@io).stack)
      elsif (c == "]" || c == ")")
        # Funcall end, and when it happens assume we are called as
        # a subexpression.
        consume_atom!
        raise EndSubexpr
      elsif (c == ",")
        consume_atom!
      elsif (c == ";")
        # Skip this one
      elsif (c == "\n")
        # Skip too
      elsif (c == "=")
        handle_assignment
      else
        @buf << c
      end
    end
    
    INT_ATOM = /^(\d+)$/
    FLOAT_ATOM = /^([\-\d\.]+)$/
    STR_ATOM = /^\"/
    AT_ATOM = /^([\-\d\.]+)@([\-\d\.]+)$/
    VAR_ASSIGN = /^([\w_]+)(\s+?)\=(\s+?)(.+)/

    def handle_assignment
      @stack << [:var, @buf.strip]
      @stack << [:eq]
      @buf = ''
    end
    
    # Grab the minimum atomic value
    def consume_atom!
      at = @buf
      @buf = ''
      return if at.strip.empty?
      
      the_atom = if at.strip =~ INT_ATOM
        [:atom_i, at.to_i]
      elsif at.strip =~ STR_ATOM
        [:atom_c, unquote_s(at)]
      elsif at.strip =~ FLOAT_ATOM
        [:atom_f, at.to_f]
      elsif at.strip.empty?
        # whitespace :-)
      elsif at.strip =~ AT_ATOM
        v, f = at.strip.split("@")
        [:atom_f_at, v.to_f, f.to_i]
      elsif at.strip =~ VAR_ASSIGN
        [:equals, $1]
      else
        [:atom, at]
      end
      
      @stack << the_atom unless the_atom.nil?
    end
    
    def unquote_s(string)
      string.strip.gsub(/^\"/, '').gsub(/\"$/, '').gsub(/\\\"/, '"')
    end
  end
  
  
  def parse(script_io)
  end
end