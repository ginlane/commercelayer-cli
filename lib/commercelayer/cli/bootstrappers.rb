require_relative "bootstrappers/datocms"
require_relative "bootstrappers/contentful"

module Commercelayer
  module CLI
    module Bootstrappers

      def bootstrap_data!(destination)
        commercelayer_client.authorize!
        case destination
        when "datocms"
          if yes? "Warning: this will erase your DatoCMS data. Continue?", :yellow
            say "Exporting data to DatoCMS...", :blue
            DatoCMS.new.bootstrap!
          else
            say "Nothing to do here. Bye!", :blue
          end
        when "contentful"
          if yes? "Warning: this will erase your Contentful data. Continue?", :yellow
            say "Exporting data to Contentful...", :blue
            Contentful.new.bootstrap!
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
