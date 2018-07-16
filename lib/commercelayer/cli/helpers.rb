module Commercelayer
  module CLI
    module Helpers

      def config_data
        YAML::load_file(config_path).deep_symbolize_keys
      end

      def config_data_template
        {
          "commercelayer" => {
            "site" => "https://<subdomain>.commercelayer.io",
            "client_id" => "YOUR-COMMERCELAYER-CLIENT-ID",
            "client_secret" => "YOUR-COMMERCELAYER-CLIENT-SECRET",
            "scope" => "market:<market_id>",
          },
          "dato" => {
            "api_key" => "YOUR-DATOCMS-APIKEY"
          }
        }.to_yaml
      end

      def config_path
        ENV['HOME'] + "/.commercelayer-cli.yml"
      end

      def commercelayer_client
        Commercelayer::Client.new(
          client_id: config_data[:commercelayer][:client_id],
          client_secret: config_data[:commercelayer][:client_secret],
          scope: config_data[:commercelayer][:scope],
          site: config_data[:commercelayer][:site]
        )
      end      

    end
  end
end
