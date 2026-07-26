class SuperAdmin::AtlahubReleasesController < SuperAdmin::ApplicationController
  def index
    @releases = AtlahubPlatformRelease.order(created_at: :desc)
    @upstream_version = ::Redis::Alfred.get(::Redis::Alfred::LATEST_CHATWOOT_VERSION) || 'Fetching...'
  end

  def publish
    @release = AtlahubPlatformRelease.find(params[:id])
    if @release.update(status: :published, published_at: Time.current)
      redirect_to super_admin_atlahub_releases_path, notice: "AtlaHub Release #{@release.version} has been published successfully."
    else
      redirect_to super_admin_atlahub_releases_path, alert: "Failed to publish release."
    end
  end
end
