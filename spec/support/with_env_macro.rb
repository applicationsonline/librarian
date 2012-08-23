module WithEnvMacro

  module ClassMethods

    def with_env(new)
      old = Hash[new.map{|k, v| [k, ENV[k]]}]

      before { ENV.update(new) }
      after  { ENV.update(old) }
    end

  end

  private

  def self.included(base)
    base.extend(ClassMethods)
  end

end
