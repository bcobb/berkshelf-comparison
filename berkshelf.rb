require 'chef/version_constraint'
require 'chef/exceptions'
require 'net/http'
require 'json'

classic = JSON.parse(Net::HTTP.get_response(URI('http://api.berkshelf.com/universe')).body)

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
  normalized_versions = versions.map do |version, details|
    normalized_version(version, details['dependencies'])
  end.sort_by { |v| v[:version] }

  {
    name: cookbook,
    versions: normalized_versions
  }
end.sort_by { |c| c[:name] }

puts JSON.dump(list)
