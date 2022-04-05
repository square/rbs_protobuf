module RBSProtobuf
  class RBSFactory
    include RBS

    def type_name(string)
      absolute = string.start_with?("::")

      *path, name = string.delete_prefix("::").split("::").map(&:to_sym)

      TypeName.new(
        name: name || raise,
        namespace: Namespace.new(path: path, absolute: absolute)
      )
    end

    def namespace(string)
      absolute = string.start_with?("::")
      path = string.delete_prefix("::").split("::").map(&:to_sym)

      Namespace.new(
        path: path,
        absolute: absolute
      )
    end

    def instance_type(name, *args)
      type_name = case name
                  when TypeName
                    name
                  else
                    type_name(name)
                  end

      Types::ClassInstance.new(name: type_name, args: args, location: nil)
    end

    def singleton_type(name)
      type_name = case name
                  when TypeName
                    name
                  else
                    type_name(name)
                  end

      Types::ClassSingleton.new(name: type_name, location: nil)
    end

    def union_type(type, *types)
      if types.empty?
        type
      else
        Types::Union.new(
          types: [type] + types,
          location: nil
        )
      end
    end

    def nil_type(location: nil)
      RBS::Types::Bases::Nil.new(location: location)
    end

    def bool_type(location: nil)
      RBS::Types::Bases::Bool.new(location: location)
    end

    def alias_type(name, location: nil)
      type_name = case name
                  when TypeName
                    name
                  else
                    type_name(name)
                  end

      Types::Alias.new(name: type_name, args: [], location: nil)
    end

    def function(return_type = Types::Bases::Void.new(location: nil))
      Types::Function.empty(return_type)
    end

    def param(type, name: nil)
      Types::Function::Param.new(
        type: type,
        name: name
      )
    end

    def block(function, required: true)
      Types::Block.new(
        type: function,
        required: required
      )
    end

    def untyped(location: nil)
      Types::Bases::Any.new(location: location)
    end

    def method_type(params: [], type:, block: nil, location: nil)
      type_params = params.map do |name|
        AST::TypeParam.new(name: name, variance: :invariant, upper_bound: nil, location: nil)
      end

      MethodType.new(
        type_params: type_params,
        type: type,
        block: block,
        location: location
      )
    end

    def literal_type(literal)
      Types::Literal.new(
        literal: literal,
        location: nil
      )
    end

    def optional_type(type, location: nil)
      if type.is_a?(Types::Optional)
        type
      else
        Types::Optional.new(
          type: type,
          location: location
        )
      end
    end

    def type_var(name, location: nil)
      Types::Variable.new(
        name: name,
        location: location
      )
    end

    def module_type_params(*params)
      params.map do |name|
        AST::TypeParam.new(name: name, variance: :invariant, upper_bound: nil, location: nil)
      end
    end

    def unwrap_optional(type)
      case type
      when RBS::Types::Optional
        unwrap_optional(type.type)
      else
        type
      end
    end
  end
end
