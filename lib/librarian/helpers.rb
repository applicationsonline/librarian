module Librarian

  # PRIVATE
  #
  # Adapters must not rely on these methods since they will change.
  #
  # Adapters requiring similar methods ought to re-implement them.
  module Helpers
    extend self

    # [active_support/core_ext/string/strip]
    def strip_heredoc(string)
      indent = string.scan(/^[ \t]*(?=\S)/).min
      indent = indent.respond_to?(:size) ? indent.size : 0
      string.gsub(/^[ \t]{#{indent}}/, '')
    end

    # [active_support/inflector/methods]
    def camel_cased_to_dasherized(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1-\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1-\2')
      word.downcase!
      word
    end

  end

end
