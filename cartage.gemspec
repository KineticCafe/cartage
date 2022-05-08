# -*- encoding: utf-8 -*-
# stub: cartage 2.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cartage".freeze
  s.version = "2.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "documentation_uri" => "http://www.rubydoc.info/github/KineticCafe/cartage/master", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/KineticCafe/cartage/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze, "Kinetic Cafe".freeze]
  s.date = "2022-05-08"
  s.description = "Cartage provides a repeatable means to create a package for a server-side\napplication that can be used in deployment with a configuration tool like\nAnsible, Chef, Puppet, or Salt. The package is created with vendored\ndependencies so that it can be deployed in environments with strict access\ncontrol rules and without requiring development tool presence on the target\nserver(s).\n\nThis repository will see minimal development moving forward given the move\ntoward Docker builders and deploys; it is likely that the only thing that will\neventually result from this repository is the new `cartage manifest` command\nthat satisfies `cartage-rack`.".freeze
  s.email = ["aziegler@kineticcafe.com".freeze, "dev@kineticcafe.com".freeze]
  s.executables = ["cartage".freeze]
  s.extra_rdoc_files = ["Cartage.yml.rdoc".freeze, "Contributing.md".freeze, "Extending.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "cartage-cli.md".freeze]
  s.files = ["Cartage.yml.rdoc".freeze, "Contributing.md".freeze, "Extending.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "bin/cartage".freeze, "cartage-cli.md".freeze, "cartage.yml.sample".freeze, "lib/cartage.rb".freeze, "lib/cartage/backport.rb".freeze, "lib/cartage/cli.rb".freeze, "lib/cartage/commands/echo.rb".freeze, "lib/cartage/commands/info.rb".freeze, "lib/cartage/commands/manifest.rb".freeze, "lib/cartage/commands/metadata.rb".freeze, "lib/cartage/commands/pack.rb".freeze, "lib/cartage/config.rb".freeze, "lib/cartage/core.rb".freeze, "lib/cartage/gli_ext.rb".freeze, "lib/cartage/minitest.rb".freeze, "lib/cartage/plugin.rb".freeze, "lib/cartage/plugins/build_tarball.rb".freeze, "lib/cartage/plugins/manifest.rb".freeze, "test/minitest_config.rb".freeze, "test/test_cartage.rb".freeze, "test/test_cartage_build_tarball.rb".freeze, "test/test_cartage_config.rb".freeze, "test/test_cartage_core.rb".freeze, "test/test_cartage_manifest.rb".freeze, "test/test_cartage_plugin.rb".freeze]
  s.homepage = "https://github.com/KineticCafe/cartage/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Cartage provides a repeatable means to create a package for a server-side application that can be used in deployment with a configuration tool like Ansible, Chef, Puppet, or Salt".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<gli>.freeze, ["~> 2.13"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15"])
    s.add_development_dependency(%q<rake>.freeze, [">= 10.0"])
    s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.2"])
    s.add_development_dependency(%q<hoe-doofus>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<hoe-git>.freeze, ["~> 1.5"])
    s.add_development_dependency(%q<hoe-travis>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<minitest-bisect>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<minitest-bonus-assertions>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<minitest-moar>.freeze, ["~> 0.0"])
    s.add_development_dependency(%q<minitest-pretty_diff>.freeze, ["~> 0.1"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_development_dependency(%q<hoe>.freeze, ["~> 3.23"])
  else
    s.add_dependency(%q<gli>.freeze, ["~> 2.13"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.15"])
    s.add_dependency(%q<rake>.freeze, [">= 10.0"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.2"])
    s.add_dependency(%q<hoe-doofus>.freeze, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>.freeze, ["~> 1.5"])
    s.add_dependency(%q<hoe-travis>.freeze, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>.freeze, ["~> 1.0"])
    s.add_dependency(%q<minitest-bisect>.freeze, ["~> 1.2"])
    s.add_dependency(%q<minitest-bonus-assertions>.freeze, ["~> 2.0"])
    s.add_dependency(%q<minitest-focus>.freeze, ["~> 1.1"])
    s.add_dependency(%q<minitest-moar>.freeze, ["~> 0.0"])
    s.add_dependency(%q<minitest-pretty_diff>.freeze, ["~> 0.1"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.23"])
  end
end
