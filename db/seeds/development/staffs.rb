10.times do |n|
  name = "staff#{n}"
  email = "#{name}@example.com"
  staff = Staff.find_or_initialize_by(name: name, email: email, activated: true)

  if staff.new_record?
    staff.password = "password"
    staff.save!
  end
end

puts "staffs = #{Staff.count}"