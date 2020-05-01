ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "gmail.com",
  :user_name            => "scm.ministop",
  :password             => "ministop123",
  :authentication       => "plain",
  :enable_starttls_auto => true
}