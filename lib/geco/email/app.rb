require 'sinatra/base'
require 'fulcrum'
require 'pony'

class Geco
  class Email
    class App < Sinatra::Base
      require 'json'

      # Idea from http://www.recursion.org/2011/7/21/modular-sinatra-foreman
      configure do
        set :app_file, __FILE__
        set :port, ENV['PORT']
      end

      post '/' do
        request.body.rewind
        post_body = request.body.read

        payload = JSON.parse post_body

        is_record_create = payload['type'] == 'record.create'
        return unless is_record_create

        has_payload_data = payload['data']
        return unless has_payload_data

        form_id = payload['data']['form_id']

        is_form_we_want = form_id == expected_form_id
        return unless is_form_we_want

        record_id = payload['data']['id']

        emails.each do |email|
          next if email.blank?
          send_email(email, "New GeCo 2014 Happening: #{url_to_send(record_id)}")
        end

        "Success"
      end

    private
      def api
        @api ||= Fulcrum::Client.new api_key
      end

      def api_key
        ENV['EMAIL_FULCRUM_API_KEY']
      end

      def expected_form_id
        ENV['EMAIL_FULCRUM_FORM_ID']
      end

      def alert_form_id
        ENV['EMAIL_FULCRUM_ALERTS_FORM_ID']
      end

      def url_to_send(record_id)
        url_base+record_id
      end

      def url_base
        'http://geco.herokuapp.com/?record_id='
      end

      def emails
        records_of_people_to_alert.map{|r| r['form_values'][email_field_key]}
      end

      def email_field_key
        ENV['EMAIL_FULCRUM_EMAIL_FIELD_KEY']
      end

      def records_of_people_to_alert
        api.records.all(form_id: alert_form_id).objects
      end

      def send_email(email, message)
        Pony.mail({
          to:  email,
          subject: "[Alert] New GeCo in the Rockies 2014 Happening!",
          body: message,
          from: 'kyle@sni.io',
          via: :smtp,
          via_options: {
            address: 'smtp.sendgrid.net',
            port: '587',
            domain: 'heroku.com',
            user_name: ENV['SENDGRID_USERNAME'],
            password: ENV['SENDGRID_PASSWORD'],
            authentication: :plain,
            enable_starttls_auto: true
          }
        })
      end

      run! if app_file == $0
    end
  end
end

