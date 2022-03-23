# frozen_string_literal: true

require 'omniauth/strategies/oauth2'
require 'uri'

# Potential scopes: https://developer.atlassian.com/cloud/jira/platform/scopes/
# offline_access read:user:confluence read:content-details:confluence read:content.metadata:confluence write:content:confluence
#
# Separate scopes with a space (%20)
# https://developer.atlassian.com/cloud/confluence/oauth-2-authorization-code-grants-3lo-for-apps/

module OmniAuth
  module Strategies
    # Omniauth strategy for Confluence
    class ConfluenceOauth2 < OmniAuth::Strategies::OAuth2
      option :name, 'confluence_oauth2'
      option :client_options,
             site: 'https://api.atlassian.com',
             authorize_url: 'https://auth.atlassian.com/authorize',
             token_url: 'https://auth.atlassian.com/oauth/token',
             audience: 'api.atlassian.com'
      option :authorize_params,
             prompt: 'consent',
             audience: 'api.atlassian.com'
      
      option :new_scopes, false

      uid do
        raw_info['myself']['account_id']
      end

      info do
        {
            name: raw_info['myself']['name'],
            email: raw_info['myself']['email'],
            nickname: raw_info['myself']['nickname'],
            location: raw_info['myself']['zoneinfo'],
            image: raw_info['myself']['picture']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        return @raw_info if @raw_info

        if options.new_scopes
          access_token.options[:mode] = :header
          myself ||= access_token.get('wiki/rest/api/user/current', :headers => { 'Content-Type' => 'application/json' }).parsed
        else
          # NOTE: api.atlassian.com, not auth.atlassian.com!
          accessible_resources_url = 'https://api.atlassian.com/oauth/token/accessible-resources'
          sites = JSON.parse(access_token.get(accessible_resources_url).body)

          myself_url = "https://api.atlassian.com/me"
          myself = JSON.parse(access_token.get(myself_url).body)
        end

        @raw_info ||= {
          'sites' => sites,
          'myself' => myself
        }
      end
    end
  end
end
