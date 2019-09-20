# OmniAuth Confluence OAuth2 Strategy

Strategy to authenticate with Confluence via OAuth2 in OmniAuth.

Get your API key at: https://developer.atlassian.com/apps/ Note the Client ID
and the Client Secret.

For more details, read the Atlassian Confluence docs about OAuth 2.0 (3LO):
https://developer.atlassian.com/cloud/confluence/oauth-2-authorization-code-grants-3lo-for-apps/

## Installation

Add to your `Gemfile`:

```ruby
gem 'omniauth-confluence-oauth2'
```

Then `bundle install`.

## Confluence API Setup

* Go to 'https://developer.atlassian.com/apps/'
* Create a new app.
* Note the Client ID and Secret values in the App Details section.
* Under APIs and Features, add the "Authorization code grants" feature.
  Configure the feature with your callback URL (something like
  http://localhost:3000/auth/confluence_oauth2/callback).
* Under APIs and Features, add the "Confluence platform REST API" API.

## Usage

Here's an example for adding the middleware to a Rails app in
`config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :confluence_oauth2, ENV['CONFLUENCE_CLIENT_ID'], ENV['CONFLUENCE_CLIENT_SECRET'],
    scope: "offline_access read:me read:confluence-space.summary read:confluence-props read:confluence-content.all read:confluence-content.summary search:confluence",
    prompt: "consent"
end
```
The `offline_access` scope must be included if you wish to attain a refresh token.
You may wish to include additional scopes depending on how you've configured
your app in the Atlassian UI.

You can now access the OmniAuth Confluence OAuth2 URL: `/auth/confluence_oauth2`

NOTE: While developing your application, if you change the scope in the
initializer you will need to restart your app server.

## Auth Hash

Here's an example of an authentication hash available in the callback by
accessing `request.env['omniauth.auth']`:

After authing a user, when you make API calls over time, you should follow the
[Confluence OAuth 2.0 docs](https://developer.atlassian.com/cloud/confluence/oauth-2-authorization-code-grants-3lo-for-apps/)
and continue to check the `accessible-resources` endpoint to ensure your app
continues to have access to the sites you expect.

```ruby
{
  "provider" => "confluence_oauth2",
  "uid" => "100000000000000000000",
  "info" => {
    "name" => "John Smith",
    "email" => "john@example.com",
    "nickname" => "john_smith", # username
    "location" => "Australia/Sydney", # time zone
    "image" => "https://whatever.atlassiancdn.com/photo.jpg",
  },
  "credentials" => {
    "token" => "TOKEN",
    "refresh_token" => "REFRESH_TOKEN",
    "expires_at" => 1496120719,
    "expires" => true
  },
  "extra" => {
    "raw_info" => {
      "sites" => {},
      "myself" => {},
    }
  }
}
```

## License

Copyright (c) 2019 by Ben Standefer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
