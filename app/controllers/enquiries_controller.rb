class EnquiriesController < ApplicationController
  allow_unauthenticated_access

  def create
    @enquiry = Enquiry.new(enquiry_params)
    if @enquiry.save
      EnquiryMailer.new_enquiry(@enquiry).deliver_later
      redirect_to root_path(sent: 1), status: :see_other
    else
      head :unprocessable_entity
    end
  end

  private

  def enquiry_params
    params.require(:enquiry).permit(
      :name, :company, :email, :phone,
      :location, :budget, :timeline, :source, :description,
      services: []
    )
  end
end
