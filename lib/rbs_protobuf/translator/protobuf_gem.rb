module RBSProtobuf
  module Translator
    class ProtobufGem < Base
      FIELD_ARRAY = Name::Class.new(TypeName("::Protobuf::Field::FieldArray"))

      FIELD_HASH = Name::Class.new(TypeName("::Protobuf::Field::FieldHash"))

      ENUM = Name::Class.new(TypeName("::Protobuf::Enum"))

      MESSAGE = Name::Class.new(TypeName("::Protobuf::Message"))

      TO_PROTO = Name::Interface.new(TypeName("_ToProto"))

      FIELD_ARRAY_a = Name::Alias.new(TypeName("::Protobuf::field_array"))

      FIELD_HASH_a = Name::Alias.new(TypeName("::Protobuf::field_hash"))

      attr_reader :stderr

      attr_reader :accept_nil_writer

      def initialize(input, filters=[], upcase_enum:, nested_namespace:, extension:, accept_nil_writer:, stderr: STDERR)
        super(input, filters)
        @upcase_enum = upcase_enum
        @nested_namespace = nested_namespace
        @extension = extension
        @accept_nil_writer = accept_nil_writer
        @stderr = stderr
      end

      def ignore_extension?
        !@extension
      end

      def print_extension_message?
        @extension == nil
      end

      def print_extension?
        @extension == :print
      end

      def upcase_enum?
        @upcase_enum
      end

      def nested_namespace?
        @nested_namespace
      end

      def rbs_content(file)
        decls = [] #: Array[RBS::AST::Declarations::t]

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

        file.extension.each.with_index do |extension, index|
          if ignore_extension?
            if print_extension_message?
              stderr.puts "Extension for `#{extension.extendee}` ignored in `#{file.name}`; Set RBS_PROTOBUF_EXTENSION env var to generate RBS for extensions."
            end
          else
            ext = extension_to_decl(extension, prefix: RBS::Namespace.root, source_code_info: source_code_info, path: [7, index])

            if print_extension?
              stderr.puts "#=========================================================="
              stderr.puts "# Printing RBS for extensions from #{file.name}"
              stderr.puts "#"
              RBS::Writer.new(out: stderr).write([ext])
              stderr.puts
            else
              decls.push(ext)
            end
          end
        end

        decls
      end

      def message_to_decl(message, prefix:, message_path:, source_code_info:, path:)
        class_name = ActiveSupport::Inflector.upcase_first(message.name)

        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: class_name.to_sym, namespace: prefix),
          super_class: MESSAGE.super_class,
          type_params: [],
          location: nil,
          comment: comment_for_path(source_code_info, path, options: message.options),
          members: [],
          annotations: []
        ).tap do |class_decl|
          class_instance_type = factory.instance_type(RBS::TypeName.new(name: class_decl.name.name, namespace: RBS::Namespace.empty))

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

          # @type var field_types: Hash[Symbol, [RBS::Types::t, Array[RBS::Types::t], RBS::Types::t]]
          field_types = {}

          message.field.each_with_index do |field, index|
            field_name = field.name.to_sym
            comment = comment_for_path(source_code_info, path + [2, index], options: field.options)

            read_type, write_types, init_type = field_type(field, maps)
            field_types[field_name] = [read_type, write_types, init_type]

            add_field(class_decl.members, name: field_name, read_type: read_type, write_types: write_types, comment: comment)
          end

          class_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :initialize,
            overloads: [
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(
                  type: factory.function().update(
                    optional_keywords: field_types.transform_values {|pair|
                      _, _, init_type = pair
                      factory.param(init_type)
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
                          RBS::BuiltinNames::Hash.instance_type(RBS::BuiltinNames::Symbol.instance_type, factory.untyped),
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
                  read_type, _ = pair

                  RBS::AST::Members::MethodDefinition::Overload.new(
                    method_type: factory.method_type(
                      type: factory.function(read_type).update(
                        required_positionals: [
                          factory.param(factory.literal_type(field_name))
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
                            factory.param(RBS::BuiltinNames::Symbol.instance_type)
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
                field_types.flat_map do |field_name, pair|
                  read_type, write_types = pair

                  [read_type, *write_types].map do |type|
                    method_type =
                      if (type_param, type_var = interface_type?(type))
                        factory.method_type(
                          type: factory.function(type_var).update(
                            required_positionals: [
                              factory.literal_type(field_name),
                              type_var
                            ].map {|t| factory.param(t) }
                          )
                        ).update(type_params: [type_param])
                      else
                        factory.method_type(
                          type: factory.function(type).update(
                            required_positionals: [
                              factory.literal_type(field_name),
                              type
                            ].map {|t| factory.param(t) }
                          )
                        )
                      end

                    RBS::AST::Members::MethodDefinition::Overload.new(method_type: method_type, annotations: [])
                  end
                end +
                  [
                    RBS::AST::Members::MethodDefinition::Overload.new(
                      method_type: factory.method_type(
                        type: factory.function(factory.untyped).update(
                          required_positionals: [
                            RBS::BuiltinNames::Symbol.instance_type,
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

          message.field.each do |field|
            if field.type == FieldDescriptorProto::Type::TYPE_BOOL
              class_decl.members << RBS::AST::Members::MethodDefinition.new(
                name: :"#{field.name}?",
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
          end

          class_decl.members << RBS::AST::Declarations::Interface.new(
            name: TO_PROTO.name,
            type_params: [],
            members: [],
            annotations: [],
            comment: nil,
            location: nil
          ).tap do |interface_decl|
            interface_decl.members << RBS::AST::Members::MethodDefinition.new(
              name: :to_proto,
              overloads: [
                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: factory.method_type(
                    type: factory.function(class_instance_type)
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
            name: TypeName("init"),
            type_params: [],
            type: factory.union_type(
              class_instance_type,
              TO_PROTO[]
            ),
            annotations: [],
            comment: RBS::AST::Comment.new(string: "The type of `#initialize` parameter.", location: nil),
            location: nil
          )

          class_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("field_array"),
            type_params: [],
            type: FIELD_ARRAY[
              class_instance_type,
              factory.union_type(class_instance_type, TO_PROTO[])
            ],
            annotations: [],
            comment: RBS::AST::Comment.new(string: "The type of `repeated` field.", location: nil),
            location: nil
          )

          class_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("field_hash"),
            type_params: [RBS::AST::TypeParam.new(name: :KEY, variance: :invariant, upper_bound: nil, location: nil)],
            type: FIELD_HASH[
              factory.type_var(:KEY),
              class_instance_type,
              factory.union_type(class_instance_type, TO_PROTO[])
            ],
            annotations: [],
            comment: RBS::AST::Comment.new(string: "The type of `map` field.", location: nil),
            location: nil
          )

          class_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("array"),
            type_params: [],
            type: RBS::BuiltinNames::Array.instance_type(factory.union_type(class_instance_type, TO_PROTO[])),
            annotations: [],
            comment: nil,
            location: nil
          )

          class_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("hash"),
            type_params: [RBS::AST::TypeParam.new(name: :KEY, variance: :invariant, upper_bound: nil, location: nil)],
            type: RBS::BuiltinNames::Hash.instance_type(
              factory.type_var(:KEY),
              factory.union_type(class_instance_type, TO_PROTO[])
            ),
            annotations: [],
            comment: nil,
            location: nil
          )
        end
      end

      def message_to_proto_type(type)
        namespace = type.name.to_namespace
        RBS::Types::Interface.new(
          name: RBS::TypeName.new(name: :_ToProto, namespace: namespace),
          args: [],
          location: nil
        )
      end

      def message_init_type(type)
        RBS::Types::Alias.new(
          name: RBS::TypeName.new(name: :init, namespace: type.name.to_namespace),
          args: [],
          location: nil
        )
      end

      def message_field_array_type(type)
        RBS::Types::Alias.new(
          name: RBS::TypeName.new(name: :field_array, namespace: type.name.to_namespace),
          args: [],
          location: nil
        )
      end

      def message_array_type(type)
        RBS::Types::Alias.new(
          name: RBS::TypeName.new(name: :array, namespace: type.name.to_namespace),
          args: [],
          location: nil
        )
      end

      def message_hash_type(type, key)
        RBS::Types::Alias.new(
          name: RBS::TypeName.new(name: :hash, namespace: type.name.to_namespace),
          args: [key],
          location: nil
        )
      end

      def message_field_hash_type(type, key)
        RBS::Types::Alias.new(
          name: RBS::TypeName.new(name: :field_hash, namespace: type.name.to_namespace),
          args: [key],
          location: nil
        )
      end

      def field_type(field, maps)
        # @type var triple: [RBS::Types::t, Array[RBS::Types::t], RBS::Types::t]
        triple =
          case
          when field.type == FieldDescriptorProto::Type::TYPE_MESSAGE
            if maps.key?(field.type_name)
              key_field, value_field = maps[field.type_name]

              key_type_r, _ = field_type(key_field, maps)
              value_type_r, value_write_types = field_type(value_field, maps)

              value_type_r = factory.unwrap_optional(value_type_r)
              value_write_types = value_write_types.map {|type| factory.unwrap_optional(type) }

              case value_field.type
              when FieldDescriptorProto::Type::TYPE_MESSAGE, FieldDescriptorProto::Type::TYPE_ENUM
                value_type_r.is_a?(RBS::Types::ClassInstance) or raise
                [
                  message_field_hash_type(value_type_r, key_type_r),
                  [message_hash_type(value_type_r, key_type_r)],
                  message_hash_type(value_type_r, key_type_r)
                ]
              else
                hash_type = FIELD_HASH[
                  key_type_r,
                  value_type_r,
                  factory.union_type(value_type_r, *value_write_types)
                ]

                [
                  FIELD_HASH_a[key_type_r, value_type_r],
                  [RBS::BuiltinNames::Hash.instance_type(key_type_r, value_type_r)],
                  RBS::BuiltinNames::Hash.instance_type(key_type_r, value_type_r)
                ]
              end
            else
              type = message_type(field.type_name)

              case field.label
              when FieldDescriptorProto::Label::LABEL_OPTIONAL
                [
                  factory.optional_type(type),
                  [
                    factory.optional_type(message_to_proto_type(type))
                  ],
                  factory.optional_type(message_init_type(type))
                ]
              when FieldDescriptorProto::Label::LABEL_REPEATED
                [
                  message_field_array_type(type),
                  [
                    message_array_type(type)
                  ],
                  message_array_type(type)
                ]
              else
                [
                  type,
                  [message_to_proto_type(type)],
                  message_init_type(type)
                ]
              end
            end
          when field.type == FieldDescriptorProto::Type::TYPE_ENUM
            type = message_type(field.type_name)
            enum_namespace = type.name.to_namespace
            values = factory.alias_type(RBS::TypeName.new(name: :values, namespace: enum_namespace))

            if field.label == FieldDescriptorProto::Label::LABEL_REPEATED
              [
                message_field_array_type(type),
                [message_array_type(type)],
                message_array_type(type)
              ]
            else
              [
                type,
                [values],
                message_init_type(type)
              ]
            end
          else
            type = base_type(field.type)

            if field.label == FieldDescriptorProto::Label::LABEL_REPEATED
              [
                FIELD_ARRAY_a[type],
                [RBS::BuiltinNames::Array.instance_type(type)],
                RBS::BuiltinNames::Array.instance_type(type)
              ]
            else
              [type, [], type]
            end
          end

        if accept_nil_writer
          read_type, write_types, init_type = triple
          [
            read_type,
            ([factory.optional_type(read_type)] + write_types.map {|t| factory.optional_type(t) }).uniq,
            factory.optional_type(init_type)
          ]
        else
          triple
        end
      end

      def interface_type?(type)
        case
        when type.is_a?(RBS::Types::Interface)
          [
            RBS::AST::TypeParam.new(name: :M, upper_bound: type, variance: :invariant, location: nil),
            factory.type_var(:M)
          ]
        when type.is_a?(RBS::Types::Optional)
          if (type = type.type).is_a?(RBS::Types::Interface)
            [
              RBS::AST::TypeParam.new(name: :M, upper_bound: type, variance: :invariant, location: nil),
              factory.optional_type(factory.type_var(:M))
            ]
          end
        end
      end

      def add_field(members, name:, read_type:, write_types:, comment:)
        members << RBS::AST::Members::AttrAccessor.new(
          name: name,
          type: read_type,
          comment: comment,
          location: nil,
          annotations: [],
          ivar_name: false,
          kind: :instance
        )

        unless write_types.empty?
          members << RBS::AST::Members::MethodDefinition.new(
            name: :"#{name}=",
            overloads:
              write_types.map do |write_type|
                method_type =
                  if (type_param, type = interface_type?(write_type))
                    factory.method_type(
                      type: factory.function(type).update(
                        required_positionals:[factory.param(type)]
                      )
                    ).update(type_params: [type_param])
                  else
                    factory.method_type(
                      type: factory.function(write_type).update(
                        required_positionals:[factory.param(write_type)]
                      )
                    )
                  end

                RBS::AST::Members::MethodDefinition::Overload.new(
                  method_type: method_type,
                  annotations: []
                )
              end,
            annotations: [],
            comment: comment,
            location: nil,
            overloading: true,
            visibility: nil,
            kind: :instance
          )
        end

        members << RBS::AST::Members::MethodDefinition.new(
          name: :"#{name}!",
          overloads: [
            RBS::AST::Members::MethodDefinition::Overload.new(
              method_type: factory.method_type(
                type: factory.function(factory.optional_type(read_type))
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
          super_class: ENUM.super_class,
          type_params: factory.module_type_params(),
          members: [],
          comment: comment_for_path(source_code_info, path, options: enum_type.options),
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

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: factory.type_name("names"),
            type_params: [],
            type: factory.union_type(*names),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: factory.type_name("strings"),
            type_params: [],
            type: factory.union_type(*strings),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: factory.type_name("tags"),
            type_params: [],
            type: factory.union_type(*tags),
            location: nil,
            comment: nil,
            annotations: []
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: factory.type_name("values"),
            type_params: [],
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
            location: nil,
            kind: :instance
          )

          enum_decl.members << RBS::AST::Members::AttrReader.new(
            name: :tag,
            type: factory.alias_type("tags"),
            ivar_name: false,
            annotations: [],
            comment: nil,
            location: nil,
            kind: :instance
          )

          enum_type.value.each.with_index do |v, index|
            comment = comment_for_path(source_code_info, path + [2, index], options: v.options)

            enum_decl.members << RBS::AST::Declarations::Constant.new(
              name: factory.type_name(enum_name(v.name).to_s),
              type: factory.instance_type(RBS::TypeName.new(name: enum_name.to_sym, namespace: prefix)),
              comment: comment,
              location: nil
            )
          end

          enum_instance_type = factory.instance_type(RBS::TypeName.new(name: enum_name.to_sym, namespace: RBS::Namespace.empty))
          values_type = factory.alias_type(RBS::TypeName.new(name: :values, namespace: RBS::Namespace.empty))

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("init"),
            type_params: [],
            type: factory.union_type(enum_instance_type, values_type),
            annotations: [],
            comment: RBS::AST::Comment.new(string: "The type of `#initialize` parameter.", location: nil),
            location: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("field_array"),
            type_params: [],
            type: FIELD_ARRAY[
              enum_instance_type,
              factory.union_type(enum_instance_type, values_type)
            ],
            annotations: [],
            comment: RBS::AST::Comment.new(string: "The type of `repeated` field.", location: nil),
            location: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("field_hash"),
            type_params: [RBS::AST::TypeParam.new(name: :KEY, variance: :invariant, upper_bound: nil, location: nil)],
            type: FIELD_HASH[
              factory.type_var(:KEY),
              enum_instance_type,
              factory.union_type(enum_instance_type, values_type)
            ],
            annotations: [],
            comment: RBS::AST::Comment.new(string: "The type of `map` field.", location: nil),
            location: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("array"),
            type_params: [],
            type: RBS::BuiltinNames::Array.instance_type(factory.union_type(enum_instance_type, values_type)),
            annotations: [],
            comment: nil,
            location: nil
          )

          enum_decl.members << RBS::AST::Declarations::TypeAlias.new(
            name: TypeName("hash"),
            type_params: [RBS::AST::TypeParam.new(name: :KEY, variance: :invariant, upper_bound: nil, location: nil)],
            type: RBS::BuiltinNames::Hash.instance_type(
              factory.type_var(:KEY),
              factory.union_type(enum_instance_type, values_type)
            ),
            annotations: [],
            comment: nil,
            location: nil
          )
        end
      end

      def extension_to_decl(extension, prefix:, source_code_info:, path:)
        class_name = message_type(extension.extendee).name

        comment = comment_for_path(source_code_info, path, options: extension.options)
        field_name = extension.name.to_sym

        RBS::AST::Declarations::Class.new(
          name: class_name,
          super_class: nil,
          type_params: [],
          location: nil,
          comment: nil,
          members: [],
          annotations: []
        ).tap do |class_decl|
          read_type, write_types, _ = field_type(extension, {})

          add_field(class_decl.members, name: field_name, read_type: read_type, write_types: write_types, comment: comment)

          class_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :[],
            overloads: [
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(
                  type: factory.function(read_type).update(
                    required_positionals: [
                      factory.param(factory.literal_type(field_name))
                    ]
                  )
                ),
                annotations: []
              )
            ],
            annotations: [],
            comment: nil,
            location: nil,
            overloading: true,
            visibility: nil,
            kind: :instance
          )

          class_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: :[]=,
            overloads: [read_type, *write_types].map do |write_type|
              method_type =
                if (type_param, type_var = interface_type?(write_type))
                  factory.method_type(
                    type: factory.function(type_var).update(
                      required_positionals: [
                        factory.param(factory.literal_type(field_name)),
                        factory.param(type_var)
                      ]
                    )
                  ).update(type_params: [type_param])
                else
                  factory.method_type(
                    type: factory.function(write_type).update(
                      required_positionals: [
                        factory.param(factory.literal_type(field_name)),
                        factory.param(write_type)
                      ]
                    )
                  )
                end
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: method_type,
                annotations: []
              )
            end,
            annotations: [],
            comment: nil,
            location: nil,
            overloading: true,
            visibility: nil,
            kind: :instance
          )
        end
      end

      def service_base_class
        RBS::AST::Declarations::Class::Super.new(
          name: factory.type_name("::Protobuf::Rpc::Service"),
          args: [],
          location: nil
        )
      end

      def service_to_decl(service, prefix:, source_code_info:, path:)
        service_name = ActiveSupport::Inflector.camelize(service.name)

        members = [] #: Array[RBS::AST::Declarations::Class::member]

        service.method.each do |method|
          method_name = ActiveSupport::Inflector.underscore(method.name).to_sym #: Symbol

          interface_name = "_#{ActiveSupport::Inflector.camelize(method.name)}Method"

          members << RBS::AST::Declarations::Interface.new(
            name: factory.type_name(interface_name),
            type_params: [],
            members: [
              RBS::AST::Members::MethodDefinition.new(
                name: :request,
                kind: :instance,
                overloads: [
                  RBS::AST::Members::MethodDefinition::Overload.new(
                    method_type: factory.method_type(type: factory.function(message_type(method.input_type))),
                    annotations: []
                  )
                ],
                annotations: [],
                location: nil,
                comment: nil,
                overloading: false,
                visibility: nil
              ),
              RBS::AST::Members::MethodDefinition.new(
                name: :respond_with,
                kind: :instance,
                overloads: [
                  RBS::AST::Members::MethodDefinition::Overload.new(
                    method_type: factory.method_type(
                      type: factory.function().update(
                        required_positionals: [
                          factory.param(message_init_type(message_type(method.output_type)))
                        ]
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
            ],
            annotations: [],
            location: nil,
            comment: nil
          )

          members << RBS::AST::Members::MethodDefinition.new(
            name: method_name,
            kind: :instance,
            overloads: [
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: factory.method_type(type: factory.function()),
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

        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: service_name.to_sym, namespace: prefix),
          super_class: service_base_class,
          type_params: factory.module_type_params(),
          members: members,
          comment: comment_for_path(source_code_info, path, options: nil),
          location: nil,
          annotations: []
        )
      end
    end
  end
end
