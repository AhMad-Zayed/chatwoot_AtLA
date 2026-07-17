module I18nWhiteLabelPatch
  def translate(*args)
    result = super(*args)
    if result.is_a?(String) && result.include?('Chatwoot')
      # Fetch INSTALLATION_NAME dynamically
      # Using begin/rescue just in case GlobalConfig isn't fully loaded or table doesn't exist
      begin
        installation_name = ENV.fetch('INSTALLATION_NAME', 'AtlaHub')
        if defined?(GlobalConfig) && GlobalConfig.respond_to?(:get)
          config_val = GlobalConfig.get('INSTALLATION_NAME')
          installation_name = config_val if config_val.present?
        end
        result.gsub('Chatwoot', installation_name)
      rescue StandardError
        result.gsub('Chatwoot', 'AtlaHub')
      end
    elsif result.is_a?(Array)
      result.map do |item|
        if item.is_a?(String) && item.include?('Chatwoot')
          begin
            installation_name = ENV.fetch('INSTALLATION_NAME', 'AtlaHub')
            if defined?(GlobalConfig) && GlobalConfig.respond_to?(:get)
              config_val = GlobalConfig.get('INSTALLATION_NAME')
              installation_name = config_val if config_val.present?
            end
            item.gsub('Chatwoot', installation_name)
          rescue StandardError
            item.gsub('Chatwoot', 'AtlaHub')
          end
        else
          item
        end
      end
    else
      result
    end
  end

  alias t translate
end

I18n.singleton_class.prepend(I18nWhiteLabelPatch)
