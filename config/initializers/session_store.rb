# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_twitter_session',
  :secret      => 'ff77855f4a2e13a3e741fb7cc0b7710de78d4f61909d3c804fdf907d250a603574c2227b54e0e5b627a36bdc84441a403e4de84d6534758fdadc07c1750166a8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
