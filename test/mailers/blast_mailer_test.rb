require 'test_helper'

class BlastMailerTest < ActionMailer::TestCase
  def blast_mail_preview
    BlastMailer.blast_email(User.first)
  end
end
