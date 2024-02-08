module RBSProtobuf
  module Translator
    class GoogleProtobufGem < Base
      EACH = Name::Interface.new(TypeName("::_Each"))

      ENUMERATOR = Name::Class.new(TypeName("::Enumerator"))

      TIME = Name::Class.new(TypeName("::Time"))

      MESSAGE = Name::Class.new(TypeName("::Google::Protobuf::AbstractMessage"))

      FIELD_ARRAY = Name::Class.new(TypeName("::Google::Protobuf::RepeatedField"))

      FIELD_HASH = Name::Class.new(TypeName("::Google::Protobuf::Map"))

      ENUM_DESCRIPTOR = Name::Class.new(TypeName("::Google::Protobuf::EnumDescriptor"))

      GENERIC_SERVICE = Name::Class.new(TypeName("::GRPC::GenericService"))

      SINGLE_REQ_VIEW = Name::Class.new(TypeName("::GRPC::ActiveCall::SingleReqView"))

      MULTI_REQ_VIEW = Name::Class.new(TypeName("::GRPC::ActiveCall::MultiReqView"))

      CLIENT_STUB = Name::Class.new(TypeName("::GRPC::ClientStub"))

      CORE_CALL = Name::Class.new(TypeName("::GRPC::Core::Call"))

      CORE_CALL_CREDENTIALS = Name::Class.new(TypeName("::GRPC::Core::CallCredentials"))

      OPERATION = Name::Class.new(TypeName("::GRPC::ActiveCall::Operation"))

      WRAPPER_BASE_TYPES = {
        ".google.protobuf.DoubleValue" => FieldDescriptorProto::Type::TYPE_DOUBLE,
        ".google.protobuf.FloatValue" => FieldDescriptorProto::Type::TYPE_FLOAT,
        ".google.protobuf.Int64Value" => FieldDescriptorProto::Type::TYPE_INT64,
        ".google.protobuf.UInt64Value" => FieldDescriptorProto::Type::TYPE_UINT64,
        ".google.protobuf.Int32Value" => FieldDescriptorProto::Type::TYPE_INT32,
        ".google.protobuf.UInt32Value" => FieldDescriptorProto::Type::TYPE_UINT32,
        ".google.protobuf.BoolValue" => FieldDescriptorProto::Type::TYPE_BOOL,
        ".google.protobuf.StringValue" => FieldDescriptorProto::Type::TYPE_STRING,
        ".google.protobuf.BytesValue" => FieldDescriptorProto::Type::TYPE_BYTES
      }.freeze

      attr_reader :stderr

      def initialize(input, filters=[], nested_namespace:, stderr: STDERR)
        super(input, filters)
        @nested_namespace = nested_namespace
        @stderr = stderr
        @message_mapping = {}

        input.proto_file.each do |file|
          preprocess_file(file)
        end
      end

      def nested_namespace?
        @nested_namespace
      end

      def preprocess_file(file)
        ruby_path = ruby_path_for(file)
        proto_path = proto_path_for(file)

        file.message_type.each do |message|
          preprocess_message(message, ruby_path: ruby_path, proto_path: proto_path)
        end

        file.enum_type.each do |enum|
          preprocess_enum(enum, ruby_path: ruby_path, proto_path: proto_path)
        end
      end

      def preprocess_message(message, ruby_path:, proto_path:)
        class_name = ActiveSupport::Inflector.upcase_first(message.name)

        ruby_subpath = [*ruby_path, class_name.to_sym]
        proto_subpath = "#{proto_path}.#{message.name}"

        @message_mapping[proto_subpath] = RBS::TypeName.new(name: class_name.to_sym, namespace: RBS::Namespace.new(path: ruby_path, absolute: true))

        message.nested_type.each do |nested_type|
          next if nested_type.options&.map_entry

          preprocess_message(nested_type, ruby_path: ruby_subpath, proto_path: proto_subpath)
        end

        message.enum_type.each do |enum|
          preprocess_enum(enum, ruby_path: ruby_subpath, proto_path: proto_subpath)
        end
      end

      def preprocess_enum(enum, ruby_path:, proto_path:)
        class_name = ActiveSupport::Inflector.upcase_first(enum.name)

        proto_subpath = "#{proto_path}.#{enum.name}"

        @message_mapping[proto_subpath] = RBS::TypeName.new(name: class_name.to_sym, namespace: RBS::Namespace.new(path: ruby_path, absolute: true))
      end

      def rbs_content(file)
        decls = [] #: Array[RBS::AST::Declarations::t]

        source_code_info = file.source_code_info

        ruby_path = ruby_path_for(file)
        proto_path = proto_path_for(file)

        prefix = if nested_namespace?
                   RBS::Namespace.empty
                 else
                   RBS::Namespace.new(path: ruby_path, absolute: true)
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
                                   proto_path: proto_path,
                                   file: file,
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
          ruby_path.reverse_each do |name|
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

        decls
      end

      def ruby_path_for(file)
        if file.options&.ruby_package && !file.options.ruby_package.empty?
          file.options.ruby_package.split(/\.|::/).map(&:to_sym)
        elsif file.package && !file.package.empty?
          file.package.split(".").map { |s| ActiveSupport::Inflector.classify(s).to_sym }
        else
          []
        end
      end

      def proto_path_for(file)
        if file.package && !file.package.empty?
          ".#{file.package}"
        else
          ""
        end
      end

      def message_to_decl(message, prefix:, proto_path:, file:, source_code_info:, path:)
        class_name = ActiveSupport::Inflector.upcase_first(message.name)

        proto_subpath = "#{proto_path}.#{message.name}"

        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: class_name.to_sym, namespace: prefix),
          super_class: MESSAGE.super_class,
          type_params: [],
          location: nil,
          comment: comment_for_path(source_code_info, path, options: message.options),
          members: [],
          annotations: []
        ).tap do |class_decl|
          maps = {}

          message.nested_type.each_with_index do |nested_type, index|
            if nested_type.options&.map_entry
              key_field, value_field = nested_type.field.to_a
              map_type_name = "#{proto_subpath}.#{nested_type.name}"
              maps[map_type_name] = [key_field, value_field]
            else
              class_decl.members << message_to_decl(
                nested_type,
                prefix: RBS::Namespace.empty,
                proto_path: proto_subpath,
                file: file,
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

          # @type var field_types: Hash[Symbol, [RBS::Types::t, RBS::Types::t?, RBS::Types::t?]]
          field_types = {}

          message.field.each_with_index do |field, index|
            field_name = field.name.to_sym
            comment = comment_for_path(source_code_info, path + [2, index], options: field.options)

            read_type, write_type, init_type = field_type(field, maps)
            field_types[field_name] = [read_type, write_type, init_type]

            add_field(class_decl.members, name: field_name, read_type: read_type, write_type: write_type, comment: comment, field: field, file: file)
          end

          fields_by_oneof_index = message.field.select { |field| field.oneof_index! }.group_by(&:oneof_index)

          message.oneof_decl.each_with_index do |oneof_decl, index|
            comment = comment_for_path(source_code_info, path + [6, index], options: oneof_decl.options)
            add_oneof(class_decl.members, oneof_decl, fields: fields_by_oneof_index[index], maps: maps, comment: comment)
          end

          class_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :initialize,
            overloads: [
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(
                  type: factory.function().update(
                    optional_keywords: field_types.transform_values {|pair|
                      read_type, _, init_type = pair
                      factory.param(factory.optional_type(init_type || read_type))
                    }
                  )
                ),
                annotations: []
              ),
              unless field_types.empty?
                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: factory.method_type(
                    type: factory.function().update(
                      required_positionals: [
                        factory.param(
                          RBS::BuiltinNames::Hash.instance_type(
                            factory.union_type(
                              RBS::BuiltinNames::Symbol.instance_type,
                              RBS::BuiltinNames::String.instance_type
                            ),
                            factory.untyped
                          ),
                          name: :attributes
                        )
                      ]
                    )
                  ),
                  annotations: []
                )
              end,
            ].compact,
            annotations: [],
            comment: nil,
            location: nil,
            overloading: false,
            visibility: nil,
            kind: :instance
          )

          unless field_types.empty?
            class_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :[],
              overloads:
                field_types.map do |field_name, pair|
                  read_type, _, _ = pair

                  RBS::AST::Members::MethodDefinition::Overload.new(
                    method_type: factory.method_type(
                      type: factory.function(read_type).update(
                        required_positionals: [
                          factory.param(factory.literal_type(field_name.to_s))
                        ]
                      )
                    ),
                    annotations: []
                  )
                end +
                  [
                    RBS::AST::Members::MethodDefinition::Overload.new(
                      method_type: factory.method_type(
                        type: factory.function(factory.untyped).update(
                          required_positionals: [
                            factory.param(RBS::BuiltinNames::String.instance_type)
                          ]
                        )
                      ),
                      annotations: []
                    )
                  ],
              annotations: [],
              comment: nil,
              location: nil,
              overloading: false,
              visibility: nil,
              kind: :instance
            )

            class_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :[]=,
              overloads:
                field_types.map do |field_name, pair|
                  read_type, write_type, _ = pair

                  method_type =
                    factory.method_type(
                      type: factory.function().update(
                        required_positionals: [
                          factory.literal_type(field_name.to_s),
                          write_type || read_type
                        ].map {|t| factory.param(t) }
                      )
                    )

                  RBS::AST::Members::MethodDefinition::Overload.new(method_type: method_type, annotations: [])
                end +
                  [
                    RBS::AST::Members::MethodDefinition::Overload.new(
                      method_type: factory.method_type(
                        type: factory.function().update(
                          required_positionals: [
                            RBS::BuiltinNames::String.instance_type,
                            factory.untyped
                          ].map {|t| factory.param(t) }
                        )
                      ),
                      annotations: []
                    )
                  ],
              annotations: [],
              comment: nil,
              location: nil,
              overloading: false,
              visibility: nil,
              kind: :instance
            )
          end

          class_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("init_map"),
            type_params: [],
            type: RBS::Types::Record.new(
              # TODO: make fields optional once https://github.com/ruby/rbs/issues/504 is resolved
              # TODO: also accept Strings once https://github.com/ruby/rbs/issues/1645 is resolved
              fields: field_types.transform_values {|pair|
                read_type, _, init_type = pair
                factory.optional_type(init_type || read_type)
              },
              location: nil
            ),
            annotations: [],
            comment: nil,
            location: nil
          )
        end
      end

      def message_init_type(type)
        factory.union_type(
          type,
          RBS::Types::Alias.new(
            name: RBS::TypeName.new(name: :init_map, namespace: type.name.to_namespace),
            args: [],
            location: nil
          )
        )
      end

      def enum_read_type(type)
        factory.union_type(
          RBS::Types::Alias.new(
            name: RBS::TypeName.new(name: :names, namespace: type.name.to_namespace),
            args: [],
            location: nil
          ),
          RBS::BuiltinNames::Integer.instance_type
        )
      end

      def enum_init_type(type)
        factory.union_type(
          RBS::Types::Alias.new(
            name: RBS::TypeName.new(name: :names, namespace: type.name.to_namespace),
            args: [],
            location: nil
          ),
          RBS::Types::Alias.new(
            name: RBS::TypeName.new(name: :strings, namespace: type.name.to_namespace),
            args: [],
            location: nil
          ),
          RBS::BuiltinNames::Integer.instance_type,
          RBS::BuiltinNames::Float.instance_type
        )
      end

      def base_write_type(type)
        case type
        when FieldDescriptorProto::Type::TYPE_FLOAT, FieldDescriptorProto::Type::TYPE_DOUBLE
          factory.union_type(
            RBS::BuiltinNames::Float.instance_type,
            RBS::BuiltinNames::Integer.instance_type
          )
        when FieldDescriptorProto::Type::TYPE_STRING
          # String (but not bytes) accepts Symbols as well
          factory.union_type(
            RBS::BuiltinNames::String.instance_type,
            RBS::BuiltinNames::Symbol.instance_type
          )
        when FieldDescriptorProto::Type::TYPE_INT32, FieldDescriptorProto::Type::TYPE_INT64,
          FieldDescriptorProto::Type::TYPE_UINT32, FieldDescriptorProto::Type::TYPE_UINT64,
          FieldDescriptorProto::Type::TYPE_FIXED32, FieldDescriptorProto::Type::TYPE_FIXED64,
          FieldDescriptorProto::Type::TYPE_SINT32, FieldDescriptorProto::Type::TYPE_SINT64,
          FieldDescriptorProto::Type::TYPE_SFIXED32, FieldDescriptorProto::Type::TYPE_SFIXED64
          # Integer types accept floats provided they are whole numbers
          factory.union_type(
            RBS::BuiltinNames::Integer.instance_type,
            RBS::BuiltinNames::Float.instance_type
          )
        else
          nil
        end
      end

      def ruby_type_for(proto_path)
        factory.instance_type(
          @message_mapping[proto_path] || raise("Type not found: #{proto_path}")
        )
      end

      def field_scalar_type(field,  maps)
        case field.type
        when FieldDescriptorProto::Type::TYPE_MESSAGE
          raise "unreachable" if maps.key?(field.type_name)

          message_base = ruby_type_for(field.type_name)
          [message_base, nil, message_init_type(message_base)]
        when FieldDescriptorProto::Type::TYPE_ENUM
          enum_base = ruby_type_for(field.type_name)
          [enum_read_type(enum_base), enum_init_type(enum_base), enum_init_type(enum_base)]
        else
          [
            base_type(field.type),
            base_write_type(field.type),
            base_write_type(field.type)
          ]
        end
      end

      def field_type(field,  maps)
        if field.type == FieldDescriptorProto::Type::TYPE_MESSAGE && maps.key?(field.type_name)
          key_field, value_field = maps[field.type_name]

          key_type_r, key_type_w = field_scalar_type(key_field, maps)
          value_type_r, value_type_w = field_scalar_type(value_field, maps)

          return [
            FIELD_HASH[key_type_r, value_type_r, key_type_w || key_type_r, value_type_w || value_type_r],
            nil,
            RBS::BuiltinNames::Hash.instance_type(key_type_r, value_type_r)
          ]
        end

        scalar_read_type, scalar_write_type, scalar_init_type = field_scalar_type(field, maps)

        if field.label == FieldDescriptorProto::Label::LABEL_REPEATED
          [
            FIELD_ARRAY[scalar_read_type, scalar_write_type || scalar_read_type],
            nil,
            RBS::BuiltinNames::Array.instance_type(scalar_init_type || scalar_read_type)
          ]
          # In google-protobuf, proto2 optional is ignored.
        elsif field.type == FieldDescriptorProto::Type::TYPE_MESSAGE
          [
            factory.optional_type(scalar_read_type),
            scalar_write_type && factory.optional_type(scalar_write_type),
            scalar_init_type && factory.optional_type(scalar_init_type)
          ]
        elsif field.oneof_index! && !field.proto3_optional?
          # non-message oneof other than proto3 optional; you can write nil onto it but it won't return nil
          [
            scalar_read_type,
            factory.optional_type(scalar_write_type || scalar_read_type),
            factory.optional_type(scalar_init_type || scalar_read_type)
          ]
        else
          # NOTE: proto2 optional and proto3 optional also fall here; google-protobuf ignores them
          [
            scalar_read_type,
            scalar_write_type,
            scalar_init_type
          ]
        end
      end

      def has_presence?(field, file:)
        return false if field.label == FieldDescriptorProto::Label::LABEL_REPEATED

        case field.type
        when FieldDescriptorProto::Type::TYPE_MESSAGE
          true
        when FieldDescriptorProto::Type::TYPE_GROUP
          true
        else
          # It should be ideally based on optionality but google-protobuf gem actually checks for the syntax instead.
          # And "proto2" sometimes represented as "", it seems.
          file.syntax == "proto2" || file.syntax == "" || field.oneof_index!
        end
      end

      def add_field(members, name:, read_type:, write_type:, comment:, field:, file:)
        if write_type
          members << RBS::AST::Members::AttrReader.new(
            name: name,
            type: read_type,
            comment: comment,
            location: nil,
            annotations: [],
            ivar_name: false,
            kind: :instance
          )
          members << RBS::AST::Members::AttrWriter.new(
            name: name,
            type: write_type,
            comment: nil,
            location: nil,
            annotations: [],
            ivar_name: false,
            kind: :instance
          )
        else
          members << RBS::AST::Members::AttrAccessor.new(
            name: name,
            type: read_type,
            comment: comment,
            location: nil,
            annotations: [],
            ivar_name: false,
            kind: :instance
          )
        end

        if field.type == FieldDescriptorProto::Type::TYPE_MESSAGE
          inner_type = WRAPPER_BASE_TYPES[field.type_name]
          if inner_type
            scalar_read_type = base_type(inner_type)
            scalar_write_type = base_write_type(inner_type)
            if scalar_write_type
              members << RBS::AST::Members::AttrReader.new(
                name: :"#{name}_as_value",
                type: factory.optional_type(scalar_read_type),
                ivar_name: false,
                kind: :instance,
                annotations: [],
                location: nil,
                comment: nil,
                visibility: nil
              )
              members << RBS::AST::Members::AttrWriter.new(
                name: :"#{name}_as_value",
                type: factory.optional_type(scalar_write_type),
                ivar_name: false,
                kind: :instance,
                annotations: [],
                location: nil,
                comment: nil,
                visibility: nil
              )
            else
              members << RBS::AST::Members::AttrAccessor.new(
                name: :"#{name}_as_value",
                type: factory.optional_type(scalar_read_type),
                ivar_name: false,
                kind: :instance,
                annotations: [],
                location: nil,
                comment: nil,
                visibility: nil
              )
            end
          end
        end

        if field.type == FieldDescriptorProto::Type::TYPE_ENUM
          members << RBS::AST::Members::AttrReader.new(
            name: :"#{name}_const",
            type:
              if field.label == FieldDescriptorProto::Label::LABEL_REPEATED
                RBS::BuiltinNames::Array.instance_type(RBS::BuiltinNames::Integer.instance_type)
              else
                RBS::BuiltinNames::Integer.instance_type
              end,
            comment: nil,
            location: nil,
            annotations: [],
            ivar_name: false,
            kind: :instance
          )
        end

        if has_presence?(field, file: file)
          members << RBS::AST::Members::MethodDefinition.new(
            name: :"has_#{name}?",
            overloads: [
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(
                  type: factory.function(factory.bool_type)
                ),
                annotations: []
              )
            ],
            annotations: [],
            comment: nil,
            location: nil,
            overloading: false,
            visibility: nil,
            kind: :instance
          )
        end

        members << RBS::AST::Members::MethodDefinition.new(
          name: :"clear_#{name}",
          overloads: [
            RBS::AST::Members::MethodDefinition::Overload.new(
              method_type: factory.method_type(
                type: factory.function()
              ),
              annotations: []
            )
          ],
          annotations: [],
          comment: nil,
          location: nil,
          overloading: false,
          visibility: nil,
          kind: :instance
        )
      end

      def add_oneof(members, oneof_decl, fields:, maps:, comment:)
        members << RBS::AST::Members::AttrReader.new(
          name: oneof_decl.name,
          type: factory.optional_type(factory.union_type(
            *fields.map do |field|
              read_type, _ = field_scalar_type(field, maps)
              read_type
            end
          )),
          comment: comment,
          location: nil,
          annotations: [],
          ivar_name: false,
          kind: :instance
        )

        members << RBS::AST::Members::MethodDefinition.new(
          name: :"clear_#{oneof_decl.name}",
          overloads: [
            RBS::AST::Members::MethodDefinition::Overload.new(
              method_type: factory.method_type(
                type: factory.function
              ),
              annotations: []
            )
          ],
          annotations: [],
          comment: nil,
          location: nil,
          overloading: false,
          visibility: nil,
          kind: :instance
        )
      end

      def enum_type_to_decl(enum_type, prefix:, source_code_info:, path:)
        enum_name = ActiveSupport::Inflector.upcase_first(enum_type.name)

        RBS::AST::Declarations::Module.new(
          name: RBS::TypeName.new(name: enum_name.to_sym, namespace: prefix),
          type_params: factory.module_type_params(),
          members: [],
          self_types: [],
          comment: comment_for_path(source_code_info, path, options: enum_type.options),
          location: nil,
          annotations: []
        ).tap do |enum_decl|
          enum_type.value.each.with_index do |v, index|
            # Exotic enum value name; skip
            next if /\A[_a-z]/.match?(v.name)

            comment = comment_for_path(source_code_info, path + [2, index], options: v.options)

            enum_decl.members << RBS::AST::Declarations::Constant.new(
              name: factory.type_name(v.name.to_s),
              type: factory.literal_type(v.number),
              comment: comment,
              location: nil
            )
          end

          enum_decl.members << RBS::AST::Members::AttrReader.new(
            name: :descriptor,
            type: ENUM_DESCRIPTOR.instance_type,
            ivar_name: nil,
            kind: :singleton,
            annotations: [],
            location: nil,
            comment: nil,
            visibility: nil,
          )

          names_by_number = enum_type.value.group_by(&:number).transform_values do |values|
            values.map(&:name)
          end

          enum_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :lookup,
            kind: :singleton,
            overloads: [
              *names_by_number.map do |number, names|
                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: factory.method_type(
                    type: factory.function(
                      factory.union_type(*names.map {|name| factory.literal_type(name.to_sym) })
                    ).update(
                      required_positionals: [
                        factory.param(factory.literal_type(number), name: :number)
                      ]
                    )
                  ),
                  annotations: []
                )
              end,
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(
                  type: factory.function(
                    factory.optional_type(factory.alias_type("names"))
                  ).update(
                    required_positionals: [
                      factory.param(factory.alias_type("::int"), name: :number)
                    ]
                  )
                ),
                annotations: []
              ),
            ],
            annotations: [],
            location: nil,
            comment: nil,
            overloading: false,
            visibility: nil
          )

          enum_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :resolve,
            kind: :singleton,
            overloads: [
              *enum_type.value.map do |v|
                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: factory.method_type(
                    type: factory.function(
                      factory.literal_type(v.number)
                    ).update(
                      required_positionals: [
                        factory.param(factory.literal_type(v.name.to_sym), name: :name)
                      ]
                    )
                  ),
                  annotations: []
                )
              end,
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(
                  type: factory.function(
                    factory.optional_type(factory.alias_type("numbers"))
                  ).update(
                    required_positionals: [
                      factory.param(RBS::BuiltinNames::Symbol.instance_type, name: :name)
                    ]
                  )
                ),
                annotations: []
              ),
            ],
            annotations: [],
            location: nil,
            comment: nil,
            overloading: false,
            visibility: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("names"),
            type_params: [],
            type: factory.union_type(
              *enum_type.value.map { |v| factory.literal_type(v.name.to_sym) }
            ),
            annotations: [],
            location: nil,
            comment: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("strings"),
            type_params: [],
            type: factory.union_type(
              *enum_type.value.map { |v| factory.literal_type(v.name) }
            ),
            annotations: [],
            location: nil,
            comment: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("numbers"),
            type_params: [],
            type: factory.union_type(
              *names_by_number.map { |number, *| factory.literal_type(number) }
            ),
            annotations: [],
            location: nil,
            comment: nil
          )
        end
      end

      def service_to_decl(service, prefix:, source_code_info:, path:)
        service_name = ActiveSupport::Inflector.camelize(service.name)

        RBS::AST::Declarations::Module.new(
          name: RBS::TypeName.new(name: service_name.to_sym, namespace: prefix),
          type_params: [],
          members: [
            RBS::AST::Declarations::Class.new(
              name: RBS::TypeName.new(name: :Service, namespace: RBS::Namespace.empty),
              type_params: [],
              super_class: nil,
              members: [
                RBS::AST::Members::Include.new(
                  name: GENERIC_SERVICE.name,
                  args: [],
                  annotations: [],
                  location: nil,
                  comment: nil
                ),
                *service.method.map do |method|
                  method_name = ActiveSupport::Inflector.underscore(method.name).to_sym #: Symbol
                  RBS::AST::Members::MethodDefinition.new(
                    name: method_name,
                    kind: :instance,
                    overloads: [
                      RBS::AST::Members::MethodDefinition::Overload.new(
                        method_type: factory.method_type(
                          type: factory.function(
                            if method.server_streaming
                              EACH[ruby_type_for(method.output_type)]
                            else
                              ruby_type_for(method.output_type)
                            end
                          ).update(
                            required_positionals: [
                              if method.server_streaming && method.client_streaming
                                factory.param(ENUMERATOR[ruby_type_for(method.input_type), RBS::Types::Bases::Void.new(location: nil)], name: :reqs)
                              elsif method.client_streaming
                                nil
                              else
                                factory.param(ruby_type_for(method.input_type), name: :req)
                              end,
                              factory.param(
                                if method.client_streaming && method.server_streaming
                                  MULTI_REQ_VIEW[RBS::Types::Bases::Void.new(location: nil)]
                                elsif method.client_streaming
                                  MULTI_REQ_VIEW[ruby_type_for(method.input_type)]
                                else
                                  SINGLE_REQ_VIEW.instance_type
                                end,
                                name: :view
                              )
                            ].compact
                          )
                        ),
                        annotations: []
                      )
                    ],
                    annotations: [],
                    location: nil,
                    comment: nil,
                    overloading: false,
                    visibility: nil
                  )
                end
              ],
              annotations: [],
              location: nil,
              comment: nil
            ),
            RBS::AST::Declarations::Class.new(
              name: RBS::TypeName.new(name: :Stub, namespace: RBS::Namespace.empty),
              type_params: [],
              super_class: CLIENT_STUB.super_class,
              members: [
                *service.method.map do |method|
                  method_name = ActiveSupport::Inflector.underscore(method.name).to_sym #: Symbol
                  overloads = [] #: Array[RBS::AST::Members::MethodDefinition::Overload]

                  accept_block_variations = if method.server_streaming
                                              [false, true]
                                            else
                                              [false]
                                            end

                  accept_block_variations.each do |accept_block|
                    [false, true].each do |return_op|
                      return_type = ruby_type_for(method.output_type)
                      if method.server_streaming && accept_block
                        return_type = RBS::Types::Bases::Void.new(location: nil)
                      elsif method.server_streaming
                        return_type = ENUMERATOR[return_type, RBS::Types::Bases::Void.new(location: nil)]
                      end
                      return_type = OPERATION[return_type] if return_op
                      overloads << RBS::AST::Members::MethodDefinition::Overload.new(
                        method_type: factory.method_type(
                          type: factory.function(return_type).update(
                            required_positionals: [
                              if method.client_streaming
                                factory.param(EACH[ruby_type_for(method.input_type)], name: :reqs)
                              else
                                factory.param(ruby_type_for(method.input_type), name: :req)
                              end
                            ],
                            required_keywords: {
                              return_op:
                                if return_op
                                  factory.param(factory.literal_type(true))
                                else
                                  nil
                                end
                            }.compact,
                            optional_keywords: {
                              return_op:
                                if return_op
                                  nil
                                else
                                  factory.param(factory.literal_type(false))
                                end,
                              deadline: factory.param(factory.optional_type(TIME.instance_type)),
                              parent: factory.param(factory.optional_type(CORE_CALL.instance_type)),
                              credentials: factory.param(factory.optional_type(CORE_CALL_CREDENTIALS.instance_type)),
                              metadata: factory.param(
                                # TODO: is it a correct type for metadata?
                                RBS::BuiltinNames::Hash.instance_type(
                                  RBS::BuiltinNames::String.instance_type,
                                  RBS::BuiltinNames::String.instance_type
                                )
                              )
                            }.compact,
                          ),
                          block:
                            if method.server_streaming && accept_block
                              factory.block(
                                factory.function.update(required_positionals: [
                                  factory.param(ruby_type_for(method.output_type), name: :res)
                                ]),
                                required: true
                              )
                            else
                              nil
                            end
                        ),
                        annotations: []
                      )
                    end
                  end

                  RBS::AST::Members::MethodDefinition.new(
                    name: method_name,
                    kind: :instance,
                    overloads: overloads,
                    annotations: [],
                    location: nil,
                    comment: nil,
                    overloading: false,
                    visibility: nil
                  )
                end
              ],
              annotations: [],
              location: nil,
              comment: nil
            )
          ],
          self_types: [],
          comment: comment_for_path(source_code_info, path, options: nil),
          location: nil,
          annotations: []
        )
      end
    end
  end
end
