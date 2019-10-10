module ::Jobs
  class OnesignalPushNotification < Jobs::Base

    ONE_SIGNAL_API = 'https://onesignal.com/api/v1/notifications'.freeze

    def execute(args)
      payload = args["payload"]

      filters = [
          {"field": "tag", "key": "username", "relation": "=", "value": args["username"]}
      ]

      params = {
          "app_id" => SiteSetting.onesignal_app_id,
          "contents" => {"en" => "#{payload[:username]}: #{payload[:excerpt]}"},
          "headings" => {"en" => payload[:topic_title]},
          "data" => {"discourse_url" => payload[:post_url]},
          "ios_badgeType" => "Increase",
          "ios_badgeCount" => "1",
          "filters" => filters
      }

      uri = URI.parse(ONE_SIGNAL_API)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path,
                                    'Content-Type'  => 'application/json;charset=utf-8',
                                    'Authorization' => "Basic #{SiteSetting.onesignal_rest_api_key}")
      request.body = params.as_json.to_json
      response = http.request(request)

      case response
      when Net::HTTPSuccess then
        Rails.logger.info("Push notification sent via OneSignal to #{args['username']}.")
      else
        Rails.logger.error("OneSignal error")
        Rails.logger.error("#{request.to_yaml}")
        Rails.logger.error("#{response.to_yaml}")
      end

    end
  end
end
