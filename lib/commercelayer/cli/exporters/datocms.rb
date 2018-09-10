module Commercelayer
  module CLI
    module Exporters
      class DatoCMS

        include Helpers

        def initialize(options={})
          puts "Clearing item types..."
          client.item_types.all.each do |item_type|
            client.item_types.destroy(item_type[:id])
          end
          puts "Clearing uploads..."
          client.uploads.all.each do |upload|
            client.uploads.destroy(upload[:id])
          end
        end

        def export!
          create_product_model!
          create_variant_model!
          create_product_model_fields!
          create_variant_model_fields!
          create_records!
        end

        private
        def create_product_model!
          puts "Creating product model..."
          @product_model = client.item_types.create({
            api_key: "product",
            name: "Product",
            singleton: false,
            all_locales_required: false,
            sortable: true,
            modular_block: false,
            draft_mode_active: false,
            tree: false,
            ordering_direction: nil,
            ordering_field: nil
          })
        end

        def create_variant_model!
          puts "Creating variant model..."
          @variant_model = client.item_types.create({
            api_key: "variant",
            name: "Variant",
            singleton: false,
            all_locales_required: false,
            sortable: true,
            modular_block: false,
            draft_mode_active: false,
            tree: false,
            ordering_direction: nil,
            ordering_field: nil
          })
        end

        def create_product_model_fields!
          puts "Creating product model fields..."
          product_model_fields.each do |api_key, options|
            client.fields.create(@product_model[:id], {
              api_key: api_key,
              appeareance: options[:appeareance],
              default_value: nil,
              field_type: options[:field_type],
              hint: options[:hint],
              label: options[:label],
              localized: false,
              position: options[:position],
              validators: options[:validators]
            })
          end
        end

        def create_variant_model_fields!
          puts "Creating variant model fields..."
          variant_model_fields.each do |api_key, options|
            client.fields.create(@variant_model[:id], {
              api_key: api_key,
              appeareance: options[:appeareance],
              default_value: nil,
              field_type: options[:field_type],
              hint: options[:hint],
              label: options[:label],
              localized: false,
              position: options[:position],
              validators: options[:validators]
            })
          end
        end

        def product_model_fields
          {
            reference: {
              label: "Reference",
              field_type: "string",
              hint: "The product's reference",
              position: 1,
              validators: {
                required: {},
                unique: {}
              },
              appeareance: {
                editor: "single_line",
                parameters: {}
              }
            },
            variants: {
              label: "Variants",
              field_type: "links",
              hint: "The product's variants",
              position: 2,
              validators: { items_item_type: { item_types: [@variant_model[:id]] } },
              appeareance: {
                editor: "links_select",
                parameters: {}
              }
            }
          }
        end

        def variant_model_fields
          {
            code: {
              label: "Code",
              field_type: "string",
              hint: "The variant's code",
              position: 1,
              validators: {
                required: {},
                unique: {}
              },
              appeareance: {
                editor: "single_line",
                parameters: {}
              }
            },
            name: {
              label: "Name",
              field_type: "string",
              hint: "The variant's name",
              position: 2,
              validators: {
                required: {},
                unique: {}
              },
              appeareance: {
                editor: "single_line",
                parameters: {}
              }
            },
            description: {
              label: "Description",
              field_type: "text",
              hint: "The variant's description",
              position: 3,
              validators: {},
              appeareance: {
                editor: "markdown",
                parameters: {
                  "toolbar" => ["heading", "bold", "italic", "strikethrough", "unordered_list", "ordered_list", "quote", "link", "image", "fullscreen"]
                }
              }
            },
            image: {
              label: "Image",
              field_type: "file",
              hint: "The variant's image",
              position: 4,
              validators: {},
              appeareance: {
                editor: "file",
                parameters: {}
              }
            }
          }
        end

        def create_records!
          last_product_reference = nil
          last_product_id = nil
          last_product_variants = []
          Commercelayer::Sku.order(:reference).all.each_total do |sku|
            puts "> #{sku.code}"
            if sku.reference != last_product_reference
              if last_product_id
                client.items.update(last_product_id, {
                  reference: last_product_reference,
                  variants: last_product_variants
                })
                last_product_variants = []
              end

              begin
                product = client.items.create({
                  item_type: @product_model[:id],
                  reference: sku.reference,
                  variants: []
                })
                last_product_reference = sku.reference
                last_product_id = product[:id]
              rescue => e
                puts e.inspect
                break
              end
            end

            begin
              variant = client.items.create({
                item_type: @variant_model[:id],
                code: sku.code,
                name: sku.name,
                description: sku.description,
                image: client.upload_image(sku.image_url.split("?").first)
              })
              last_product_variants << variant[:id]
            rescue => e
              puts e.inspect
              break
            end
          end
        end

        def client
          Dato::Site::Client.new(config_data[:dato][:api_key])
        end

      end
    end
  end
end
