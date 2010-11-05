module Raymond

  class Control

    attr_reader :dir, :attr

    # Constructor
    #
    # @param [Object] controller is used to figure out the sort class; if option[:class] is
    #   given, the value is ignored.
    # @param [String, Array] sort_params comes in the string form of "my_attribute-down" or
    #   "other_attribute-up", or in Array form of [:attribute, :direction]
    # @param [Hash, #[]] options:
    #   +:class+: specify which class to sort; if omitted, will try to build out
    #   of the name of controller. The class must include Raymond::Model
    #   +:logger+: the logger to use; defaults to the controllers logger or +Rails.logger+
    def initialize(controller, sort_params, options = {})
      @attr, @dir = if sort_params.kind_of?(String)
        (sort_params || '').split('-').map(&:to_sym)
      else
        raise ArgumentError.new("sort_params must be either String or Array.") unless sort_params.kind_of?(Array)
        raise ArgumentError.new("As as Array, sort_params must be in the form of [:my_attribute, :up_or_down].") unless sort_params.size == 2
        sort_params.map(&:to_sym)
      end

      @class = if (klass = options[:class])
        if klass.kind_of?(Class)
          klass
        else
          klass.to_s.constantize    # ActiveSupport dependency
        end
      else
        # class was not explicitly specified; we assume it's related to the name controller name
        controller.class.name[0..-11].singularize.constantize  # 'Controller' is 11 characters long; ActiveSupport dependency!
        #
        # achieve the same without ActiveSupport:
        #@class = Module.const_get(controller.class.name[0..-11].singularize) # 'Controller' is 11 characters long
      end

      # try to use the controllers logger, if available
      @logger = options[:logger] || (controller.respond_to?(:logger) && controller.logger)

      self.logger.warn "Trying to sort by `#{@attr}`, which is not allowed for class #{@class}." unless attr_valid?
    end

    # Returns the sorted result
    # When a block is given, you can hook in between SQL sorting and Ruby sorting.
    #
    # Example:
    #   @sorting = Raymond::Control.new(self, params[:sort], :class => MyFaboulousModel)
    #   @retrieved_data = @sorting.result do |arel|
    #     arel.limit(20).offset(120).where(:foo => 'bar')
    #   end
    #
    # @return [Array] the results in the requested sort order
    def result
      result = @class.scoped

      sql_order = @class.sql_sort_order(@attr, @dir)
      result = result.order(sql_order) unless sql_order.blank?

      result = yield(result) if block_given?

      sort_proc = @class.sort_proc(@attr)
      result = result.sort_by{|obj| sort_proc.call(obj)} if sort_proc

      return result.reverse if sort_proc && @dir == :up

      result
    end

    def inverse_dir
      SORTING_DIRECTIONS.keys.detect{|dir| dir != @dir}
    end

    def attr_valid?
      @class.sort_attributes.include?(@attr)
    end

    def current_attr?(attr)
      attr.to_sym == @attr && self.attr_valid?
    end

    def logger #:nodoc:
      @logger ||= (Module.const_defined?('Rails') && Rails.logger)
    end

  end
end

