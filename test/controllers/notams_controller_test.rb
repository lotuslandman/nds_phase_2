require 'test_helper'

class NotamsControllerTest < ActionDispatch::IntegrationTest
  test "should get hello" do
    get notams_hello_url
    assert_response :success
  end

end
