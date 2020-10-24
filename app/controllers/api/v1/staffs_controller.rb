class Api::V1::StaffsController < ApplicationController
  def index
    staffs = Staff.all
    render json: staffs.as_json(only: [:id, :name, :email, :created_at])
  end
end
