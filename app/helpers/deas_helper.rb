module DeasHelper
  def group_droplet_versions(droplet, app)
    versions = {:current => [], :old => []}

    droplet.versions.inject(versions) do |h, version|
      if app && match = /^#{app.staged_package_hash}-(\d+)/.match(version.version)
        h[:current] << [version, match[1]]
      else
        h[:old] << [version, nil]
      end

      h
    end

    if versions[:current].count > 1
      current_version = versions[:current].max do |x,y|
        x[1] <=> y[1]
      end
      versions[:old] += versions[:current] - [current_version]
    else
      current_version = versions[:current].first
      versions[:old] -= current_version if current_version
    end

    yield(current_version[0], true) if current_version

    versions[:old].each do |version|
      yield(version[0], false)
    end
  end
end
