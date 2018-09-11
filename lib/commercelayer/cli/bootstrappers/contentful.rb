module Commercelayer
  module CLI
    module Bootstrappers
      class Contentful

        include Helpers

        def initialize(options={})
          puts "Clearing entries..."
          master.entries.all.each do |entry|
            entry.unpublish if entry.published?
            entry.destroy
          end
          puts "Clearing content types..."
          master.content_types.all.each do |content_type|
            content_type.unpublish if content_type.published?
            content_type.destroy
          end
          puts "Clearing assets..."
          master.assets.all.each do |asset|
            asset.unpublish if asset.published?
            asset.destroy
          end
        end

        def bootstrap!
          create_variant_model!
          create_product_model!
          create_variant_model_fields!
          create_product_model_fields!
          create_records!
        end

        private
        def create_product_model!
          puts "Creating product model..."
          @product_model = master.content_types.create({
            id: "product",
            name: "Product"
          })
        end

        def create_variant_model!
          puts "Creating variant model..."
          @variant_model = master.content_types.create({
            id: "variant",
            name: "Variant"
          })
        end

        def create_product_model_fields!
          puts "Creating product model fields..."
          product_model_fields.each do |id, options|
            @product_model.fields.create({ id: id }.merge(options))
          end
          @product_model.activate
          @product_model.update(displayField: "reference")
          @product_model.activate
        end

        def create_variant_model_fields!
          puts "Creating variant model fields..."
          variant_model_fields.each do |id, options|
            @variant_model.fields.create({ id: id }.merge(options))
          end
          @variant_model.activate
          @variant_model.update(displayField: "name")
          @variant_model.activate
        end

        def product_model_fields
          {
            reference: {
              name: "Reference",
              type: "Symbol",
              required: true,
              validations: [ validation(unique: true) ]
            },
            variants: {
              name: "Variants",
              type: "Array",
              items: link(type: "variant")
            }
          }
        end

        def variant_model_fields
          {
            name: {
              name: "Name",
              type: "Symbol",
              required: true,
              validations: [ validation(unique: true) ]
            },
            code: {
              name: "Code",
              type: "Symbol",
              required: true,
              validations: [ validation(unique: true) ]
            },
            description: {
              name: "Description",
              type: "Text"
            },
            image: {
              name: "Image",
              type: "Link",
              link_type: "Asset",
              validations: [ validation(link_mimetype_group: 'image') ]
            }
          }
        end

        def create_records!
          puts "Creating entries..."
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
                product = @product_model.entries.create({
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
              variant = @variant_model.entries.create({
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

        def client
          ::Contentful::Management::Client.new(config_data[:contentful][:access_token])
        end

        def environments
          @environments ||= client.environments(config_data[:contentful][:space]).all
        end

        def master
          @master ||= environments.find('master').first
        end

        def validation(options={})
          validation = ::Contentful::Management::Validation.new
          options.each do |k,v|
            validation.send("#{k}=", v)
          end
          validation
        end

        def link(options={})
          field = ::Contentful::Management::Field.new
          field.type = "Link"
          field.link_type = "Entry"
          validation = ::Contentful::Management::Validation.new
          validation.link_content_type = [options[:type]]
          field.validations = [validation]
          field
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
