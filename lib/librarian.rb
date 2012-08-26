require 'librarian/version'
require 'librarian/environment'

module Librarian
  extend self

  def environment_class
    self::Environment
  end

end
