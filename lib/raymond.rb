#encoding: UTF-8

#module SortHelper
#
#  def sort_header(key, label)
#    current = @sorterer.current_attr?(key)
#    symbol = current ? "#{Raymond::SORTING_SYMBOLS[@sorterer.dir]} " : ''
#    link_to "#{symbol}#{label}", "?sort=#{key}-#{current ? @sorterer.inverse_dir : Raymond::DEFAULT_SORTING_DIR.to_s}"
#  end
#
#end

module Raymond

  SORTING_DIRECTIONS = {:up => 'ASC', :down => 'DESC'}

  #   ⇓ ⇑   ➷ ➹    ➴ ➶     ▼ ▲
  SORTING_SYMBOLS = {:up => '▲', :down => '▼'}

  DEFAULT_SORTING_DIR = :down

  class Control

    attr_reader :dir, :attr

    def initialize(controller, sort_params)
      @attr, @dir = (sort_params || '').split('-').map(&:to_sym)
      @controller = controller
      @class = Module.const_get(controller.class.name[0..-11].singularize) # 'Controller' is 11 characters long
      Rails.logger.warn "Trying to sort by `#{@attr}`, which is not allowed for class #{@class}." unless attr_valid?
    end

    def result
      result = @class.scoped
      #return result unless sorting?

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
      #@class::SORT_ATTRIBUTES.include?(@attr)
      @class.sort_attributes.include?(@attr)
    end

    def current_attr?(attr)
      attr.to_sym == @attr && self.attr_valid?
    end

  end
end


module Raymond

  module Model

    def self.included(base)
      #  Class enhancements
      base.extend(ClassMethods)
    end

    # the methods in this module will become class methods
    module ClassMethods

      def allow_sort_by(*params)
        @sort_attributes ||= []

        # give the use a little bit more freedom by allowing to pass an array of column names
        params = params.first if params.size == 1 && params.first.kind_of?(Array)

        options = params.pop if params.last.kind_of?(Hash)

        raise ArgumentError.new('Method allow_sort_by takes either an array of column names or' +
            'a single column name with a optional hash of options.') if params.size != 1 && options

        params = params.map(&:to_sym)

        params = [{params.first => options}] if options

        # the items of params must all be column names, if params they are symbols

        @sort_attributes += params
      end

      def sort_attributes
        raise "Trying to sort with no sort attributes defined." unless @sort_attributes
        @sort_attributes.map{|attr| attr.kind_of?(Symbol) ? attr : attr.keys.first}
      end

      def sort_proc(attr)#, direction)
        hash = @sort_attributes.detect{|obj| obj.kind_of?(Hash) && obj[attr]}
        method_result = hash && hash[attr] && hash[attr][:method]
        return method_result if method_result
        hash && hash[attr] && hash[attr][:db] == false && Proc.new{|obj| obj.send(attr)}
      end

      def sql_sort_order(attr, direction)
        second = @secondary_sort_attr ? "#{@secondary_sort_attr} #{SORTING_DIRECTIONS[@secondary_sort_direction]}" : nil
        first = (@sort_attributes || []).include?(attr) ? "#{attr} #{SORTING_DIRECTIONS[direction]}" : nil
        [first, second].compact.join(', ')
      end

      def secondary_sort_attr(attr, direction = :up)
        raise ArgumentError.new("First argument of secondary_sort_attr must be a column name.") unless self.column_names.include?(attr.to_s)
        raise ArgumentError.new("Second argument of secondary_sort_attr must be one of #{SORTING_DIRECTIONS.keys.map{|key| ":#{key}"}}.") unless SORTING_DIRECTIONS.keys.include?(direction)
        @secondary_sort_attr = attr
        @secondary_sort_direction = direction
      end

    end

  end

end
