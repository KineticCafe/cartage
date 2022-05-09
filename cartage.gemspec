# stub: cartage 2.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cartage".freeze
  s.version = "2.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = {"documentation_uri" => "http://www.rubydoc.info/github/KineticCafe/cartage/master", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/KineticCafe/cartage/"} if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze, "Kinetic Cafe".freeze]
  s.description = "Cartage provides a repeatable means to create a package for a server-side\napplication that can be used in deployment with a configuration tool like\nAnsible, Chef, Puppet, or Salt. The package is created with vendored\ndependencies so that it can be deployed in environments with strict access\ncontrol rules and without requiring development tool presence on the target\nserver(s).\n\nThis is the last release of cartage. It's been a fun ride, but Docker-based\nimages are our future at Kinetic Commerce. There is one feature that remains\nuseful, the release-metadata output. We have created a new, more extensible\nformat for which we will be creating a gem to manage this. One example of the\nimplementation can be found at:\n\nhttps://github.com/KineticCafe/release-metadata-ts\n\nWe will also be replacing `cartage-rack` with a new gem supporting this new\nformat.".freeze
  s.email = ["aziegler@kineticcafe.com".freeze, "dev@kineticcafe.com".freeze]
  s.executables = ["cartage".freeze]
  s.extra_rdoc_files = ["Cartage.yml.rdoc".freeze, "Contributing.md".freeze, "Extending.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "cartage-cli.md".freeze]
  s.files = ["Cartage.yml.rdoc".freeze, "Contributing.md".freeze, "Extending.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "bin/cartage".freeze, "cartage-cli.md".freeze, "cartage.yml.sample".freeze, "lib/cartage.rb".freeze, "lib/cartage/backport.rb".freeze, "lib/cartage/cli.rb".freeze, "lib/cartage/commands/echo.rb".freeze, "lib/cartage/commands/info.rb".freeze, "lib/cartage/commands/manifest.rb".freeze, "lib/cartage/commands/metadata.rb".freeze, "lib/cartage/commands/pack.rb".freeze, "lib/cartage/config.rb".freeze, "lib/cartage/core.rb".freeze, "lib/cartage/gli_ext.rb".freeze, "lib/cartage/minitest.rb".freeze, "lib/cartage/plugin.rb".freeze, "lib/cartage/plugins/build_tarball.rb".freeze, "lib/cartage/plugins/manifest.rb".freeze, "test/minitest_config.rb".freeze, "test/test_cartage.rb".freeze, "test/test_cartage_build_tarball.rb".freeze, "test/test_cartage_config.rb".freeze, "test/test_cartage_core.rb".freeze, "test/test_cartage_manifest.rb".freeze, "test/test_cartage_plugin.rb".freeze]
  s.homepage = "https://github.com/KineticCafe/cartage/".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "This is the last release of cartage. It's been a fun ride, but Docker-\nbased images are our future at Kinetic Commerce. There is one feature\nthat remains useful, the release-metadata output. We have created a\nnew, more extensible format for which we will be creating a gem to\nmanage this. One example of the implementation can be found at:\n\n  https://github.com/KineticCafe/release-metadata-ts\n\nWe will also be replacing `cartage-rack` with a new gem supporting\nthis new format.\n".freeze
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Cartage provides a repeatable means to create a package for a server-side application that can be used in deployment with a configuration tool like Ansible, Chef, Puppet, or Salt".freeze

  if s.respond_to? :specification_version
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency
    s.add_runtime_dependency("gli".freeze, ["~> 2.13"])
    s.add_development_dependency("minitest".freeze, ["~> 5.15"])
    s.add_development_dependency("rake".freeze, [">= 10.0"])
    s.add_development_dependency("rdoc".freeze, ["~> 6.4"])
    s.add_development_dependency("hoe-doofus".freeze, ["~> 1.0"])
    s.add_development_dependency("hoe-gemspec2".freeze, ["~> 1.1"])
    s.add_development_dependency("hoe-git".freeze, ["~> 1.5"])
    s.add_development_dependency("hoe-travis".freeze, ["~> 1.2"])
    s.add_development_dependency("minitest-autotest".freeze, ["~> 1.0"])
    s.add_development_dependency("minitest-bisect".freeze, ["~> 1.2"])
    s.add_development_dependency("minitest-bonus-assertions".freeze, ["~> 3.0"])
    s.add_development_dependency("minitest-focus".freeze, ["~> 1.1"])
    s.add_development_dependency("minitest-moar".freeze, ["~> 0.0"])
    s.add_development_dependency("minitest-pretty_diff".freeze, ["~> 0.1"])
    s.add_development_dependency("simplecov".freeze, ["~> 0.7"])
    s.add_development_dependency("hoe".freeze, ["~> 3.23"])
  else
    s.add_dependency("gli".freeze, ["~> 2.13"])
    s.add_dependency("minitest".freeze, ["~> 5.15"])
    s.add_dependency("rake".freeze, [">= 10.0"])
    s.add_dependency("rdoc".freeze, ["~> 6.4"])
    s.add_dependency("hoe-doofus".freeze, ["~> 1.0"])
    s.add_dependency("hoe-gemspec2".freeze, ["~> 1.1"])
    s.add_dependency("hoe-git".freeze, ["~> 1.5"])
    s.add_dependency("hoe-travis".freeze, ["~> 1.2"])
    s.add_dependency("minitest-autotest".freeze, ["~> 1.0"])
    s.add_dependency("minitest-bisect".freeze, ["~> 1.2"])
    s.add_dependency("minitest-bonus-assertions".freeze, ["~> 3.0"])
    s.add_dependency("minitest-focus".freeze, ["~> 1.1"])
    s.add_dependency("minitest-moar".freeze, ["~> 0.0"])
    s.add_dependency("minitest-pretty_diff".freeze, ["~> 0.1"])
    s.add_dependency("simplecov".freeze, ["~> 0.7"])
    s.add_dependency("hoe".freeze, ["~> 3.23"])
  end
end
