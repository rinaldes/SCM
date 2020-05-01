class PdfForSupplier < ApplicationMailer
  # include PdfHelper

  def send_report(user, pdf)
     @user = user
     pdfmail = pdf
     attachments["Purchase Order.pdf"] = pdfmail
     mail to: @user.email, subject: "Purchase Order"
  end
end
