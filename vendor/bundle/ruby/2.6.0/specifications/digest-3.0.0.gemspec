# -*- encoding: utf-8 -*-
# stub: digest 3.0.0 ruby lib
# stub: ext/digest/extconf.rb ext/digest/bubblebabble/extconf.rb ext/digest/md5/extconf.rb ext/digest/rmd160/extconf.rb ext/digest/sha1/extconf.rb ext/digest/sha2/extconf.rb

Gem::Specification.new do |s|
  s.name = "digest".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "msys2_mingw_dependencies" => "openssl" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akinori MUSHA".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-12-18"
  s.description = "Provides a framework for message digest libraries.".freeze
  s.email = ["knu@idaemons.org".freeze]
  s.extensions = ["ext/digest/extconf.rb".freeze, "ext/digest/bubblebabble/extconf.rb".freeze, "ext/digest/md5/extconf.rb".freeze, "ext/digest/rmd160/extconf.rb".freeze, "ext/digest/sha1/extconf.rb".freeze, "ext/digest/sha2/extconf.rb".freeze]
  s.files = ["ext/digest/bubblebabble/extconf.rb".freeze, "ext/digest/extconf.rb".freeze, "ext/digest/md5/extconf.rb".freeze, "ext/digest/rmd160/extconf.rb".freeze, "ext/digest/sha1/extconf.rb".freeze, "ext/digest/sha2/extconf.rb".freeze]
  s.homepage = "https://github.com/ruby/digest".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Provides a framework for message digest libraries.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rake-compiler>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rake-compiler>.freeze, [">= 0"])
  end
end
