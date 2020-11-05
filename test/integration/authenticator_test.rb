require 'test_helper'

class AuthenticatorTest < ActionDispatch::IntegrationTest
  def setup
    @user = active_user
    @token = @user.to_token
  end

  test "jwt_decode" do
    payload = UserAuth::AuthToken.new(token: @token).payload
    sub = payload["sub"]
    exp = payload["exp"]
    aud = payload["aud"]

    # subjectは一致しているか
    assert_equal(@user.id, sub)

    # expirationの値はあるか
    assert exp.present?

    # tokenの有効期限は2週間か(1分許容)
    assert_in_delta(2.week.from_now, Time.at(exp), 1.minute)

    # audienceの値はあるか
    assert aud.present?

    # audienceの値は一致しているか
    assert_equal(ENV["API_DOMAIN"], aud)
  end

  test "authenticate_user_method_test" do
    key = UserAuth.token_access_key

    # @userとcurrent_userは一致しているか
    cookies[key] = @token
    get api_url("/users/current_user")
    assert_response 200
    assert_equal(@user, @controller.send(:current_user))

    # 無効なトークンはアクセス不可か
    invalid_token = @token + "a"
    cookies[key] = invalid_token
    get api_url("/users/current_user")
    assert_response 401

    # 何も返されないか
    assert @response.body.blank?

    # トークンがない場合もアクセス不可か
    cookies[key] = nil
    get api_url("/users/current_user")
    assert_response 401

    # トークンの有効期限内はアクセス可能か
    travel_to (UserAuth.token_lifetime.from_now - 1.minute) do
      cookies[key] = @token
      get api_url("/users/current_user")
      assert_response 200
      assert_equal(@user, @controller.send(:current_user))
    end

    # トークンの有効期限が切れた場合はアクセス不可か
    travel_to (UserAuth.token_lifetime.from_now + 1.minute) do
      cookies[key] = @token
      get api_url("/users/current_user")
      assert_response 401
    end

    # headerトークンが優先されているか
    cookies[key] = @token
    other_user = User.where.not(id: @user.id).first
    header_token = other_user.to_token

    get api_url("/users/current_user"), headers: { Authorization: "Bearer #{header_token}" }

    # Authenticatorのトークンはheaderトークンか
    assert_equal(header_token, @controller.send(:token))

    # current_userはother_userか
    assert_equal(other_user, @controller.send(:current_user))
  end
end
