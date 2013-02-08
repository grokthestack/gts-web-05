# Load the testing libraries
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

require './app.rb'

class ApplicationTest < Test::Unit::TestCase

	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def setup
		return unless File.exists?('test.sqlite3')
		db = SQLite3::Database.new('test.sqlite3')
		db.execute "DELETE FROM guestbook WHERE 1;"
		db.execute "DELETE FROM users WHERE 1;"
	end

	def login_user 

		name = "test_name_#{rand(256)}"
		pass = "passpass#{rand(256)}"

		post '/users/', { :name => name, :password => pass }
		post '/login', { :name => name, :password => pass }

		{ :name => name, :pass => pass }

	end

	def post_message(message=nil)
		data = {
			:message => message || "test_name_#{rand(256)}"
		}
		post '/', data
		data
	end

	def test_homepage
		get '/'
		assert last_response.ok?,
			"Homepage loaded without an error."
		assert last_response.body.include?('Please leave me a message below!'),
			"Expected text present."
	end

 	def test_new_message_thanks
 		user    = login_user 
 		message = post_message
		assert last_response.ok?,
			"Form posts without an error."
		assert last_response.body.include?(user[:name]),
			"Page includes the name of the poster."
	end

	def test_messages_displayed
		user = login_user 
		message = post_message
		get '/'
		assert last_response.ok?, "No errors returned."
		assert last_response.body.include?(user[:name]),
			"Posted name is displayed on the main page."
		assert last_response.body.include?(message[:message]),
			"Posted message is displayed on the main page."
	end

	def test_user_profile

		user = login_user 
		name = user[:name]

		post '/', { :message => 'First post'    }
		post '/', { :message => 'A second post' }
		post '/', { :message => 'And a third'   }

		get '/users/'+name
		assert last_response.ok?, "/users/#{name} resolves correctly"
		assert last_response.body.include?(name),
			"#{name} displayed on user page"
		assert last_response.body.include?("First post"),
			"First post of #{name} displayed on user page"
		assert last_response.body.include?("A second post"),
			"Second post of #{name} displayed on user page"
		assert last_response.body.include?("And a third"),
			"Third post of #{name} displayed on user page"

	end

	def test_user_editing_apologizes_when_no_user_found

		name = "test_name_#{rand(256)}"
		mess = "Sorry, the user \"#{name}\" doesn't exist."

		get '/users/'+name+'/edit'
		assert last_response.ok?, "/users/#{name} resolves correctly"
		assert last_response.body.include?(mess),
			"Displays '#{mess}' when the user can't be found."

	end

	def test_saving_new_name_for_user

		d = login_user 

		name1 = d[:name]
		name2 = "test_name_#{rand(256)}"
		mess  = "Sorry, the user \"#{name1}\" doesn't exist."

		post '/', { :message => 'First post'}

		post '/users/'+name1, {:name => name2}

		get '/users/'+name2

		assert last_response.ok?,
			"The user's page has moved to the newly-named link"
		assert last_response.body.include?('First post'),
			"The user's post history is available."

		get '/users/'+name1
		assert last_response.body.include?(mess),
			"The page under the old user name should display '#{mess}'."

	end

	def test_can_sign_up

		name = "test_name_#{rand(256)}"
		pass = "passpass#{rand(256)}"

		post '/users/', { :name => name, :password => pass }

		get '/users/'+name
		assert last_response.ok?,
			"User returned"
		assert last_response.body.include? name
			"Username found on user profile page."

	end

	def test_can_log_in

		name = "test_name_#{rand(256)}"
		pass = "passpass#{rand(256)}"
		mess = "Thank you for logging in, #{name}!"

		post '/users/', { :name => name, :password => pass }

		post '/login',  { :name => name, :password => pass }
		assert last_response.ok?,
			"Login path exists."
		assert last_response.body.include?(mess),
			"Login page says, '#{mess}'"

	end

	def test_reject_bad_password

		name = "test_name_#{rand(256)}"
		pass = "passpass#{rand(256)}"

		mess = "Sorry, that password isn't correct."

		post '/login',  { :name => name, :password => pass }
		assert last_response.ok?,
			"Login path exists."
		assert last_response.body.include?(mess),
			"Login page says, '#{mess}'"

	end

	def test_rejects_posts_when_logged_out

		post_message
		mess = "Sorry, you must be logged in to post a message."

		assert last_response.body.include?(mess),
			"Page says, '#{mess}'"

	end

	def test_can_only_edit_own_username

		login_user 

		name1 = "test_name_#{rand(256)}"
		name2 = "test_name_#{rand(256)}"
		mess  = "Sorry, the user \"#{name1}\" doesn't exist."

		post '/', { :message => 'First post' }

		post '/users/'+name1, {:name => name2}

		get '/users/'+name2

		assert last_response.ok?,
			"The user's page has moved to the newly-named link"
		assert last_response.body.include?('First post'),
			"The user's post history is available."

	end

end
