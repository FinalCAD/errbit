Problem.where({message: /Api::ApiController::APIUpgradeRequired/}).each &:resolve!
Problem.unresolved.where({message: /Api::ApiController::APIUpgradeRequired/}).map(&:notices_count).sum
Problem.where({:created_at.lt => 15.day.ago }).map &:resolve!

user = User.where({email: 'joel@finalcad.fr'}).first
user = User.where({github_login: 'joel'}).first
user.password = 'secret'
user.password_confirmation = 'secret'
user.save


title = 'ThreadTimeout::TimedOut'
selected_problems = Problem.where(message: Regexp.new(title)).order_by(:created_at.desc).to_a
merged_problem    = selected_problems.first # Most recent
ProblemMerge.new(selected_problems).merge
merged_problem.unresolve!
selected_problems.size