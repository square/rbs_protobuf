module RBSProtobuf
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

      source_code_info = file.source_code_info

      if file.package && !file.package.empty?
        prefix = to_type_name(file.package).to_namespace
      else
        prefix = RBS::Namespace.empty
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
                                 source_code_info: source_code_info,
                                 path: [4, index])
      end

      StringIO.new.tap do |io|
        RBS::Writer.new(out: io).write(decls)
      end.string
    end

    def comment_for_path(source_code_info:, path:)
      loc = source_code_info.location.find {|loc| loc.path == path }
      if loc
        comments = []
        if loc.leading_comments.length > 0
          comments << loc.leading_comments.strip
        end
        if loc.trailing_comments.length > 0
          comments << loc.trailing_comments.strip
        end
        if comments.empty? && !loc.leading_detached_comments.empty?
          comments << loc.leading_detached_comments.join("\n\n").strip
        end
        RBS::AST::Comment.new(
          location: nil,
          string: comments.join("\n\n")
        )
      end
    end

    def enum_type_to_decl(enum_type, prefix:, source_code_info:, path:)
      RBS::AST::Declarations::Module.new(
        name: RBS::TypeName.new(name: ActiveSupport::Inflector.upcase_first(enum_type.name).to_sym, namespace: prefix),
        self_type: nil,
        type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
        members: [],
        comment: comment_for_path(source_code_info: source_code_info, path: path),
        location: nil,
        annotations: []
      ).tap do |enum_decl|
        enum_decl.members << RBS::AST::Declarations::Alias.new(
          name: RBS::TypeName.new(name: :symbols, namespace: RBS::Namespace.empty),
          type: RBS::Types::Union.new(
            types: enum_type.value.map do |v|
              RBS::Types::Literal.new(literal: v.name.upcase.to_sym, location: nil)
            end,
            location: nil
          ),
          location: nil,
          comment: nil,
          annotations: []
        )

        enum_type.value.each_with_index do |value, index|
          comment = comment_for_path(source_code_info: source_code_info, path: path + [2, index])
          enum_decl.members << RBS::AST::Declarations::Constant.new(
            name: RBS::TypeName.new(name: value.name.upcase.to_sym, namespace: RBS::Namespace.empty),
            type: RBS::BuiltinNames::Integer.instance_type,
            location: nil,
            comment: comment
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

    def message_to_decl(message, prefix: RBS::Namespace.empty, maps: {}, source_code_info:, path:)
      name = ActiveSupport::Inflector.upcase_first(message.name)
      decl_namespace = prefix.append(name.to_sym)

      RBS::AST::Declarations::Class.new(
        name: RBS::TypeName.new(name: name.to_sym, namespace: prefix),
        super_class: nil,
        type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
        location: nil,
        comment: comment_for_path(source_code_info: source_code_info, path: path),
        members: [],
        annotations: []
      ).tap do |class_decl|
        keywords = {}
        oneof_fields = message.oneof_decl.map { [] }

        message.enum_type.each_with_index do |enum, index|
          class_decl.members << enum_type_to_decl(
            enum,
            prefix: RBS::Namespace.empty,
            source_code_info: source_code_info,
            path: path + [4, index]
          )
        end

        message.nested_type.each_with_index do |nested_type, index|
          if nested_type.options&.map_entry
            key_field, value_field = nested_type.field.to_a
            maps["." + decl_namespace.to_s.gsub(/::/, ".") + nested_type.name] = [key_field, value_field]
          else
            class_decl.members << message_to_decl(
              nested_type,
              prefix: RBS::Namespace.empty,
              maps: maps,
              source_code_info: source_code_info,
              path: path + [3, index]
            )
          end
        end

        message.field.each_with_index do |field, index|
          comment = comment_for_path(source_code_info: source_code_info, path: path + [2, index])
          case
          when field.type == :TYPE_MESSAGE && field.label == :LABEL_REPEATED && maps.key?(field.type_name)
            # Map!
            key_field, value_field = maps[field.type_name]
            key_type = base_type(key_field.type)
            value_type = field_type(value_field)

            type = RBS::BuiltinNames::Hash.instance_type(key_type, value_type)

            class_decl.members << RBS::AST::Members::AttrAccessor.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: comment,
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
              comment: comment,
              annotations: []
            )
            class_decl.members << RBS::AST::Members::AttrWriter.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: comment,
              annotations: []
            )
          when field.type == :TYPE_MESSAGE
            type = field_type(field)
            if field.label == :LABEL_REPEATED
              class_decl.members << RBS::AST::Members::AttrAccessor.new(
                name: field.name.to_sym,
                type: type,
                ivar_name: false,
                location: nil,
                comment: comment,
                annotations: []
              )
            else
              class_decl.members << RBS::AST::Members::AttrAccessor.new(
                name: field.name.to_sym,
                type: type,
                ivar_name: false,
                location: nil,
                comment: comment,
                annotations: []
              )
            end
          else
            # Scalar values
            type = field_type(field)
            class_decl.members << RBS::AST::Members::AttrAccessor.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: comment,
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
               enum_name = to_type_name(field.type_name).to_namespace

               RBS::Types::Alias.new(
                 name: RBS::TypeName.new(
                   name: :symbols,
                   namespace: enum_name
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

      *path, basename = type_name.split(".").map {|name| ActiveSupport::Inflector.upcase_first(name) }.drop_while {|x| x.size == 0 }

      RBS::TypeName.new(
        name: basename.to_sym,
        namespace: RBS::Namespace.new(path: path.map(&:to_sym), absolute: absolute)
      )
    end
  end
end
