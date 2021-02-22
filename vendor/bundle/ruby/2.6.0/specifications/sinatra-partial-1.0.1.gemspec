# -*- encoding: utf-8 -*-
# stub: sinatra-partial 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "sinatra-partial".freeze
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Schneider".freeze, "Sam Elliott".freeze, "Iain Barnett".freeze]
  s.date = "2017-07-28"
  s.description = "Just the partials helper in a gem. That is all.".freeze
  s.email = ["iainspeed@gmail.com".freeze]
  s.homepage = "https://github.com/yb66/Sinatra-Partial".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A sinatra extension for render partials.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sinatra>.freeze, [">= 1.4"])
    else
      s.add_dependency(%q<sinatra>.freeze, [">= 1.4"])
    end
  else
    s.add_dependency(%q<sinatra>.freeze, [">= 1.4"])
  end
end
