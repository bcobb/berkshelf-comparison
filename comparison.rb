require 'chef/version_constraint'
require 'chef/exceptions'
require 'net/http'
require 'json'

classic = JSON.parse(Net::HTTP.get_response(URI('http://api.berkshelf.com/universe')).body)
supermarket = JSON.parse(Net::HTTP.get_response(URI('https://supermarket.getchef.com/universe')).body)

analysis = classic.reduce({}) do |discrepancies, (cookbook, versions)|
  if supermarket.key?(cookbook)
    discrepancies[cookbook] ||= {}

    versions.reduce(discrepancies[cookbook]) do |cookbook_discrepancies, (version, details)|
      cookbook_discrepancies[version] = {
        'supermarket' => nil,
        'berkshelf' => {}
      }

      if supermarket[cookbook].key?(version)
        cookbook_discrepancies[version]['supermarket'] = supermarket[cookbook][version]['dependencies'].reduce({}) do |h, (dep, constraint)|
          h[dep] = Chef::VersionConstraint.new(constraint)
          h
        end
      end

      cookbook_discrepancies[version]['berkshelf'] = details['dependencies'].reduce({}) do |h, (dep, constraint)|
        h[dep] = Chef::VersionConstraint.new(constraint)
        h
      end

      cookbook_discrepancies
    end
  else
    discrepancies[cookbook] = 'MISSING'
  end

  discrepancies
end.map do |cookbook, versions|
  if versions == 'MISSING'
    {
      name: cookbook,
      identical: false,
      missing: true,
      versions: [],
      discrepancies: []
    }
  else
    identical = versions.all? do |version, details|
      details['supermarket'].to_a.sort_by(&:first) == details['berkshelf'].to_a.sort_by(&:first)
    end

    discrepancies = versions.reject do |_, details|
      details['supermarket'].to_a.sort_by(&:first) == details['berkshelf'].to_a.sort_by(&:first)
    end.map(&:first)

    {
      name: cookbook,
      identical: identical,
      versions: versions,
      missing: false,
      discrepancies: discrepancies
    }
  end
end.reject do |cookbook|
  cookbook[:identical]
end

puts JSON.dump(analysis)
