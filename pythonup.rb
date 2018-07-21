class Pythonup < Formula
  desc "The Python Runtime Manager for POSIX"
  homepage "https://github.com/uranusjr/pythonup-posix"

  head "https://github.com/uranusjr/pythonup-posix.git", :using => :git

  depends_on "pyenv"
  depends_on "python3"
  depends_on "readline"
  depends_on "xz"

  def python3
    prefix = HOMEBREW_PREFIX/"Cellar/python3"
    if not File.directory? prefix   # Homebrew merged 2 and 3 formulae.
      prefix = HOMEBREW_PREFIX/"Cellar/python"
    end
    prefix/Dir.entries(prefix).sort_by(&:downcase).last/"bin/python3"
  end

  def install
    # Create a venv to dump information from Pipfile to requirements.txt.
    ohai "Collecting requirements"
    system python3, "-m", "venv", "./venv", "--clear"
    system "./venv/bin/pip", "install", "requirementslib~=1.0"
    txt = `"./venv/bin/python" "tools/dump_requirements.py" ""`
    raise RuntimeError, 'cannot dump requirements' if txt.nil? || txt.empty?
    File.open "requirements.txt", "w" do |f|
      f.write txt
    end

    # Create a new venv to actually collect dependencies.
    system python3, "-m", "venv", "./venv", "--clear"
    excludes = Dir.glob "./venv/lib/*/site-packages/*"
    system "./venv/bin/pip", "install", "-r", "requirements.txt"

    # Collect dependencies into keg.
    Dir.glob("./venv/lib/*/site-packages/*") { |item|
      name = item.rpartition("/").last
      next if excludes.include? item or name.end_with? ".dist-info"
      libexec.install item
    }

    # Copy pythonup package into keg.
    libexec.install "pythonup"

    # Generate launcher.
    ohai "Generating launcher"
    File.open "pythonup", "w" do |f|
      f.write <<~EOS
\#!/bin/sh

VERSION="$(ls -1 '#{HOMEBREW_PREFIX}/Cellar/python3' | tail -n1)"
PYTHON="#{HOMEBREW_PREFIX}/Cellar/python3/$VERSION/bin/python3"

PYTHONPATH="#{libexec}:$PATHONPATH" exec "$PYTHON" -m pythonup $@
EOS
    end

    # Install the launcher.
    bin.install "pythonup"
  end

  def caveats; <<~EOS
    You should configure your shell to add the following paths to your PATH:
        $HOME/Library/PythonUp/bin
        $HOME/Library/PythonUp/cmd
    EOS
  end
end
