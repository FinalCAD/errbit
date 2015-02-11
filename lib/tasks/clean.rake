desc <<-DESC
  Resolves problems that didnt occur for x weeks
  bundle exec rake cleanup['1']
  heroku run rake "cleanup['1'] --trace -a finalcloud-errbit
DESC
task :cleanup, :weeks do |t, args|
  args.each { |k, v| puts "#{k} => #{v}" }
  offset = args.weeks ? args.weeks.to_i.weeks.ago : 3.weeks.ago
  puts "Clean problems older than #{offset}"
  Rake::Task[:environment].invoke

  Problem.where(:updated_at.lt => offset).map(&:resolve!)
  Notice.where(:updated_at.lt => offset).destroy_all
end
