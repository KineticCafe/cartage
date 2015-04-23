require 'tempfile'
# Manage and use the package manifest ('Manifest.txt') and the ignore file
# ('.cartignore').
class Cartage::Manifest < Cartage::Plugin
  # This exception is raised if the package manifest is missing.
  MissingError = Class.new(StandardError) do
    def message
      <<-exception
Cartage cannot create a package without a Manifest.txt file. You may generate
or update the Manifest.txt file with the following command:

      exception
    end
  end

  DIFF     = if system('gdiff', __FILE__, __FILE__) #:nodoc:
               'gdiff'
             else
               'diff'
             end

  def initialize(cartage) #:nodoc:
    @cartage = cartage
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
  def resolve(path = nil, command: nil) # :yields: resolved manifest filename
    raise MissingError unless manifest_file.exist?

    data = strip_comments_and_empty_lines(manifest_file.readlines)
    raise "Manifest.txt is empty." if data.empty?

    path = Pathname(path || Dir.pwd).expand_path.basename
    tmpfile = Tempfile.new('Manifest')

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
    raise MissingError unless manifest_file.exist?
    tmp = create_file_list('Manifest.tmp')
    system(DIFF, '-du', manifest_file.basename.to_s, tmp.to_s)
    $?.success?
  ensure
    tmp.unlink if tmp
  end

  # Installs the default .cartignore file.
  def install_default_ignore(mode: nil)
    mode = mode.to_s.downcase.strip
    save = mode || !ignore_file.exist?

    if mode == :merge
      data = strip_comments_and_empty_lines(ignore_file.readlines)

      if data.empty?
        data = DEFAULT_IGNORE
      else
        data += strip_comments_and_empty_lines(DEFAULT_IGNORE.split($/))
        data = data.uniq.join("\n")
      end
    else
      data = DEFAULT_IGNORE
    end

    ignore_file.open('w') { |f| f.puts data } if save
  end

  private

  def ignore_file
    @ignore_file ||= @cartage.root_path.join('.cartignore')
  end

  def slugignore_file
    @slugignore_file ||= @cartage.root_path.join('.slugignore')
  end

  def manifest_file
    @manifest_file ||= @cartage.root_path.join('Manifest.txt')
  end

  def create_file_list(filename)
    Pathname(filename).tap { |file|
      file.open('w') { |f|
        f.puts prune(%x(git ls-files).split.map(&:chomp)).sort.uniq.join("\n")
      }
    }
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
      if pat =~ %r{/\z}
        Regexp.new(%r{\A#{pat}})
      elsif pat =~ %r{\A/[^*?]+\z}
        Regexp.new(%r{\A#{pat.sub(%r{\A/}, '')}/})
      else
        pat
      end
    }.compact
  end

  def strip_comments_and_empty_lines(list)
    list.map { |item|
      item = item.chomp.gsub(/(?:^|[^\\])#.*\z/, '').strip
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

  def prune?(file, exclusions = ignore_patterns())
    exclusions.any? do |pat|
      case pat
      when /[*?]/
        File.fnmatch?(pat, file, File::FNM_PATHNAME | File::FNM_EXTGLOB |
                      File::FNM_DOTMATCH)
      when Regexp
        file =~ pat
      else
        file == pat
      end
    end
  end

  DEFAULT_IGNORE = <<-'EOM' #:nodoc:
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
tmp/
vendor/bundle/
  EOM
end

require_relative 'manifest/commands'
