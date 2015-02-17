namespace :merge do

  desc <<-DESC
    Merge uniq problem based on message
    bundle exec rake merge:problem['message']
    heroku run rake "merge:problem['message']" --trace -a finalcloud-errbit
  DESC
  task :problem, :message do |t, args|
    args.each { |k, v| puts "#{k} => #{v}" }
    unless args.message
      puts 'You must provided an message'
      exit 1
    end
    Rake::Task[:environment].invoke
    begin
      selected_problems = Problem.where(message: Regexp.new(args.message)).order_by(:created_at.desc).to_a
      merged_problem    = selected_problems.first # Most recent
      ProblemMerge.new(selected_problems).merge
      merged_problem.unresolve!
      puts "#{selected_problems.size} merged"
    rescue ArgumentError => e
      if e.message =~ /need almost 2 uniq different problems/
        puts "You have only one entry"
      else
        raise
      end
    end
  end

  desc <<-DESC
    Merge all problems based on RULES { problems: [] }.to_json
    bundle exec rake merge:problems
    heroku run rake "merge:problems" --trace -a finalcloud-errbit
  DESC
  task :problems do |args|
    require 'json'
    JSON.parse(ENV['RULES'])['problems'].each do |rule|
      begin
        Rake::Task['merge:problem'].invoke(rule)
      rescue
        next
      ensure
        Rake::Task['merge:problem'].reenable
      end
    end
  end

  namespace :reference do
    desc <<-DESC
      Sometime the message content special caracter, double space, break line, you need to know the real content.
      bundle exec rake merge:reference:problem['id']
      heroku run rake "merge:reference:problem['id']" --trace -a finalcloud-errbit
    DESC
    task :problem, :id do |t, args|
      unless args.id
        puts 'You must provided an id'
        exit 1
      end
      Rake::Task[:environment].invoke
      begin
        p("Title : '#{Problem.find(args.id).message}'")
      rescue Mongoid::Errors::DocumentNotFound
        puts "There aren't record for this id"
      end
    end
  end

end
