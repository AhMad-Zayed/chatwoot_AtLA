class CreateAtlahubPlatformReleases < ActiveRecord::Migration[7.0]
  def change
    create_table :atlahub_platform_releases do |t|
      t.string :version, null: false
      t.string :title
      t.text :description_en
      t.text :description_ar
      t.string :source_version
      t.integer :status, default: 0
      t.datetime :published_at

      t.timestamps
    end
    
    add_index :atlahub_platform_releases, :version, unique: true
  end
end
