require 'test_helper'

class DeasControllerTest < ActionController::TestCase
  setup do
    @dea = deas(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dea" do
    assert_difference('Dea.count') do
      post :create, dea: {  }
    end

    assert_redirected_to dea_path(assigns(:dea))
  end

  test "should show dea" do
    get :show, id: @dea
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dea
    assert_response :success
  end

  test "should update dea" do
    put :update, id: @dea, dea: {  }
    assert_redirected_to dea_path(assigns(:dea))
  end

  test "should destroy dea" do
    assert_difference('Dea.count', -1) do
      delete :destroy, id: @dea
    end

    assert_redirected_to deas_path
  end
end
