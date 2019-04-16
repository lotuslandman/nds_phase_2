desc 'drops, creates, and migrates database'
namespace :clear do
  task :env_db => :environment do
  Rake::Task['db:drop'].execute
  Rake::Task['db:create'].execute
  Rake::Task['db:migrate'].execute
  end
end

#task :clear_db do
#  Rake::Task['db:drop'].execute
#  Rake::Task['db:create'].execute
#  Rake::Task['db:migrate'].execute
#end

