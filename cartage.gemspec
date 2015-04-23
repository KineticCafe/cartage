# -*- encoding: utf-8 -*-
# stub: cartage 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cartage"
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2015-04-23"
  s.description = "Cartage provides a plug-in based tool to reliably create a package for a\nBundler-based Ruby application that can be used in deployment with a\nconfiguration tool like Ansible, Chef, Puppet, or Salt. The package is created\nwith its dependencies bundled in +vendor/bundle+, so it can be deployed in\nenvironments with strict access control rules and without requiring development\ntool access.\n\nCartage has learned its tricks from Heroku, Capistrano, and Hoe. From Hoe, it\nlearned to keep a manifest to control what is packaged (as well as its plug-in\nsystem). From Heroku, it learned to keep a simple ignore file. From Capistrano,\nit learned to mark the Git hashref as a file in its built package, and to\ntimestamp the packages.\n\nCartage follows a relatively simple set of steps when creating a package:\n\n1.  Copy the application files to the work area. The application\u{2019}s files are\n    specified in +Manifest.txt+ and filtered against the exclusion list\n    (+.cartignore+). If there is no +.cartignore+, try to use +.slugignore+. If\n    there is no +.slugignore+, Cartage will use a sensible default exclusion\n    list. To override the use of this exclusion list, an empty +.cartignore+\n    file must be present.\n\n2.  The Git hashref is written to the work area (as +release_hashref+) and to\n    the package staging area.\n\n3.  Files that have been modified are restored to pristine condition in the\n    work area. The source files are not touched. (This ensures that\n    +config/database.yml+, for example, will not be the version used by a\n    continuous integration system.)\n\n4.  Bundler is fetched into the work area, and the bundle is installed into the\n    work area\u{2019}s +vendor/bundle+ without the +development+ and +test+\n    environments. If a bundle cache is kept (by default, one is), the resulting\n    +vendor/bundle+ will be put into a bundle cache so that future bundle\n    installs are faster.\n\n5.  A timestamped tarball is created from the contents of the work area. It can\n    then be copied to a more permanent or accessible location.\n\nCartage is extremely opinionated about its tools and environment:\n\n* The packages are created with +tar+ and +bzip2+ using <tt>tar cfj</tt>.\n* Cartage only understands +git+, which is used for creating\n  <tt>release_hashref</tt>s, +Manifest.txt+ creation and comparison, and even\n  default application name detection (from the name of the origin remote)."
  s.email = ["aziegler@kineticcafe.com"]
  s.executables = ["cartage"]
  s.extra_rdoc_files = ["Cartage.yml.rdoc", "Contributing.rdoc", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Cartage.yml.rdoc", "Contributing.rdoc", "History.rdoc", "Licence.rdoc", "README.rdoc"]
  s.files = [".autotest", ".gemtest", ".minitest.rb", ".travis.yml", "Cartage.yml.rdoc", "Contributing.rdoc", "Gemfile", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "bin/cartage", "cartage.yml.sample", "lib/cartage.rb", "lib/cartage/command.rb", "lib/cartage/config.rb", "lib/cartage/manifest.rb", "lib/cartage/manifest/commands.rb", "lib/cartage/pack_command.rb", "lib/cartage/plugin.rb", "test/minitest_config.rb", "test/test_cartage.rb", "test/test_cartage_config.rb"]
  s.homepage = "https://github.com/KineticCafe/cartage/"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.rubygems_version = "2.2.3"
  s.summary = "Cartage provides a plug-in based tool to reliably create a package for a Bundler-based Ruby application that can be used in deployment with a configuration tool like Ansible, Chef, Puppet, or Salt"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cmdparse>, ["~> 3.0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.6"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_development_dependency(%q<hoe-geminabox>, ["~> 0.3"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_development_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_development_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_development_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<cmdparse>, ["~> 3.0"])
      s.add_dependency(%q<minitest>, ["~> 5.6"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_dependency(%q<hoe-geminabox>, ["~> 0.3"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<cmdparse>, ["~> 3.0"])
    s.add_dependency(%q<minitest>, ["~> 5.6"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.5"])
    s.add_dependency(%q<hoe-geminabox>, ["~> 0.3"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
    s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
    s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
    s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
    s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
