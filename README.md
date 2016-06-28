# Dropbox SDK for Ruby

[![Gem Version](https://img.shields.io/gem/v/dropbox-sdk-v2.svg)](https://rubygems.org/gems/dropbox-sdk-v2)
[![Build Status](https://travis-ci.org/waits/dropbox-sdk-ruby.svg?branch=master)](https://travis-ci.org/waits/dropbox-sdk-ruby)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/waits/dropbox-sdk-ruby/blob/master/LICENSE)

This is a small Ruby library for accessing the new [Dropbox API](https://www.dropbox.com/developers/documentation/http/overview). It provides a single class, `Dropbox::Client`, with methods that map to most of the Dropbox API endpoints. Currently all of the endpoints in the `auth`, `files`, and `users` namespaces are supported. Sharing methods are planned.

## Requirements
- Ruby 2.1.0 or later
- The [http](https://github.com/httprb/http) gem

## Installation

Run:
```bash
gem install dropbox-sdk-v2
```

Then, in your source files:
```ruby
require 'dropbox'
```

Or just add this to your Gemfile:
```ruby
gem 'dropbox-sdk-v2'
```

## Usage

Also see the [full YARD documentation](http://www.rubydoc.info/github/waits/dropbox-sdk-ruby).

Set up a client:
```ruby
require 'dropbox'

dbx = Dropbox::Client.new(ENV['DROPBOX_ACCESS_TOKEN'])
```

Create a folder:
```ruby
folder = dbx.create_folder('/myfolder') # => Dropbox::FolderMetadata
folder.id # => "id:a4ayc_80_OEAAAAAAAAAXz"
folder.name # => "myfolder"
folder.path_lower # => "/myfolder"
```

Upload a file:
```ruby
# File body can be a String, File, or any Enumerable.
file = dbx.upload('/myfolder/file.txt', 'file body') # => Dropbox::FileMetadata
file.size # => 9
file.rev # => a1c10ce0dd78
```

Download a file:
```ruby
file, body = dbx.download('/myfolder/file.txt') # => Dropbox::FileMetadata, HTTP::Response::Body
body.to_s # => "file body"
```

Delete a file:
```ruby
dbx.delete('/myfolder/file.txt') # => Dropbox::FileMetadata
```

## Contributing

All contributions are welcome. Please [file an issue](https://github.com/waits/dropbox-sdk-ruby/issues) or [submit a pull request](https://github.com/waits/dropbox-sdk-ruby/pulls).

This project strives for full test coverage. To run the test suite, make a [Dropbox App](https://www.dropbox.com/developers/apps) with "app folder" access and generate an access token. Then run `DROPBOX_SDK_ACCESS_TOKEN="..." rake test`.
