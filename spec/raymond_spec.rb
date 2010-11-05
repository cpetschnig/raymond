require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MySpecController
  include Raymond::Control
  def index(params)
    @sorting = Raymond::Control.new(self, params[:sort])
    @result_array = @sorting.result
  end
end

class MySpecModel
  include Raymond::Model
  
  allow_sort_by :start_at, :title, :km
  allow_sort_by :duration, :method => Proc.new{|obj| obj.duration(:numeric)}
  allow_sort_by :modality, :method => Proc.new{|obj| obj.modality && obj.modality.name}
  allow_sort_by :costs, :db => false

  secondary_sort_attr :start_at

  
end

describe "Raymond" do
  it "fails" do
    fail "hey buddy, you should probably rename this file and start specing for real"
  end
end
