class AtlahubPlatformRelease < ApplicationRecord
  enum status: { draft: 0, published: 1 }

  validates :version, presence: true, uniqueness: true
end
