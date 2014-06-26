require 'chef/version_constraint'
require 'chef/exceptions'
require 'net/http'
require 'json'

classic = JSON.parse(Net::HTTP.get_response(URI('http://api.berkshelf.com/universe')).body)
supermarket = JSON.parse(Net::HTTP.get_response(URI('https://supermarket.getchef.com/universe')).body)

def normalized_version(version, dependencies)
  sorted_dependencies = dependencies.map do |name, constraint|
    [name, Chef::VersionConstraint.new(constraint)]
  end.sort_by(&:first)

  chef_version = Chef::Version.new(version) rescue version

  {
    version: chef_version,
    dependencies: sorted_dependencies
  }
end

list = classic.map do |cookbook, versions|
  supermarket_cookbook = supermarket[cookbook]

  if supermarket_cookbook
    normalized_versions = versions.select do |version, _|
      supermarket_cookbook.key?(version)
    end.map do |version, _|
      details = supermarket[cookbook][version]

      normalized_version(version, details['dependencies'])
    end.sort_by { |v| v[:version] }

    {
      name: cookbook,
      versions: normalized_versions
    }
  else
    {}
  end
end.reject(&:empty?).sort_by { |c| c[:name] }

puts JSON.dump(list)
