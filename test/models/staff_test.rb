require 'test_helper'

class StaffTest < ActiveSupport::TestCase
  def setup
    @staff = active_staff
  end

  test "name_validation" do
    # 入力必須
    staff = Staff.new(email: "test@example.com", password: "password")
    staff.save
    required_msg = ["名前を入力してください"]
    assert_equal(required_msg, staff.errors.full_messages)

    # 文字数制限
    max = 30
    name = "a" * (max + 1)
    staff.name = name
    staff.save
    maxlength_msg = ["名前は30文字以内で入力してください"]
    assert_equal(maxlength_msg, staff.errors.full_messages)

    # 30文字以内は正しく保存されているか
    name = "あ" * max
    staff.name = name
    assert_difference("Staff.count", 1) do
      staff.save
    end
  end

  test "email_validation" do
    # 入力必須
    staff = Staff.new(name: "test", password: "password")
    staff.save
    required_msg = ["メールアドレスを入力してください"]
    assert_equal(required_msg, staff.errors.full_messages)

    # 文字数制限
    max = 255
    domain = "@example.com"
    email = "a" * ((max + 1) - domain.length) + domain
    assert max < email.length

    staff.email = email
    staff.save
    maxlength_msg = ["メールアドレスは255文字以内で入力してください"]
    assert_equal(maxlength_msg, staff.errors.full_messages)

    # 書式チェック format = /\A\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*\z/
    ok_emails = %w(
      A@EX.COM
      a-_@e-x.c-o_m.j_p
      a.a@ex.com
      a@e.co.js
      1.1@ex.com
      a.a+a@ex.com
    )
    ok_emails.each do |email|
      staff.email = email
      assert staff.save
    end
    ng_emails = %w(
      aaa
      a.ex.com
      メール@ex.com
      a~a@ex.com
      a@|.com
      a@ex.
      .a@ex.com
      a＠ex.com
      Ａ@ex.com
      a@?,com
      １@ex.com
      "a"@ex.com
      a@ex@co.jp
    )
    ng_emails.each do |email|
      staff.email = email
      staff.save
      format_msg = ["メールアドレスは不正な値です"]
      assert_equal(format_msg, staff.errors.full_messages)
    end
  end

  test "email_downcase" do
    # email小文字化テスト
    email = "USER@EXAMPLE.COM"
    staff = Staff.new(email: email)
    staff.save
    assert staff.email == email.downcase
  end

  test "active_user_uniqueness" do
    email = "test@example.com"

    # アクティブユーザーがいない場合、同じメールアドレスが登録できているか
    count = 3
    assert_difference("Staff.count", count) do
      count.times do |n|
        Staff.create(name: "test", email: email, password: "password")
      end
    end

    # ユーザーがアクティブになった場合、バリデーションエラーを吐いているか
    active_staff = Staff.find_by(email: email)
    active_staff.update!(activated: true)
    assert active_staff.activated

    assert_no_difference("Staff.count") do
      staff = Staff.new(name: "test", email: email, password: "password")
      staff.save
      uniqueness_msg = ["メールアドレスはすでに存在します"]
      assert_equal(uniqueness_msg, staff.errors.full_messages)
    end

    # アクティブユーザーがいなくなった場合、ユーザーは保存できているか
    active_staff.destroy!
    assert_difference("Staff.count", 1) do
      Staff.create(name: "test", email: email, password: "password", activated: true)
    end

    # 一意性は保たれているか
    assert_equal(1, Staff.where(email: email, activated: true).count)
  end

  test "password_validation" do
    # 入力必須
    staff = Staff.new(name: "test", email: "test@example.com")
    staff.save
    required_msg = ["パスワードを入力してください"]
    assert_equal(required_msg, staff.errors.full_messages)

    # min文字以上
    min = 8
    staff.password = "a" * (min - 1)
    staff.save
    minlength_msg = ["パスワードは8文字以上で入力してください"]
    assert_equal(minlength_msg, staff.errors.full_messages)

    # max文字以下
    max = 72
    staff.password = "a" * (max + 1)
    staff.save
    maxlength_msg = ["パスワードは72文字以内で入力してください"]
    assert_equal(maxlength_msg, staff.errors.full_messages)

    # 書式チェック VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
    ok_passwords = %w(
      pass---word
      ________
      12341234
      ____pass
      pass----
      PASSWORD
    )
    ok_passwords.each do |pass|
      staff.password = pass
      assert staff.save
    end

    ng_passwords = %w(
      pass/word
      pass.word
      |~=?+"a"
      １２３４５６７８
      ＡＢＣＤＥＦＧＨ
      password@
    )
    format_msg = ["パスワードは半角英数字・ハイフン・アンダーバーが使えます"]
    ng_passwords.each do |pass|
      staff.password = pass
      staff.save
      assert_equal(format_msg, staff.errors.full_messages)
    end
  end
end
