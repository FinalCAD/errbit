desc 'Resolves problems that didnt occur for 2 weeks'
task cleanup: :environment do
  offset = 3.weeks.ago
  Problem.where(:updated_at.lt => offset).map(&:resolve!)
  Notice.where(:updated_at.lt => offset).destroy_all
end
