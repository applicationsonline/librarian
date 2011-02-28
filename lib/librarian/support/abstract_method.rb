module Librarian
  module Support
    module AbstractMethod

      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      module ClassMethods
        def abstract_method(*names)
          names.each do |name, *args|
            define_method(name) { raise Exception, "Method #{self.class.name}##{name} is abstract!" }
          end
        end
      end

    end
  end
end
