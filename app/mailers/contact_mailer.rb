class ContactMailer < ApplicationMailer
  default to: "admin@jbps.com.au"

  def new_message(name:, email:, message:)
    @name = name
    @email = email
    @message = message

    mail(
      from: "noreply@jbps.com.au",
      reply_to: email,
      subject: "New enquiry from #{name} via jbps.com.au"
    )
  end
end
