module RBSProtobuf
  module Translator
    class ProtobufGem < Base
      def initialize(input, upcase_enum:, nested_namespace:)
        super(input)
        @upcase_enum = upcase_enum
        @nested_namespace = nested_namespace
      end

      def upcase_enum?
        @upcase_enum
      end

      def nested_namespace?
        @nested_namespace
      end

      def rbs_content(file)
        decls = []

        source_code_info = file.source_code_info

        if file.package && !file.package.empty?
          package_namespace = message_type(file.package).name.to_namespace
        else
          package_namespace = RBS::Namespace.empty
        end

        prefix = if nested_namespace?
                   RBS::Namespace.empty
                 else
                   package_namespace
                 end

        file.enum_type.each_with_index do |enum, index|
          decls << enum_type_to_decl(enum,
                                     prefix: prefix,
                                     source_code_info: source_code_info,
                                     path: [5, index])
        end

        file.message_type.each_with_index do |message, index|
          decls << message_to_decl(message,
                                   prefix: prefix,
                                   message_path: if package_namespace.empty?
                                                   [message.name.to_sym]
                                                 else
                                                   [file.package.to_sym, message.name.to_sym]
                                                 end,
                                   source_code_info: source_code_info,
                                   path: [4, index])
        end

        file.service.each_with_index do |service, index|
          decls << service_to_decl(service,
                                   prefix: prefix,
                                   source_code_info: source_code_info,
                                   path: [6, index])
        end

        if nested_namespace?
          package_namespace.path.reverse_each do |name|
            decls = [
              RBS::AST::Declarations::Module.new(
                name: factory.type_name(name.to_s),
                self_types: [],
                type_params: factory.module_type_params,
                location: nil,
                comment: nil,
                annotations: [],
                members: decls
              )
            ]
          end
        end

        StringIO.new.tap do |io|
          RBS::Writer.new(out: io).write(decls)
        end.string
      end

      def message_base_class
        RBS::AST::Declarations::Class::Super.new(
          name: RBS::TypeName.new(
            name: :Message,
            namespace: RBS::Namespace.parse("::Protobuf")
          ),
          args: []
        )
      end

      def repeated_field_type(type, wtype = type)
        factory.instance_type(
          factory.type_name("::Protobuf::Field::FieldArray"),
          type,
          wtype
        )
      end

      def message_to_decl(message, prefix:, message_path:, source_code_info:, path:)
        class_name = ActiveSupport::Inflector.upcase_first(message.name)
        decl_namespace = prefix.append(class_name.to_sym)

        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: class_name.to_sym, namespace: prefix),
          super_class: message_base_class,
          type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
          location: nil,
          comment: comment_for_path(source_code_info, path),
          members: [],
          annotations: []
        ).tap do |class_decl|
          maps = {}

          message.nested_type.each_with_index do |nested_type, index|
            if nested_type.options&.map_entry
              key_field, value_field = nested_type.field.to_a
              map_type_name = ".#{(message_path + [nested_type.name]).join(".")}"
              maps[map_type_name] = [key_field, value_field]
            else
              class_decl.members << message_to_decl(
                nested_type,
                prefix: RBS::Namespace.empty,
                message_path: message_path + [nested_type.name.to_sym],
                source_code_info: source_code_info,
                path: path + [3, index]
              )
            end
          end

          message.enum_type.each_with_index do |enum, index|
            class_decl.members << enum_type_to_decl(
              enum,
              prefix: RBS::Namespace.empty,
              source_code_info: source_code_info,
              path: path + [4, index]
            )
          end

          field_read_types = {}
          field_write_types = {}

          message.field.each_with_index do |field, index|
            field_name = field.name.to_sym
            comment = comment_for_path(source_code_info, path + [2, index])

            read_type, write_type = field_type(field, maps)

            field_read_types[field_name] = read_type
            field_write_types[field_name] = write_type

            if read_type == write_type
              class_decl.members << RBS::AST::Members::AttrAccessor.new(
                name: field_name,
                type: read_type,
                comment: comment,
                location: nil,
                annotations: [],
                ivar_name: false
              )
            else
              class_decl.members << RBS::AST::Members::AttrReader.new(
                name: field_name,
                type: read_type,
                comment: comment,
                location: nil,
                annotations: [],
                ivar_name: false
              )

              class_decl.members << RBS::AST::Members::AttrWriter.new(
                name: field_name,
                type: write_type,
                comment: comment,
                location: nil,
                annotations: [],
                ivar_name: false
              )
            end
          end

          class_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :initialize,
            types: [
              factory.method_type(
                type: factory.function().update(
                  optional_keywords: field_write_types.transform_values {|ty|
                    factory.param(ty)
                  }
                )
              )
            ],
            annotations: [],
            comment: nil,
            attributes: [],
            location: nil,
            overload: false,
            kind: :instance
          )

          unless field_read_types.empty?
            class_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :[],
              types:
                field_read_types.keys.map do |key|
                  factory.method_type(
                    type: factory.function(field_read_types[key]).update(
                      required_positionals: [
                        factory.param(factory.literal_type(key))
                      ]
                    )
                  )
                end +
                  [
                    factory.method_type(
                      type: factory.function(factory.untyped).update(
                        required_positionals: [
                          factory.param(RBS::BuiltinNames::Symbol.instance_type)
                        ]
                      )
                    )
                  ],
              annotations: [],
              comment: nil,
              attributes: [],
              location: nil,
              overload: false,
              kind: :instance
            )
          end

          unless field_write_types.empty?
            class_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :[]=,
              types:
                field_write_types.keys.map do |key|
                  factory.method_type(
                    type: factory.function(field_write_types[key]).update(
                      required_positionals: [
                        factory.literal_type(key),
                        field_write_types[key]
                      ].map {|t| factory.param(t) }
                    )
                  )
                end +
                  [
                    factory.method_type(
                      type: factory.function(factory.untyped).update(
                        required_positionals: [
                          RBS::BuiltinNames::Symbol.instance_type,
                          factory.untyped
                        ].map {|t| factory.param(t) }
                      )
                    )
                  ],
              annotations: [],
              comment: nil,
              attributes: [],
              location: nil,
              overload: false,
              kind: :instance
            )
          end

          message.field.each do |field|
            if field.type == FieldDescriptorProto::Type::TYPE_BOOL
              class_decl.members << RBS::AST::Members::MethodDefinition.new(
                name: :"#{field.name}?",
                types: [
                  factory.method_type(
                    type: factory.function(factory.bool_type)
                  )
                ],
                annotations: [],
                comment: nil,
                attributes: [],
                location: nil,
                overload: false,
                kind: :instance
              )
            end
          end
        end
      end

      def field_type(field, maps)
        case
        when field.type == FieldDescriptorProto::Type::TYPE_MESSAGE
          if maps.key?(field.type_name)
            key_field, value_field = maps[field.type_name]

            key_type_r, _ = field_type(key_field, maps)
            value_type_r, value_type_w = field_type(value_field, maps)

            hash_type = factory.instance_type(
              factory.type_name("::Protobuf::Field::FieldHash"),
              key_type_r,
              factory.unwrap_optional(value_type_r),
              factory.unwrap_optional(value_type_w)
            )

            [
              hash_type,
              hash_type
            ]
          else
            type = message_type(field.type_name)

            case field.label
            when FieldDescriptorProto::Label::LABEL_OPTIONAL
              type = factory.optional_type(type)
              [type, type]
            when FieldDescriptorProto::Label::LABEL_REPEATED
              type = repeated_field_type(type)
              [type, type]
            else
              [type, factory.optional_type(type)]
            end
          end
        when field.type == FieldDescriptorProto::Type::TYPE_ENUM
          type = message_type(field.type_name)
          enum_namespace = type.name.to_namespace

          wtype = factory.union_type(
            type,
            factory.alias_type(RBS::TypeName.new(name: :values, namespace: enum_namespace))
          )

          if field.label == FieldDescriptorProto::Label::LABEL_REPEATED
            type = repeated_field_type(type, wtype)

            [
              type,
              type
            ]
          else
            [
              type,
              factory.optional_type(wtype)
            ]
          end
        else
          type = base_type(field.type)

          if field.label == FieldDescriptorProto::Label::LABEL_REPEATED
            type = repeated_field_type(type)
            [type, type]
          else
            [type, factory.optional_type(type)]
          end
        end
      end

      def enum_base_class
        RBS::AST::Declarations::Class::Super.new(
          name: factory.type_name("::Protobuf::Enum"),
          args: []
        )
      end

      def enum_name(name)
        if upcase_enum?
          name.upcase.to_sym
        else
          name.to_sym
        end
      end

      def enum_type_to_decl(enum_type, prefix:, source_code_info:, path:)
        enum_name = ActiveSupport::Inflector.upcase_first(enum_type.name)

        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: enum_name.to_sym, namespace: prefix),
          super_class: enum_base_class(),
          type_params: factory.module_type_params(),
          members: [],
          comment: comment_for_path(source_code_info, path),
          location: nil,
          annotations: []
        ).tap do |enum_decl|
          names = enum_type.value.map do |v|
            factory.literal_type(enum_name(v.name))
          end

          strings = enum_type.value.map do |v|
            factory.literal_type(enum_name(v.name).to_s)
          end

          tags = enum_type.value.map do |v|
            factory.literal_type(v.number)
          end.uniq

          enum_decl.members << RBS::AST::Declarations::Alias.new(
            name: factory.type_name("names"),
            type: factory.union_type(*names),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Declarations::Alias.new(
            name: factory.type_name("strings"),
            type: factory.union_type(*strings),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Declarations::Alias.new(
            name: factory.type_name("tags"),
            type: factory.union_type(*tags),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Declarations::Alias.new(
            name: factory.type_name("values"),
            type: factory.union_type(
              factory.alias_type("names"),
              factory.alias_type("strings"),
              factory.alias_type("tags")
            ),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Members::AttrReader.new(
            name: :name,
            type: factory.alias_type("names"),
            ivar_name: false,
            annotations: [],
            comment: nil,
            location: nil
          )

          enum_decl.members << RBS::AST::Members::AttrReader.new(
            name: :tag,
            type: factory.alias_type("tags"),
            ivar_name: false,
            annotations: [],
            comment: nil,
            location: nil
          )

          enum_type.value.each.with_index do |v, index|
            comment = comment_for_path(source_code_info, path + [2, index])

            enum_decl.members << RBS::AST::Declarations::Constant.new(
              name: factory.type_name(enum_name(v.name).to_s),
              type: RBS::TypeName.new(name: enum_name.to_sym, namespace: prefix),
              comment: comment,
              location: nil
            )
          end
        end
      end

      def service_base_class
        RBS::AST::Declarations::Class::Super.new(
          name: factory.type_name("::Protobuf::Rpc::Service"),
          args: []
        )
      end

      def service_to_decl(service, prefix:, source_code_info:, path:)
        service_name = ActiveSupport::Inflector.camelize(service.name)

        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: service_name.to_sym, namespace: prefix),
          super_class: service_base_class,
          type_params: factory.module_type_params(),
          members: [],
          comment: comment_for_path(source_code_info, path),
          location: nil,
          annotations: []
        ).tap do |service_decl|
          requests = []
          responses = []

          service.method.each.with_index do |method, index|
            requests << message_type(method.input_type)
            responses << message_type(method.output_type)

            service_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: ActiveSupport::Inflector.underscore(method.name).to_sym,
              kind: :instance,
              types: [factory.method_type(type: factory.function())],
              annotations: [],
              location: nil,
              comment: comment_for_path(source_code_info, path + [2, index]),
              attributes: [],
              overload: false
            )
          end

          unless requests.empty?
            service_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :request,
              kind: :instance,
              types: [
                factory.method_type(
                  type: factory.function(
                    factory.union_type(*requests)
                  )
                )
              ],
              annotations: [],
              location: nil,
              comment: nil,
              attributes: [],
              overload: false
            )
          end

          unless responses.empty?
            service_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :response,
              kind: :instance,
              types: [
                factory.method_type(
                  type: factory.function().update(
                    required_positionals: [
                      factory.param(
                        factory.union_type(*responses)
                      )
                    ]
                  )
                )
              ],
              annotations: [],
              location: nil,
              comment: nil,
              attributes: [],
              overload: false
            )
          end
        end
      end

      def vendor_gem_rbs!
        dir = Pathname(__dir__) + "../../../rbs/protobuf"
        dir.each_child do |child|
          if child.extname == ".rbs"
            response.file << Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(
              name: (Pathname("rbs_protobuf/protobuf") + child.basename).to_s,
              content: child.read
            )
          end
        end
      end
    end
  end
end
