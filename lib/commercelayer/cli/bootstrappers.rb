require_relative "bootstrappers/datocms"

module Commercelayer
  module CLI
    module Bootstrappers

      def bootstrap_data!(destination)
        commercelayer_client.authorize!
        case destination
        when "datocms"
          if yes? "Warning: this will erase your DatoCMS site. Continue?", :yellow
            say "Exporting data to DatoCMS...", :blue
            DatoCMS.new.bootstrap!
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
