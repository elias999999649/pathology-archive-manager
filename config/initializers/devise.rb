Devise.setup do |config|
  config.mailer_sender = "no-reply@pathology-archive.local"
  config.parent_mailer = "ActionMailer::Base"
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.reconfirmable = true
  config.password_length = 12..128
  config.expire_all_remember_me_on_sign_out = true
  config.stretches = Rails.env.test? ? 1 : 12
end
