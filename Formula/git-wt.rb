class GitWt < Formula
  desc "Git worktree add that never nests worktrees inside a checkout"
  homepage "https://github.com/tgrnd/git-wt"
  # Fetched with git; the revision pins the tag, so no sha256 is needed.
  url "https://github.com/tgrnd/git-wt.git",
      tag:      "v0.2.0",
      revision: "49217f56ac204d39338cbdaed7d4759515575a3c"
  license "MIT"
  head "https://github.com/tgrnd/git-wt.git", branch: "main"

  def install
    bin.install "git-wt"
  end

  test do
    ENV["GIT_WT_HOME"] = (testpath/"wt-home").to_s
    ENV["GIT_AUTHOR_NAME"] = ENV["GIT_COMMITTER_NAME"] = "test"
    ENV["GIT_AUTHOR_EMAIL"] = ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"
    system "git", "init", "--quiet", "repo"
    system "git", "-C", "repo", "commit", "--quiet", "--allow-empty", "-m", "init"

    cd "repo" do
      assert_match %r{/wt-home/repo-\h{8}/wt/a$}, shell_output("git wt path wt/a").chomp
      system "git", "wt", "add", "--quiet", "wt/b"
      created = shell_output("git wt path wt/b").chomp
      assert_path_exists "#{created}/.git"
      refute_path_exists "wt/b"
    end
  end
end
