class ContactsController < ApplicationController
  allow_unauthenticated_access

  def create
    name = params[:name].to_s.strip
    email = params[:email].to_s.strip
    message = params[:message].to_s.strip

    if name.blank? || email.blank? || message.blank?
      redirect_to root_path(anchor: "contact"), alert: "Please fill in all fields."
    else
      ContactMailer.new_message(name: name, email: email, message: message).deliver_now
      redirect_to root_path(anchor: "contact"), notice: "Thanks #{name}, we'll be in touch soon!"
    end
  end
end
