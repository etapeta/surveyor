require 'test_helper'

class HobAsActiveModelTest < ActiveSupport::TestCase

  include ActiveModel::Lint::Tests

  def setup
    @model = factory(:hob)
  end


  test "model_name exposes singular and human name" do 
    assert_equal "surveyor_hob", model.class.model_name.singular
    assert_equal "Hob", model.class.model_name.human
  end

  test "model_name.human uses I18n" do
    begin
      I18n.backend.store_translations :en, 
        :activemodel => { :models => { :surveyor => { :hob => "A Sample Hob" } } }
      assert_equal "A Sample Hob", model.class.model_name.human
    ensure
      I18n.reload!
    end
  end

end