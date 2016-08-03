rails_env = ENV['RAILS_ENV'] || 'development'

config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
Resque.redis = Redis.new( config.merge(thread_safe: true ) )

Resque.inline = false #rails_env == 'development'
Resque.redis.namespace = "libra2:#{rails_env}"
Resque.logger.level = Logger::INFO