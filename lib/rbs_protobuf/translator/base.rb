module RBSProtobuf
  module Translator
    class Base
      FieldDescriptorProto = Google::Protobuf::FieldDescriptorProto

      attr_reader :input, :filters

      def initialize(input, filters = [])
        @input = input
        @filters = filters
      end

      def apply_filter(rbs_name, rbs_content, proto_files)
        filters.inject([rbs_name, rbs_content]) do |(rbs_name, rbs_content), filter| #$ [String, String]
          filter[rbs_name, rbs_content, proto_files] or return
        end
      end

      def factory
        @factory ||= RBSFactory.new()
      end

      def response
        @response ||= Google::Protobuf::Compiler::CodeGeneratorResponse.new(:supported_features => ::Google::Protobuf::Compiler::CodeGeneratorResponse::Feature::FEATURE_PROTO3_OPTIONAL.to_i)
      end

      def generate_rbs!
        input.proto_file.each do |file|
          name = rbs_name(file.name)
          decls = rbs_content(file)
          if (name, content = apply_filter(name, format_rbs(decls: decls), [file]))
            response.file << Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(
              name: name,
              content: content
            )
          end
        end
      end

      def format_rbs(dirs: [], decls: [])
        StringIO.new.tap do |io|
          RBS::Writer.new(out: io).write(dirs + decls)
        end.string
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

      def comment_for_path(source_code_info, path, options:)
        loc = source_code_info.location.find {|loc| loc.path == path }

        comments = []

        if loc
          if loc.leading_comments.length > 0
            comments << loc.leading_comments.strip
          end
          if loc.trailing_comments.length > 0
            comments << loc.trailing_comments.strip
          end
          if comments.empty? && !loc.leading_detached_comments.empty?
            comments << loc.leading_detached_comments.join("\n\n").strip
          end
        end

        if options
          # @type var opts: Array[[Symbol, untyped]]
          opts = []
          options.each_field do |key, value|
            if options.field?(key.fully_qualified_name)
              opts << [key.fully_qualified_name, value]
            end
          end

          unless opts.empty?
            unless comments.empty?
              comments << "----"
            end
            comments << "Protobuf options:"
            list = opts.map {|key, value| "- `#{key} = #{value.inspect}`" }
            comments << list.join("\n")
          end
        end

        unless comments.empty?
          RBS::AST::Comment.new(
            location: nil,
            string: comments.join("\n\n") + "\n\n"
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

        name or raise

        factory.instance_type(
          RBS::TypeName.new(
            name: name,
            namespace: RBS::Namespace.new(path: path, absolute: absolute)
          )
        )
      end

      def optional_type(type)
        case type
        when RBS::Types::Optional
          type
        else
          RBS::Types::Optional.new(type: type, location: nil)
        end
      end
    end
  end
end
