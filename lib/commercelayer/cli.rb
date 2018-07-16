require 'thor'
require 'commercelayer'
require 'dato'

require "commercelayer/cli/version"
require "commercelayer/cli/helpers"
require "commercelayer/cli/exporters"

module Commercelayer
  module CLI
    class Base < Thor

      include Helpers
      include Exporters
      include Thor::Actions

      desc "init", "Create a config file under $HOME/.commercelayer-cli.yml"
      def init
        create_file(config_path) do
          config_data_template
        end
      end

      desc "export", "Export data from Commerce Layer to a destination"
      def export
        destination = ask "What is your destination?", limited_to: ["contentful", "datocms", "csv"]
        export_data!(destination)
      end

    end
  end
end
