#
# A simple transformation of Puppet hash to YAML.
#

require 'yaml'

module Puppet::Parser::Functions
  newfunction(:hash2yml, :type => :rvalue, :doc => <<-EOS
    Returns a YAML data based on passed hash.
    EOS
  ) do |arguments|

    return arguments[0].to_yaml
  
  end
end

# vim: set ts=2 sw=2 et :
