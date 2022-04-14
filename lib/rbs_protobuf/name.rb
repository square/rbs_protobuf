module RBSProtobuf
  module Name
    class Class
      attr_reader :name

      def initialize(name)
        raise unless name.class?
        @name = name
      end

      def instance_type(*args)
        RBS::Types::ClassInstance.new(name: name, args: args, location: nil)
      end

      alias [] instance_type

      def singleton_type
        RBS::Types::ClassSingleton.new(name: name, location: nil)
      end

      def instance_type?(t)
        t.is_a?(RBS::Types::ClassInstance) && t.name == name
      end

      def singleton_type?(t)
        t.is_a?(RBS::Types::ClassSingleton) && t.name == name
      end

      def super_class(*args)
        RBS::AST::Declarations::Class::Super.new(name: name, args: args, location: nil)
      end
    end

    class Alias
      attr_reader :name

      def initialize(name)
        raise unless name.alias?
        @name = name
      end

      def [](*args)
        RBS::Types::Alias.new(name: name, args: args, location: nil)
      end

      def type?(t)
        t.is_a?(RBS::Types::Alias) && t.name == name
      end
    end

    class Interface
      attr_reader :name

      def initialize(name)
        raise unless name.interface?
        @name = name
      end

      def [](*args)
        RBS::Types::Interface.new(name: name, args: args, location: nil)
      end

      def type?(t)
        t.is_a?(RBS::Types::Interface) && t.name == name
      end
    end
  end
end
