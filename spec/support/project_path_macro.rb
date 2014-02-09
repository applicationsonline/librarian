module Support
  module ProjectPathMacro

    project_path = Pathname.new(__FILE__).expand_path
    project_path = project_path.dirname until project_path.join("Rakefile").exist?

    PROJECT_PATH = project_path

    def project_path
      PROJECT_PATH
    end

  end
end
