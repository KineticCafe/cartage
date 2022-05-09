# frozen_string_literal: true

require "tempfile"

# Manage and use the package manifest ('Manifest.txt') and the ignore file
# ('.cartignore').
class Cartage::Manifest < Cartage::Plugin
  # This exception is raised if the package manifest is missing.
  class MissingError < StandardError
    def message # :nodoc:
      <<~EXCEPTION
        Cartage cannot create a package without a Manifest.txt file. You may generate
        or update the Manifest.txt file with the following command:

            cartage manifest generate

      EXCEPTION
    end
  end

  DIFF = if system("gdiff", __FILE__, __FILE__) # :nodoc:
    "gdiff"
  else
    "diff"
  end

  # Resolve the Manifest to something that can be used by <tt>tar -T</tt>. The
  # manifest should be relative to the files in the repository, as reported
  # from <tt>git ls-files</tt>. +tar+ requires either full paths, or files
  # relative to the directory you are packaging from (and we want relative
  # files).
  #
  # This reads the manifest, prunes it with package ignores, and then writes it
  # in a GNU tar compatible format as a tempfile. It does this by taking the
  # expanded version of +path+, grabbing the basename, and inserting that in
  # front of every line in the Manifest.
  #
  # If +path+ is not provided, Dir.pwd is used.
  #
  # A block is required and is provided the +resolved_path+.
  def resolve(path = nil) # :yields: resolved_path
    fail MissingError unless manifest_file.exist?
    fail ArgumentError, "A block is required." unless block_given?

    data = strip_comments_and_empty_lines(manifest_file.readlines)
    fail "Manifest.txt is empty." if data.empty?

    path = Pathname(path || Dir.pwd).expand_path.basename
    tmpfile = Tempfile.new("Manifest.")

    tmpfile.puts prune(data, with_slugignore: true).map { |line|
      path.join(line).to_s
    }.join("\n")

    tmpfile.close

    yield tmpfile.path
  ensure
    if tmpfile
      tmpfile.close
      tmpfile.unlink
    end
  end

  # Generates Manifest.txt.
  def generate
    create_file_list(manifest_file)
  end

  # Checks Manifest.txt
  def check
    fail MissingError unless manifest_file.exist?
    tmp = create_file_list("Manifest.tmp")

    args = [DIFF, "-du", manifest_file.basename.to_s, tmp.to_s]

    if cartage.quiet
      `#{(args << "-q").join(" ")}`
    else
      system(*args)
    end

    $?.success?
  ensure
    tmp&.unlink
  end

  # Installs the default .cartignore file. Will either +overwrite+ or +merge+
  # based on the provided +mode+.
  def install_default_ignore(mode: nil)
    save = mode || !ignore_file.exist?

    if mode == "merge"
      cartage.display("Merging .cartignore...")
      data = strip_comments_and_empty_lines(ignore_file.readlines)

      if data.empty?
        data = DEFAULT_IGNORE
      else
        data += strip_comments_and_empty_lines(DEFAULT_IGNORE.split($/))
        data = data.uniq.join("\n")
      end
    elsif save
      cartage.display("Creating .cartignore...")
      data = DEFAULT_IGNORE
    else
      cartage.display(".cartignore already exists, skipping...")
    end

    ignore_file.write(data) if save
  end

  private

  def ignore_file
    @ignore_file ||= @cartage.root_path.join(".cartignore")
  end

  def slugignore_file
    @slugignore_file ||= @cartage.root_path.join(".slugignore")
  end

  def manifest_file
    @manifest_file ||= @cartage.root_path.join("Manifest.txt")
  end

  def create_file_list(filename)
    files = prune(`git ls-files`.split.map(&:chomp)).sort.uniq.join("\n")
    Pathname(filename).tap { |f| f.write("#{files}\n") }
  end

  def ignore_patterns(with_slugignore: false)
    pats = if ignore_file.exist?
      ignore_file.readlines
    elsif with_slugignore && slugignore_file.exist?
      slugignore_file.readlines
    else
      DEFAULT_IGNORE.split($/)
    end

    pats = strip_comments_and_empty_lines(pats)

    pats.map { |pat|
      if %r{\A/[^*?]+\z}.match?(pat)
        Regexp.new(%r{\A#{pat.sub(%r{\A/}, '')}/})
      elsif pat.end_with?("/")
        Regexp.new(/\A#{pat}/)
      else
        pat
      end
    }.compact
  end

  def strip_comments_and_empty_lines(list)
    list.map { |item|
      item = item.chomp.gsub(/(?:^|[^\\])#.*\z/, "").strip
      if item.empty?
        nil
      else
        item
      end
    }.compact
  end

  def prune(files, with_slugignore: false)
    exclusions = ignore_patterns(with_slugignore: with_slugignore)
    files.reject { |file| prune?(file, exclusions) }
  end

  def prune?(file, exclusions = ignore_patterns)
    exclusions.any? do |pat|
      case pat
      when /[*?]/
        File.fnmatch?(
          pat, file, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH
        )
      when Regexp
        file =~ pat
      else
        file == pat
      end
    end
  end

  DEFAULT_IGNORE = <<~'EOM' # :nodoc:
    # Some of these are in .gitignore, but let’s remove these just in case they got
    # checked in.

    # Exact files to remove. Matches with ==.
    .DS_Store
    .autotest
    .editorconfig
    .env
    .git-wtfrc
    .gitignore
    .local.vimrc
    .lvimrc
    .cartignore
    .powenv
    .rake_tasks~
    .rspec
    .rubocop.yml
    .rvmrc
    .semaphore-cache
    .workenv
    Guardfile
    README.md
    bin/build
    bin/notify-project-board
    bin/osx-bootstrap
    bin/setup

    # Patterns to remove. These have a *, **, or ? in them. Uses File.fnmatch with
    # File::FNM_DOTMATCH and File::FNM_EXTGLOB.
    *.rbc
    .*.swp
    **/.DS_Store

    # Directories to remove. These should end with a slash. Matches as the regular
    # expression %r{\A#{pattern}}.
    db/seeds/development/
    db/seeds/test/
    # db/seeds/dit/
    # db/seeds/staging/
    log/
    test/
    tests/
    rspec/
    spec/
    specs/
    feature/
    features/
    tmp/
    vendor/bundle/
  EOM
end
