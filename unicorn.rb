@dir = "."
worker_processes 2
working_directory @dir
preload_app true
timeout 30
listen 9080
#listen "#{@dir}/tmp/unicorn.sock", :backlog => 1024 
pid "#{@dir}/tmp/pids/unicorn.pid"
stderr_path "#{@dir}/log/unicorn.stderr.log"
stdout_path "#{@dir}/log/unicorn.stdout.log"
