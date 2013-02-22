require 'sinatra'
require "sqlite3"

database_file = settings.environment.to_s+".sqlite3"

db = SQLite3::Database.new database_file
db.results_as_hash = true
db.execute "
	CREATE TABLE IF NOT EXISTS guestbook (
		user_id INTEGER,
		message VARCHAR(255)
	);
";

db.execute "
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(255) UNIQUE,
                password VARCHAR(255)
	);
";

enable :sessions

get '/' do
	@messages = db.execute("SELECT * FROM guestbook JOIN users ON users.id = guestbook.user_id");
	erb File.read('our_form.erb')
end

post '/' do
        id = session['user_id']
        if id
          db.execute("INSERT INTO guestbook VALUES( ?, ? )",
                     id, params['message']);
          result = db.execute("SELECT * FROM users WHERE id = ?", id)
	  @name = result.shift['name']
          erb File.read('thanks.erb')
        else
          erb File.read('not_logged_in.erb')
        end
end

get '/users/:name' do

	@name = params['name']
	@messages = db.execute("
		SELECT * FROM users 
		JOIN guestbook 
		ON users.id = guestbook.user_id 
		WHERE name = ?
	", params['name'])

	erb File.read('user.erb')

end

get '/users/:name/edit' do

	@name = params['name']
	result = db.execute("SELECT * FROM users WHERE name = ?", params['name'])
	@user = result.shift || false
	erb File.read('user_edit.erb')

end

post '/users/:old_name' do

        id = session['user_id']
        if id
          result = db.execute("SELECT * FROM users WHERE id = ?", id)
	  session_name = result.shift['name']
          if session_name == params['old_name']
            db.execute("UPDATE users SET name = ? WHERE name = ?", 
                       params['name'], params['old_name'])
          else
            @old_name = params['old_name']
            erb File.read('wrong_user.erb')
          end
        else
          erb File.read('not_logged_in.erb')
        end

end

# Create a new user (name, password)
post '/users/' do
  db.execute("INSERT into users(name, password) VALUES (?, ?)",
             params['name'], params['password'])
end

# Login the user (name, password)
post '/login' do
  @name = params['name']
  result = db.execute("SELECT * FROM users WHERE name = ? and password = ?", 
                      @name, params['password']) || []
  if result.length>0
    session['user_id'] = result.shift['id']
    erb File.read('welcome.erb')
  else
    erb File.read('incorrect_password.erb')
  end
end
