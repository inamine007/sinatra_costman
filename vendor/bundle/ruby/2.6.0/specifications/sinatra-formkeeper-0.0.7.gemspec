# -*- encoding: utf-8 -*-
# stub: sinatra-formkeeper 0.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "sinatra-formkeeper".freeze
  s.version = "0.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["lyokato".freeze]
  s.date = "2013-05-02"
  s.description = "Sinatra extension which handles stuff around HTML forms".freeze
  s.email = ["lyo.kato@gmail.com".freeze]
  s.homepage = "https://github.com/lyokato/sinatra-formkeeper/".freeze
  s.rubygems_version = "3.0.3".freeze
  s.summary = "This module provides you a easy way for form-validation and fill-in-form".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<sinatra>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<formkeeper>.freeze, ["~> 0.0.12"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
    else
      s.add_dependency(%q<hpricot>.freeze, [">= 0"])
      s.add_dependency(%q<rack>.freeze, [">= 0"])
      s.add_dependency(%q<sinatra>.freeze, [">= 0"])
      s.add_dependency(%q<formkeeper>.freeze, ["~> 0.0.12"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<hpricot>.freeze, [">= 0"])
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<sinatra>.freeze, [">= 0"])
    s.add_dependency(%q<formkeeper>.freeze, ["~> 0.0.12"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
  end
end
