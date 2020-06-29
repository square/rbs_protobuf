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

    def message_to_decl(message, prefix: RBS::Namespace.empty)
      name = message.name

      RBS::AST::Declarations::Class.new(
        name: RBS::TypeName.new(name: name.to_sym, namespace: prefix),
        super_class: nil,
        type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
        location: nil,
        comment: RBS::AST::Comment.new(location: nil, string: "#{message.name}"),
        members: [],
        annotations: []
      ).tap do |class_decl|
        keywords = {}

        message.enum_type.each do |enum|
          class_decl.members << RBS::AST::Declarations::Module.new(
            name: RBS::TypeName.new(name: enum.name.to_sym, namespace: RBS::Namespace.empty),
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
                types: enum.value.map do |v|
                  RBS::Types::Literal.new(literal: v.name.to_sym, location: nil)
                end,
                location: nil
              ),
              location: nil,
              comment: nil,
              annotations: []
            )

            enum.value.each do |value|
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

        message.field.each do |field|
          case
          when field.type == :TYPE_ENUM
            enum_name = field.type_name.split('.').last

            symbols = RBS::Types::Alias.new(
              name: RBS::TypeName.new(
                name: :symbols,
                namespace: RBS::Namespace.new(path: [enum_name.to_sym], absolute: false)
              ),
              location: nil
            )
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
          else
            # Scalar values
            type = base_type(field.type)
            class_decl.members << RBS::AST::Members::AttrAccessor.new(
              name: field.name.to_sym,
              type: type,
              ivar_name: false,
              location: nil,
              comment: nil,
              annotations: []
            )
          end

          if field.label == :LABEL_REPEATED
            type = RBS::BuiltinNames::Array.instance_type(type)
          end

          keywords[field.name.to_sym] = type
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
      end
    end

    def base_type(type)
      case type
      when :TYPE_STRING, :TYPE_BYTES
        RBS::BuiltinNames::String.instance_type
      when :TYPE_INT32, :TYPE_UINT32, :TYPE_INT64, :TYPE_UINT64, :TYPE_FIXED64, :TYPE_FIXED32
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
        RBS::Types::Bases::Any.new(location: nil)
      end
    end
  end
end
