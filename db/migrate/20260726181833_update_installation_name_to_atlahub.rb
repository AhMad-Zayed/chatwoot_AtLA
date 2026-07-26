class UpdateInstallationNameToAtlahub < ActiveRecord::Migration[7.0]
  def up
    config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_NAME')
    config.value = 'AtlaHub'
    config.save

    GlobalConfig.clear_cache if defined?(GlobalConfig)
  end

  def down
    config = InstallationConfig.find_by(name: 'INSTALLATION_NAME')
    if config
      config.value = 'Chatwoot'
      config.save
    end

    GlobalConfig.clear_cache if defined?(GlobalConfig)
  end
end
