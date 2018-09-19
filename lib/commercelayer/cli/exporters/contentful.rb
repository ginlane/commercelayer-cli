module Commercelayer
  module CLI
    module Exporters
      class Contentful

        include Helpers

        def export!
          last_product_reference = nil
          last_product_id = nil
          last_product_variants = []
          Commercelayer::Sku.order(:reference).all.each_total do |sku|
            puts "> #{sku.code}"
            if sku.reference != last_product_reference
              if last_product_id
                product = master.entries.find(last_product_id)
                product.update({
                  reference: last_product_reference,
                  variants: last_product_variants
                })
                product.publish
                last_product_variants = []
              end

              begin
                product = product_model.entries.create({
                  reference: sku.reference,
                  variants: []
                })
                last_product_reference = sku.reference
                last_product_id = product.id
              rescue => e
                puts e.inspect
                break
              end
            end

            begin
              variant = variant_model.entries.create({
                code: sku.code,
                name: sku.name,
                description: sku.description,
                image: image(sku)
              })
              variant.publish
              last_product_variants << variant
            rescue => e
              puts e.inspect
              break
            end
          end
        end

        private

        def client
          ::Contentful::Management::Client.new(config_data[:contentful][:access_token])
        end

        def environments
          @environments ||= client.environments(config_data[:contentful][:space]).all
        end

        def master
          @master ||= environments.find('master').first
        end

        def product_model
          @product_model ||= master.content_types.find('product')
        end

        def variant_model
          @variant_model ||= master.content_types.find('variant')
        end

        def image(sku, options={})
          unless sku.image_url.blank?
            image_file = ::Contentful::Management::File.new
            image_file.properties[:contentType] = "image/jpeg"
            image_file.properties[:fileName] = "#{sku.code}.jpg"
            image_file.properties[:upload] = sku.image_url
            image_file
            image_asset = master.assets.create(title: sku.name, file: image_file)
            image_asset.process_file
            image_asset.publish
            image_asset
          end
        end

      end
    end
  end
end
