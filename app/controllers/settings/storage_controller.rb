module Settings
  class StorageController < ApplicationController
    def show
      authorize StorageSnapshot
      @snapshot = StorageSnapshot.latest_first.first
    end

    def refresh
      authorize StorageSnapshot, :refresh?
      StorageMonitorService.refresh!(actor: current_user)
      redirect_to settings_storage_path, notice: "Storage status refreshed."
    end
  end
end
