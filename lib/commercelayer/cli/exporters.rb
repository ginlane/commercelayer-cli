require_relative "exporters/contentful"

module Commercelayer
  module CLI
    module Exporters

      def export_data!(destination)
        commercelayer_client.authorize!
        case destination
        when "contentful"
          if yes? "Warning: this will export your SKUs to Contentful. Continue?", :yellow
            say "Exporting SKUs to Contentful...", :blue
            Contentful.new.export!
          else
            say "Nothing to do here. Bye!", :blue
          end
        else
          say "coming soon...", :yellow
        end
      end

    end
  end
end
