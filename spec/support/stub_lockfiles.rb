
def stub_lockfiles(format)
  files = ['files/Cheffile.lock']
  files.each do |cf|
    path = create_folder(cf)
    ::FakeFS.deactivate!
    data = load_file(cf, :yaml)
    ::FakeFS.activate!
    pp "using fakefs: #{path}"
    write(path, data, :yaml)
  end
end

private

def root
  @root ||= Pathname.new(__FILE__).dirname
end

def create_folder(loc)
  d = ( root + loc)
  FileUtils.mkdir_p(d.dirname)
  return d
end

def load_file(loc, format)
  fn = root + 'files' + loc
  hash = nil
  f = File.open(fn.to_s, 'r')
  hash =  case format
            when :yaml || :yml || 'yaml' || 'yml'
              ::YAML.load(f.read)
            else
              nil
          end
  return hash
end
