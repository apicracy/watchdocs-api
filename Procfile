web: bundle exec rackup config.ru -p $PORT -o 0.0.0.0
worker: bundle exec sidekiq -r ./app/report_extractor_worker.rb -c 3
