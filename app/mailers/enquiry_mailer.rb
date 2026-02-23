class EnquiryMailer < ApplicationMailer
  default from: "JBPS <noreply@jbps.com.au>"

  def new_enquiry(enquiry)
    @enquiry = enquiry
    subject = "New Enquiry — #{enquiry.name} // #{enquiry.company.presence || enquiry.location.presence || 'TBC'}"
    mail(to: "admin@jbps.com.au", subject: subject)
  end
end
