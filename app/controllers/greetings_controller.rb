class GreetingsController < ApplicationController
  def hello
  	@commit_message = commit_message
  end

  private

  def commit_message
    msg = nil
    Dir.chdir("../systemfcompiler") do
      msg = `hg log --branch default --limit 1`
    end
    msg
  end
end
