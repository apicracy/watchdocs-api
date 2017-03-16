# CS Example App

This is an example app with CS-gem integration.
You can build your own landing page on top of it.

## Configure

Set configuration using `.env` up to a gem instruction.

## Run

Install CS-gem

```ruby
gem install content_editor-0.0.2.gem
```

Install all gems

```ruby
bundle
```

Run the server

```ruby
foreman start
```

## Develop

Now you are ready to go and implement your CS landing page.
Modify `views`, `default.json` and place you assets in `assets` path (it uses sprockets).

## Heroku Deployment

It is ready to be deployed to Heroku. Remeber to set env variables.
