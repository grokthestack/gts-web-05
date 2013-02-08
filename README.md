When we went over HTTP, I briefly mentioned that, along with the URL, metadata gets passed along with the request by the browser which you can't normally see. That's why when we make a POST request to a site, we don't see the parameters to our reqeust in the URL. They were passed on for us by the browser behind the scene when we submitted the form.

These extra values are called headers, and they have a lot to do with making things work behind the scenes so that we don't have to think about them at all.

If we were to look at all the headers inside of an HTTP request, it would look something like this:

	POST /path/to/resource?foo=bar&bizz=buzz HTTP/1.1
	Host: example.com
	User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:17.0) Gecko/20100101 Firefox/17.0
	Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
	Accept-Language: en-US,en;q=0.5
	Accept-Encoding: gzip, deflate
	Connection: keep-alive
	Referer: http://www.google.com/
	Cookie: $Version=1; logged_in=false;

Likewise, HTTP responses (the data sent back from the server) also contain a lot of metadata, such as:

	Age	7652
	Cache-Control	private, s-maxage=0, max-age=0, must-revalidate
	Connection	keep-alive
	Content-Encoding	gzip
	Content-Language	en
	Content-Length	21150
	Content-Type	text/html; charset=UTF-8
	Date	Fri, 08 Feb 2013 00:20:46 GMT
	Expires	Thu, 01 Jan 1970 00:00:00 GMT
	Last-Modified	Wed, 06 Feb 2013 19:17:03 GMT
	Server	Apache
	Vary	Accept-Encoding,Cookie
	X-Cache	HIT from cp1008.eqiad.wmnet, MISS from cp1020.eqiad.wmnet
	X-Cache-Lookup	HIT from cp1008.eqiad.wmnet:3128, MISS from cp1020.eqiad.wmnet:80
	X-Content-Type-Options	nosniff
	Set-Cookie: $Version=1; logged_in=false;

It's a lot of data, and it varies widely between domains.  Unless you're coding up a web browser or an HTTP client, they're not really that useful, so we're not going to worry about them except to be aware that they exist.

The one key header we need to know about is the Cookie field.

	Cookie: $Version=1; logged_in=1;

Most people know about cookies because they're in the news a lot.

They're a mechanism for the server to ask the client to remember specific information, so that when the next HTTP request happens from that user, the server can retrieve the information and use it to customize the site.  This allows the server to keep track of an individual user.

I mentioned previously that the web is stateless, which means that each request you make to a server is handled independently from all other requests.  Cookies are the main way that the browser and the website work together to tailor the content of the page to you specifically and remember the choices you make as you're browsing.

For example, let's say we have a form on our site for the user to set his or her favorite color.  The server could attach a header to the next response which looks like this:

	Set-Cookie: favorite_color=blue

Now, the browser will store this string locally and send its own header to the same domain every time it makes another request.

	Cookie: favorite_color=blue

This means that the server can essentially store data about each user without having to keep that data in a central location.

This works great if we want to change the background color of the page to the user's favorite_color.  However, things break down if we want to do anything more important.  Let's say we want to keep track of users, for example.  A user logs into our site, and we want to store their ID, so that we know who they are.

	Set-Cookie: user_id=5

Whenever a request is made, we can load the cookie data, see that the user's ID is 5, look up the user's data from the database, and now we have access to application-specific information about the current user.

A normal way to utilize information like this would be to check to see if the owner of a particular database item is the same as the current user before allowing access to it.

However, the important thing to remember about data sent from the client is that everything can be manipulated, and everything can be read by the end user, using the right software.

I could easily tell my browser to set any headers I want, especially cookies.  So the fact that I have a cookie is no guarantee that it came from the web application.  So if we actually used code like this in production, I would be able to set my user_id to anything I like and access absolutely any user's data.

The solution to this problem that most web applications use is a concept called Sessions.  When a user comes to the site for the first time, and there are no cookies sent from the server, the application generates a unique string representing a session ID and sends it to the user as a cookie.

	Set-Cookie: session_id=f214dfee401defcc

The session_id is stored somewhere on the server along with data related to the user.  For example:

	{ f214dfee401defcc: { user_id: 5 } }

Now, since the only thing I can change is my session ID, I might be able to sniff other users' session IDs and impersonate them that way, but I can't directly modify the session data the server is storing on my behalf.

Sinatra makes it super easy to use session variables.

First you enable them:

	enable :sessions 

And then you can use them in any handler method:

	enable :sessions

	post '/'
		if params['color']
			session['color'] = params['color']
		end
	end

	get '/'
		"Your favorite color is #{session['color']}"
	end

We're going to use sessions for our challenge this week by allowing a user to create an account and password, then login using that account and password.  We'll store the user_id in a session and pull the user data from the database every time the user creates a new message, so that we can attach the new message to the currently logged-in user.

To accomplish this, I've created two new routes:

	# Create a new user (name, password)
	post '/users/' do
	end

	# Login the user (name, password)
	post '/login' do
	end

And added the appropriate test scripts to tests.rb.  You'll have to modify the users table for passwords and check against the password in the database when the user attempts to log in.
