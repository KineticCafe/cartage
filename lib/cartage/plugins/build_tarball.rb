# frozen_string_literal: true

##
# Create the release package as a tarball.
#
# Offers:
# *  +:build_package+
class Cartage::BuildTarball < Cartage::Plugin
  # Create the package.
  #
  # Requests:
  # *  +:pre_build_tarball+
  # *  +:post_build_tarball+
  def build_package
    cartage.plugins.request(:pre_build_tarball)
    run_command
    cartage.plugins.request(:post_build_tarball)
  end

  # The final tarball name.
  def package_name
    @package_name ||=
      Pathname("#{cartage.final_name}.tar#{cartage.tar_compression_extension}")
  end

  private

  def run_command
    command = [
      "tar",
      "cf#{cartage.tar_compression_flag}",
      package_name.to_s,
      "-C",
      cartage.tmp_path.to_s,
      cartage.name
    ]

    cartage.run command
  end
end
