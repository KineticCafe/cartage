# -*- encoding: utf-8 -*-
# stub: cartage 2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cartage"
  s.version = "2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler", "Kinetic Cafe"]
  s.date = "2017-02-18"
  s.description = "Cartage provides a repeatable means to create a package for a server-side\napplication that can be used in deployment with a configuration tool like\nAnsible, Chef, Puppet, or Salt. The package is created with vendored\ndependencies so that it can be deployed in environments with strict access\ncontrol rules and without requiring development tool presence on the target\nserver(s)."
  s.email = ["aziegler@kineticcafe.com", "dev@kineticcafe.com"]
  s.executables = ["cartage"]
  s.extra_rdoc_files = ["Cartage.yml.rdoc", "Contributing.md", "Extending.md", "History.md", "Licence.md", "Manifest.txt", "README.rdoc", "cartage-cli.md"]
  s.files = ["Cartage.yml.rdoc", "Contributing.md", "Extending.md", "History.md", "Licence.md", "Manifest.txt", "README.rdoc", "Rakefile", "bin/cartage", "cartage-cli.md", "cartage.yml.sample", "lib/cartage.rb", "lib/cartage/backport.rb", "lib/cartage/cli.rb", "lib/cartage/commands/echo.rb", "lib/cartage/commands/info.rb", "lib/cartage/commands/manifest.rb", "lib/cartage/commands/pack.rb", "lib/cartage/config.rb", "lib/cartage/core.rb", "lib/cartage/gli_ext.rb", "lib/cartage/minitest.rb", "lib/cartage/plugin.rb", "lib/cartage/plugins/build_tarball.rb", "lib/cartage/plugins/manifest.rb", "test/minitest_config.rb", "test/test_cartage.rb", "test/test_cartage_build_tarball.rb", "test/test_cartage_config.rb", "test/test_cartage_core.rb", "test/test_cartage_manifest.rb", "test/test_cartage_plugin.rb"]
  s.homepage = "https://github.com/KineticCafe/cartage/"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new("~> 2.0")
  s.rubygems_version = "2.5.1"
  s.summary = "Cartage provides a repeatable means to create a package for a server-side application that can be used in deployment with a configuration tool like Ansible, Chef, Puppet, or Salt"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<gli>, ["~> 2.13"])
      s.add_development_dependency(%q<minitest>, ["~> 5.10"])
      s.add_development_dependency(%q<rake>, ["< 12.0", ">= 10.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.2"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_development_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-bonus-assertions>, ["~> 2.0"])
      s.add_development_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_development_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_development_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<hoe>, ["~> 3.16"])
    else
      s.add_dependency(%q<gli>, ["~> 2.13"])
      s.add_dependency(%q<minitest>, ["~> 5.10"])
      s.add_dependency(%q<rake>, ["< 12.0", ">= 10.0"])
      s.add_dependency(%q<rdoc>, ["~> 4.2"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_dependency(%q<minitest-bonus-assertions>, ["~> 2.0"])
      s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<hoe>, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<gli>, ["~> 2.13"])
    s.add_dependency(%q<minitest>, ["~> 5.10"])
    s.add_dependency(%q<rake>, ["< 12.0", ">= 10.0"])
    s.add_dependency(%q<rdoc>, ["~> 4.2"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.5"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
    s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
    s.add_dependency(%q<minitest-bonus-assertions>, ["~> 2.0"])
    s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
    s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
    s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<hoe>, ["~> 3.16"])
  end
end
