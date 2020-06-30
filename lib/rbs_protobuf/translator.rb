module RbsProtobuf
  class Translator
    attr_reader :input

    def initialize(input)
      @input = input
    end

    def response
      @response ||= generate_response()
    end

    def generate_response
      response = Google::Protobuf::Compiler::CodeGeneratorResponse.new

      input.proto_file.each do |file|
        response.file << Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(
          name: rbs_name(file.name),
          content: rbs_content(file)
        )
      end

      response
    end

    def rbs_name(proto_name)
      dirname = File.dirname(proto_name)
      basename = File.basename(proto_name, File.extname(proto_name))
      rbs_name = basename + "_pb.rbs"

      File.join(dirname, rbs_name)
    end

    def rbs_content(file)
      decls = []

      file.message_type.each do |message|
        decls << message_to_decl(message)
      end

      StringIO.new.tap do |io|
        RBS::Writer.new(out: io).write(decls)
      end.string
    end

    def enum_type_to_decl(enum_type)
      RBS::AST::Declarations::Module.new(
        name: RBS::TypeName.new(name: enum_type.name.to_sym, namespace: RBS::Namespace.empty),
        self_type: nil,
        type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
        members: [],
        comment: nil,
        location: nil,
        annotations: []
      ).tap do |enum_decl|
        enum_decl.members << RBS::AST::Declarations::Alias.new(
          name: RBS::TypeName.new(name: :symbols, namespace: RBS::Namespace.empty),
          type: RBS::Types::Union.new(
            types: enum_type.value.map do |v|
              RBS::Types::Literal.new(literal: v.name.to_sym, location: nil)
            end,
            location: nil
          ),
          location: nil,
          comment: nil,
          annotations: []
        )

        enum_type.value.each do |value|
          enum_decl.members << RBS::AST::Declarations::Constant.new(
            name: RBS::TypeName.new(name: value.name.to_sym, namespace: RBS::Namespace.empty),
            type: RBS::BuiltinNames::Integer.instance_type,
            location: nil,
            comment: nil
          )
        end

        enum_decl.members << RBS::AST::Members::MethodDefinition.new(
          name: :lookup,
          kind: :singleton,
          annotations: [],
          comment: nil,
          location: nil,
          overload: false,
          attributes: [],
          types: [
            RBS::MethodType.new(
              type_params: [],
              type: RBS::Types::Function.empty(
                RBS::Types::Optional.new(
                  type: RBS::Types::Alias.new(
                    name: RBS::TypeName.new(name: :symbols, namespace: RBS::Namespace.empty),
                    location: nil
                  ),
                  location: nil
                )
              ).update(required_positionals: [
                RBS::Types::Function::Param.new(
                  name: :number,
                  type: RBS::BuiltinNames::Integer.instance_type
                )
              ]),
              block: nil,
              location: nil
            )
          ]
        )

        enum_decl.members << RBS::AST::Members::MethodDefinition.new(
          name: :resolve,
          kind: :singleton,
          annotations: [],
          comment: nil,
          location: nil,
          overload: false,
          attributes: [],
          types: [
            RBS::MethodType.new(
              type_params: [],
              type: RBS::Types::Function.empty(
                RBS::Types::Optional.new(
                  type: RBS::BuiltinNames::Integer.instance_type,
                  location: nil
                )
              ).update(required_positionals: [
                RBS::Types::Function::Param.new(
                  name: :symbol,
                  type: RBS::BuiltinNames::Symbol.instance_type
                )
              ]),
              block: nil,
              location: nil
            )
          ]
        )
      end
    end

    def message_to_decl(message, prefix: RBS::Namespace.empty, maps: {})
      name = message.name
      decl_namespace = prefix.append(name.to_sym)

      RBS::AST::Declarations::Class.new(
        name: RBS::TypeName.new(name: name.to_sym, namespace: RBS::Namespace.empty),
        super_class: nil,
        type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
        location: nil,
        comment: RBS::AST::Comment.new(location: nil, string: "#{message.name}"),
        members: [],
        annotations: []
      ).tap do |class_decl|
        keywords = {}
        oneof_fields = message.oneof_decl.map { [] }

        message.enum_type.each do |enum|
          class_decl.members << enum_type_to_decl(enum)
        end

        message.nested_type.each do |nested_type|
          if nested_type.options&.map_entry
            key_field, value_field = nested_type.field.to_a
            maps["." + decl_namespace.to_s.gsub(/::/, ".") + nested_type.name] = [key_field, value_field]
          else
            class_decl.members << message_to_decl(nested_type, prefix: decl_namespace, maps: maps)
          end
        end

        message.field.each do |field|
          case
          when field.type == :TYPE_MESSAGE && field.label == :LABEL_REPEATED && maps.key?(field.type_name)
            # Map!
            key_field, value_field = maps[field.type_name]
            key_type = base_type(key_field.type)
            value_type = field_type(value_field)

            type = RBS::BuiltinNames::Hash.instance_type(key_type, value_type)

            class_decl.members << RBS::AST::Members::AttrReader.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: nil,
              annotations: []
            )

          when field.type == :TYPE_ENUM
            symbols = field_type(field)
            type = RBS::Types::Union.new(types: [symbols, RBS::BuiltinNames::Integer.instance_type], location: nil)

            class_decl.members << RBS::AST::Members::AttrReader.new(
              name: field.name.to_sym,
              type: symbols,
              ivar_name: false,
              location: nil,
              comment: nil,
              annotations: []
            )
            class_decl.members << RBS::AST::Members::AttrWriter.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: nil,
              annotations: []
            )
          when field.type == :TYPE_MESSAGE
            type = field_type(field)
            class_decl.members << RBS::AST::Members::AttrReader.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: nil,
              annotations: []
            )
          else
            # Scalar values
            type = field_type(field)
            class_decl.members << RBS::AST::Members::AttrAccessor.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: nil,
              annotations: []
            )
          end

          keywords[field.name.to_sym] = type

          if field.to_h.key?(:oneof_index)
            oneof_fields[field.oneof_index] << field.name.to_sym
          end
        end

        method_type = RBS::MethodType.new(
          type_params: [],
          type: RBS::Types::Function
                  .empty(RBS::Types::Bases::Void.new(location: nil))
                  .update(optional_keywords: keywords.transform_values {|kw_type|
                    RBS::Types::Function::Param.new(name: nil, type: kw_type)
                  }),
          block: nil,
          location: nil
        )

        class_decl.members << RBS::AST::Members::MethodDefinition.new(
          name: :initialize,
          kind: :instance,
          annotations: [],
          comment: nil,
          location: nil,
          overload: false,
          attributes: [],
          types: [method_type]
        )

        message.oneof_decl.each_with_index do |oneof_decl, index|
          fields = oneof_fields[index]
          class_decl.members << RBS::AST::Members::MethodDefinition.new(
            name: oneof_decl.name.to_sym,
            kind: :instance,
            annotations: [],
            comment: nil,
            location: nil,
            overload: false,
            attributes: [],
            types: [
              RBS::MethodType.new(
                type_params: [],
                type: RBS::Types::Function
                        .empty(
                          RBS::Types::Union.new(
                            types: fields.map {|field| RBS::Types::Literal.new(literal: field, location: nil) },
                            location: nil
                          )
                        ),
                block: nil,
                location: nil
              )
            ]
          )
        end
      end
    end

    def field_type(field)
      type = case field.type
             when :TYPE_ENUM
               enum_name = field.type_name.split('.').last

               RBS::Types::Alias.new(
                 name: RBS::TypeName.new(
                   name: :symbols,
                   namespace: RBS::Namespace.new(path: [enum_name.to_sym], absolute: false)
                 ),
                 location: nil
               )
             when :TYPE_MESSAGE
               type_name = to_type_name(field.type_name)
               RBS::Types::ClassInstance.new(
                 name: type_name,
                 args: [],
                 location: nil
               )
             else
               base_type(field.type)
             end

      if field.label == :LABEL_REPEATED
        type = RBS::BuiltinNames::Array.instance_type(type)
      end

      if field.label == :LABEL_OPTIONAL && field.type == :TYPE_MESSAGE
        type = RBS::Types::Optional.new(type: type, location: nil)
      end

      type
    end

    def base_type(type)
      case type
      when :TYPE_STRING, :TYPE_BYTES
        RBS::BuiltinNames::String.instance_type
      when :TYPE_INT32, :TYPE_INT64,
        :TYPE_UINT32, :TYPE_UINT64,
        :TYPE_FIXED32, :TYPE_FIXED64,
        :TYPE_SINT32, :TYPE_SINT64,
        :TYPE_SFIXED32, :TYPE_SFIXED64
        RBS::BuiltinNames::Integer.instance_type
      when :TYPE_DOUBLE, :TYPE_FLOAT
        RBS::BuiltinNames::Float.instance_type
      when :TYPE_BOOL
        RBS::Types::Union.new(
          location: nil,
          types: [
            RBS::BuiltinNames::TrueClass.instance_type,
            RBS::BuiltinNames::FalseClass.instance_type
          ]
        )
      else
        raise
      end
    end

    def to_type_name(type_name)
      absolute = type_name.start_with?(".")

      *path, basename = type_name.split(".").drop_while {|x| x.size == 0 }

      RBS::TypeName.new(
        name: basename.to_sym,
        namespace: RBS::Namespace.new(path: path.map(&:to_sym), absolute: absolute)
      )
    end
  end
end
