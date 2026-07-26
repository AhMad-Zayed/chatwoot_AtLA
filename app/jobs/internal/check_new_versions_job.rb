class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Rails.env.production?

    fetch_latest_version_from_atlahub
  end

  private

  def fetch_latest_version_from_atlahub
    # Fetch from AtlaHub public API as the single source of truth
    response = RestClient.get('https://api.atlahub.tech/api/v1/atlahub/releases/latest', { accept: :json })
    parsed_response = JSON.parse(response.body)
    version = parsed_response['version']

    return if version.blank?

    ::Redis::Alfred.set(::Redis::Alfred::LATEST_CHATWOOT_VERSION, version)
  rescue StandardError => e
    Rails.logger.error "Exception fetching version: #{e.message}"
  end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
