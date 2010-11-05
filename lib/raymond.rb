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

end


require 'raymond/control'
require 'raymond/model'
