require 'test_helper'

class Api::V1::UserTokenControllerTest < ActionDispatch::IntegrationTest

  def user_token_logged_in(user)
    params = { auth: { email: user.email, password: "password" } }
    post api_url("/user_token"), params: params
    assert_response 200
  end

  def setup
    @user = active_user
    @key = UserAuth.token_access_key
    user_token_logged_in(@user)
  end

  test "create_action" do
    # アクセストークンはCookieに保存されているか
    cookie_token = @request.cookie_jar[@key]
    assert cookie_token.present?

    ## Cookieオプションの追加
    cookie_options = @request.cookie_jar.instance_variable_get(:@set_cookies)[@key.to_s]

    # expiresは一致しているか
    exp = UserAuth::AuthToken.new(token: cookie_token).payload["exp"]
    assert_equal(Time.at(exp), cookie_options[:expires])

    # secureは開発環境でfalseか
    assert_equal(Rails.env.production?, cookie_options[:secure])

    # http_onlyはtrueか
    assert cookie_options[:http_only]

    ## レスポンスのテスト

    # レスポンス有効期限ｎは一致しているか
    assert_equal exp, response_body["exp"]

    # レスポンスユーザーは一致しているか
    assert_equal @user.my_json, response_body["user"]
  end

  test "destroy_action" do
    assert @request.cookie_jar[@key].present?

    delete api_url("/user_token")
    assert_response 200

    # Cookieは削除されているか
    assert @request.cookie_jar[@key].nil?
  end
end
