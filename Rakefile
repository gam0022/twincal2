task :preview do
  require 'webrick'
  include WEBrick

  module WEBrick::HTTPServlet
    FileHandler.add_handler('rb', CGIHandler)
  end

  s = HTTPServer.new(
    :Port => 3000,
    #:DocumentRoot => File.join(Dir.pwd, "/html")
    :DocumentRoot => File.join(Dir.pwd),
    :DirectoryIndex => ['index.rb']
  )
  trap("INT") { s.shutdown }
  s.start
end

task :deploy do
  # TODO: サーバーの設定は config ファイルに書くようにする
  puts `rsync -avze 'ssh -p 3843' --delete --exclude '*.log' ./ root@gam0022.net:/var/www/html/app/twincal`
end
