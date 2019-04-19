namespace :clear do
  desc 'drops, creates, and migrates database'
  task :env_db => :environment do
    Rake::Task['db:drop'].execute
    Rake::Task['db:create'].execute
    Rake::Task['db:migrate'].execute
  end

  desc 'drops, creates, and schema:loads production database (run only in production)'
  task :env_prod_db => :environment do
    Rake::Task['db:drop'].execute
    Rake::Task['db:create'].execute
    Rake::Task['db:schema:load'].execute
  end
end

