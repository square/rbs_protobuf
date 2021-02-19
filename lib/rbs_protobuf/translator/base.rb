module RBSProtobuf
  module Translator
    class Base
      FieldDescriptorProto = Google::Protobuf::FieldDescriptorProto

      attr_reader :input

      def initialize(input)
        @input = input
      end

      def factory
        @factory ||= RBSFactory.new()
      end

      def response
        @response ||= Google::Protobuf::Compiler::CodeGeneratorResponse.new
      end

      def generate_rbs!
        input.proto_file.each do |file|
          response.file << Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(
            name: rbs_name(file.name),
            content: rbs_content(file)
          )
        end
      end

      def rbs_name(proto_name)
        dirname = File.dirname(proto_name)
        basename = File.basename(proto_name, File.extname(proto_name))
        rbs_name = "#{basename}#{rbs_suffix}.rbs"

        File.join(dirname, rbs_name)
      end

      def rbs_suffix
        ""
      end

      def rbs_content(file)
        raise NotImplementedError
      end

      def comment_for_path(source_code_info, path)
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

      def base_type(type)
        case type
        when FieldDescriptorProto::Type::TYPE_STRING,
          FieldDescriptorProto::Type::TYPE_BYTES
          RBS::BuiltinNames::String.instance_type
        when FieldDescriptorProto::Type::TYPE_INT32, FieldDescriptorProto::Type::TYPE_INT64,
          FieldDescriptorProto::Type::TYPE_UINT32, FieldDescriptorProto::Type::TYPE_UINT64,
          FieldDescriptorProto::Type::TYPE_FIXED32, FieldDescriptorProto::Type::TYPE_FIXED64,
          FieldDescriptorProto::Type::TYPE_SINT32, FieldDescriptorProto::Type::TYPE_SINT64,
          FieldDescriptorProto::Type::TYPE_SFIXED32, FieldDescriptorProto::Type::TYPE_SFIXED64
          RBS::BuiltinNames::Integer.instance_type
        when FieldDescriptorProto::Type::TYPE_DOUBLE, FieldDescriptorProto::Type::TYPE_FLOAT
          RBS::BuiltinNames::Float.instance_type
        when FieldDescriptorProto::Type::TYPE_BOOL
          factory.bool_type()
        else
          raise "Unknown base type: #{type}"
        end
      end

      def message_type(string)
        absolute = string.start_with?(".")

        *path, name = string.delete_prefix(".").split(".").map {|s| ActiveSupport::Inflector.upcase_first(s).to_sym }

        factory.instance_type(
          RBS::TypeName.new(
            name: name,
            namespace: RBS::Namespace.new(path: path, absolute: absolute)
          )
        )
      end
    end
  end
end
