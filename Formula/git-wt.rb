class GitWt < Formula
  desc "Git worktree add that never nests worktrees inside a checkout"
  homepage "https://github.com/tgrnd/git-wt"
  # Fetched with git; the revision pins the tag, so no sha256 is needed.
  url "https://github.com/tgrnd/git-wt.git",
      tag:      "v0.1.0",
      revision: "7d00fbe5064ef2f55fe9cceda87e2412d92b4177"
  license "MIT"
  head "https://github.com/tgrnd/git-wt.git", branch: "main"

  depends_on "jq"

  def install
    # The create hook finds git-wt beside itself, so keep them together in libexec.
    libexec.install "git-wt", "claude-worktree-create.sh", "claude-worktree-remove.sh"
    bin.install_symlink libexec/"git-wt"
  end

  def caveats
    <<~EOS
      To send Claude Code's worktrees through git-wt, add to ~/.claude/settings.json:
        "hooks": {
          "WorktreeCreate": [{ "hooks": [{ "type": "command", "command": "#{opt_libexec}/claude-worktree-create.sh" }] }],
          "WorktreeRemove": [{ "hooks": [{ "type": "command", "command": "#{opt_libexec}/claude-worktree-remove.sh" }] }]
        }
    EOS
  end

  test do
    ENV["GIT_WT_HOME"] = (testpath/"wt-home").to_s
    ENV["GIT_AUTHOR_NAME"] = ENV["GIT_COMMITTER_NAME"] = "test"
    ENV["GIT_AUTHOR_EMAIL"] = ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"
    system "git", "init", "--quiet", "repo"
    system "git", "-C", "repo", "commit", "--quiet", "--allow-empty", "-m", "init"

    cd "repo" do
      assert_match %r{/wt-home/repo-\h{8}/wt/a$}, shell_output("git wt path wt/a").chomp
    end

    input = { session_id: "s", transcript_path: "/dev/null", cwd: (testpath/"repo").to_s, name: "x" }.to_json
    created = pipe_output(libexec/"claude-worktree-create.sh", input).chomp
    assert_match %r{/wt-home/repo-\h{8}/x$}, created
    assert_path_exists "#{created}/.git"
  end
end
