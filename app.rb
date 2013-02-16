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

get '/' do
	@messages = db.execute("SELECT * FROM guestbook JOIN users ON users.id = guestbook.user_id");
	erb File.read('our_form.erb')
end

post '/' do
	@name = params['name']
	result = db.execute("SELECT * FROM users WHERE name = ?", @name) || []
	if result.length>0
		db.execute(
			"INSERT INTO guestbook VALUES( ?, ? )",
			result.shift['id'], params['message']
		);
		erb File.read('thanks.erb')
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

	db.execute("
		UPDATE users SET name = ? WHERE name = ?;
	", params['name'], params['old_name'])

end

# Create a new user (name, password)
post '/users/' do
end

# Login the user (name, password)
post '/login' do
end
