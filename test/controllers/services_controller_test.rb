require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get services_path
    assert_response :success
  end

  test "should get new" do
    get new_service_path
    assert_response :success
  end

  test "should create service" do
    assert_difference("Service.count") do
      post services_path, params: { service: { name: "Test", description: "Test description" } }
    end
    assert_redirected_to services_path
    assert_equal "Service created successfully.", flash[:notice]
  end

  test "should get edit" do
    service = Service.create(name: "Test", description: "Test description")
    get edit_service_path(service)
    assert_response :success
  end

  test "should get update" do
    service = Service.create(name: "Test", description: "Test description")
    patch service_path(service), params: { service: { name: "Updated" } }
    assert_redirected_to services_path
    assert_equal "Updated", Service.find(service.id).name
  end

  test "should get destroy" do
    service = Service.create(name: "Test", description: "Test description")
    assert_difference("Service.count", -1) do
      delete service_path(service)
    end
    assert_redirected_to services_path
  end
end
