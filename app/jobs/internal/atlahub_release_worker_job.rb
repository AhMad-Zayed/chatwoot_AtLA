class Internal::AtlahubReleaseWorkerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    fetch_and_process_upstream
  end

  private

  def fetch_and_process_upstream
    response = RestClient.get('https://api.github.com/repos/chatwoot/chatwoot/releases/latest', { accept: 'application/vnd.github.v3+json' })
    parsed_response = JSON.parse(response.body)
    upstream_version = parsed_response['tag_name']
    upstream_notes = parsed_response['body']

    # Check if we already processed this upstream version
    return if AtlahubPlatformRelease.exists?(source_version: upstream_version)

    # Process with Gemini
    generate_release_via_gemini(upstream_version, upstream_notes)
  rescue StandardError => e
    Rails.logger.error "AtlaHub Release Worker Error: #{e.message}"
  end

  def generate_release_via_gemini(upstream_version, upstream_notes)
    current_atlahub = YAML.load_file(Rails.root.join('config/atlahub_release.yml'))['current_version'] || '1.0.0'
    api_key = ENV['GEMINI_API_KEY']
    
    unless api_key.present?
      Rails.logger.error "GEMINI_API_KEY is missing. Cannot generate AtlaHub release."
      return
    end

    prompt = <<~PROMPT
      You are AtlaHub Autonomous Release Manager.
      Responsibilities:
      1. Analyze upstream Chatwoot changes.
      2. Decide semantic version (Current AtlaHub Version is #{current_atlahub}):
         - MAJOR: breaking changes
         - MINOR: new features
         - PATCH: bug fixes/security fixes
      3. Create customer-friendly release name.
      4. Generate Arabic and English release notes in Markdown.
      5. Never mention Chatwoot, replace with AtlaHub. Remove all upstream trackers/policies.
      
      Output exactly as a JSON object:
      {
        "version": "1.X.X",
        "title": "Release Name...",
        "description_en": "Markdown...",
        "description_ar": "Markdown..."
      }
      
      Upstream Notes:
      #{upstream_notes}
    PROMPT

    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=#{api_key}"
    payload = {
      contents: [{ parts: [{ text: prompt }] }]
    }

    response = RestClient.post(url, payload.to_json, { content_type: :json, accept: :json })
    result = JSON.parse(response.body)
    text = result.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    # Strip markdown codeblocks if they exist
    text = text.gsub(/^```json\n/, '').gsub(/^```\n/, '').gsub(/\n```$/, '')
    parsed_content = JSON.parse(text.strip)

    AtlahubPlatformRelease.create!(
      version: parsed_content['version'],
      title: parsed_content['title'],
      description_en: parsed_content['description_en'],
      description_ar: parsed_content['description_ar'],
      source_version: upstream_version,
      status: :draft
    )
  end
end
