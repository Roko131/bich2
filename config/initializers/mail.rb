ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => ENV['SENDGRID_USERNAME'],
  :password       => ENV['SENDGRID_PASSWORD'],
  # :domain         => Bich::DOMAIN,
  :domain         => "#{ENV['APP_NAME'] || 'because-i-can-hear'}.onrender.com",
  :enable_starttls_auto => true
}
