class Pythonup < Formula
  desc "The Python Runtime Manager for macOS"
  homepage "https://github.com/uranusjr/pythonup-macos"

  head "https://github.com/uranusjr/pythonup-macos", :using => :git

  depends_on "pyenv"
  depends_on "python3"
  depends_on "readline"
  depends_on "xz"

  def install
    # Create a venv to collect dependencies.
    system HOMEBREW_PREFIX/"bin/python3", "-m", "venv", "./venv"

    # Dump Pipfile to requirements.txt with Pipfile API.
    system "./venv/bin/pip", "install", "pipfile"
    txt = `"./venv/bin/python" "tools/dump_requirements.py" "Pipfile"`
    File.open "requirements.txt", "w" { |f|
      f.write txt
    }
    system "./venv/bin/pip", "uninstall", "-y", "pipfile", "toml"

    # Install the dependencies.
    system "./venv/bin/pip", "install", "-r", "requirements.txt"

    # Collect dependencies into keg.
    system "mkdir", libexec
    Dir.glob("./venv/lib/*/site-packages/*") { |item|
      name = item.rpartition("/").last
      next if [
        ".", "..", "__pycache__",
        "easy_isntall.py", "pip", "pkg_resources", "setuptools",
      ].include? name
      next if name.end_with? ".dist-info"
      libexec.install item
    }

    # Copy pythonup package into keg.
    libexec.install "pythonup"

    # Generate launcher.
    File.open "pythonup", "w" { |f|
      f.write <<~EOS
\#!/bin/sh

VERSION="$(ls -1 '#{HOMEBREW_PREFIX}/Cellar/python3' | tail -n1)"
PYTHON="#{HOMEBREW_PREFIX}/Cellar/python3/$VERSION/bin/python3"

PYTHONPATH="#{libexec}:$PATHONPATH" exec "$PYTHON" -m pythonup $@
EOS
    }

    # Install the launcher.
    system "mkdir", bin
    bin.install "pythonup"
  end
end
