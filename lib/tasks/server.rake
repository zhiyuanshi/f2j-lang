desc "Start the Rails server using Unicorn instead of the default WEBrick"
task :server do
  port = ENV["PORT"] || "3000"
  system("unicorn -p #{port} -c config/unicorn.rb")
end

task :s => :server
