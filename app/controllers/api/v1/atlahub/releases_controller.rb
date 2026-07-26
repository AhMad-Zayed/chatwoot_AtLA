class Api::V1::Atlahub::ReleasesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user, raise: false

  def latest
    # Get the latest published release by ID or published_at
    latest_release = AtlahubPlatformRelease.where(status: :published).order(created_at: :desc).first

    if latest_release
      render json: {
        version: latest_release.version,
        title: latest_release.title,
        description_en: latest_release.description_en,
        description_ar: latest_release.description_ar,
        release_notes_url: "https://atlahub.tech/releases/#{latest_release.version}"
      }
    else
      render json: { version: "1.0.0" }
    end
  end
end
