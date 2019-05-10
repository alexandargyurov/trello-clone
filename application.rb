require 'rack'
require 'sqlite3'
require 'pp'

class Application
  def initialize
    @template = File.read('./todo-list/views/index.erb')#
    @db = SQLite3::Database.new('./todo-list/db/database.sqlite3')
    @db.results_as_hash = true
    create = <<-SQl
      CREATE TABLE IF NOT EXISTS todos(
        id INTEGER PRIMARY KEY,
        task TEXT,
        status TEXT
      );
    SQl
    @db.execute(create)
  end

  def call(env)
    res = Rack::Response.new
    req = Rack::Request.new(env)

    if req.POST.any?
      data = req.POST

      new_task = data['taskName']
      new_task_status = data['status']

      @db.execute("INSERT INTO todos (task, status) VALUES ('#{new_task}', '#{new_task_status}');")
    end

    if req.params['edit'] && req.params['action']
      id = req.params['edit']
      action = req.params['action']

      if action == 'delete'
        @db.execute("DELETE FROM todos WHERE id='#{id}'")
      else
        @db.execute("UPDATE todos SET status='#{action}' WHERE id='#{id}'")
      end

      @display_modal = false
    elsif req.params['edit']
      @task_id = req.params['edit']
      @display_modal = true
    end

    @todo = @db.execute("SELECT * FROM todos WHERE status='Todo';")
    @doing = @db.execute("SELECT * FROM todos WHERE status='Doing';")
    @done = @db.execute("SELECT * FROM todos WHERE status='Done';")

    res.write ERB.new(@template).result(binding)
    res.finish
  end
end