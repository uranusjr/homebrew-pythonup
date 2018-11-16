class Pylauncher < Formula
  desc "Python launcher for POSIX"
  homepage "https://github.com/uranusjr/pylauncher-posix"

  url "https://github.com/uranusjr/pylauncher-posix/archive/0.1.1.tar.gz"
  sha256 "a01f5bcfbe48dc247f48804a35ad351e92f244bfea1d5e087f82f1f2ba85aee1"

  depends_on "rust" => :build

  def install
    system "cargo", "install", "--root", prefix, "--path", "."
  end
end
