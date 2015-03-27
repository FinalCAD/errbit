require 'redis'

namespace :merge do
  
  desc <<-DESC
    Import
    bundle exec rake merge:import
    heroku run rake "merge:import" --trace -a finalcloud-errbit
  DESC
  task :import do |args|
    require 'json'
    JSON.parse(ENV['RULES'])['problems'].each_with_index do |rule, index|
      puts "#{index}. add : #{rule}"
      redis.sadd('rules', rule)
    end
  end

  desc <<-DESC
    Merge problems based on title:
    bundle exec rake merge:problem['title']
    heroku run rake "merge:problem['title']" --trace -a finalcloud-errbit
  DESC
  task :problem, :title do |t, args|
    args.each { |k, v| puts "#{k} => #{v}" }
    unless args.title
      puts 'You must provided a title'
      exit 1
    end
    Rake::Task[:environment].invoke
    begin
      selected_problems = Problem.where(title: Regexp.new(args.title)).order_by(:created_at.desc).to_a
      merged_problem    = selected_problems.first # Most recent
      ProblemMerge.new(selected_problems).merge
      merged_problem.unresolve!
      puts "#{selected_problems.size} merged"
    rescue ArgumentError => e
      if e.title =~ /need almost 2 uniq different problems/
        puts "Nothing to merge, exists only one entry for this title"
      else
        raise
      end
    end
  end

  desc <<-DESC
    Show rules
    bundle exec rake merge:rules
    heroku run rake "merge:rules" --trace -a finalcloud-errbit
  DESC
  task :rules do |args|
    require 'json'
    JSON.parse(ENV['RULES'])['problems'].each_with_index do |rule, index|
      puts "#{index}. #{rule}"
    end
  end

  desc <<-DESC
    Add rule
    bundle exec rake merge:add['rule']
    heroku run rake "merge:add['rule']" --trace -a finalcloud-errbit
  DESC
  task :add, :rule do |t, args|
    args.each { |k, v| puts "#{k} => #{v}" }
    unless args.rule
      puts 'You must provided an message'
      exit 1
    end
    redis.sadd('rules', rule)
    puts 'rule added, perform rake merge:problems for fixing existing duplication'
  end

  desc <<-DESC
    Merge all problems based on RULES { problems: [] }.to_json
    bundle exec rake merge:problems
    heroku run rake "merge:problems" --trace -a finalcloud-errbit
  DESC
  task :problems do |args|
    redis.smembers('rules').each do |rule|
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
