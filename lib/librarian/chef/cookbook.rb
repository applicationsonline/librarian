require 'pathname'
require 'json'
require 'yaml'

module Librarian
  module Chef
    class Cookbook < Dependency

      MANIFESTS = %w(metadata.json metadata.yml metadata.yaml)

      def manifest?(path)
        path = Pathname.new(path)
        manifest_path = MANIFESTS.map{|s| path.join(s)}.select{|s| s.exist?}.first
        manifest_path && check_manifest(manifest_path)
      end

    private

      def check_manifest(manifest_path)
        case manifest_path.extname
        when ".json"
          check_manifest_json(manifest_path)
        when ".yml", ".yaml"
          check_manifest_yaml(manifest_path)
        end
      end

      def check_manifest_json(manifest_path)
        j = JSON.parse(manifest_path.read)
        j["name"] == name
      end

      def check_manifest_yaml(manifest_path)
        y = YAML.load(manifest_path.read)
        y["name"] == name
      end

    end
  end
end
