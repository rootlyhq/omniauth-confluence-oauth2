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
        raw_info['myself']['accountId']
      end

      info do
        {
            name: raw_info['myself']['displayName'],
            email: raw_info['myself']['email']
        }.compact
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        return @raw_info if @raw_info

        sites = access_token.get('oauth/token/accessible-resources', :headers => { 'Content-Type' => 'application/json' }).parsed

        if options.new_scopes
          cloud_id = sites.first['id']
          myself ||= access_token.get("ex/confluence/#{cloud_id}/wiki/rest/api/user/current", :headers => { 'Content-Type' => 'application/json' }).parsed
        else
          myself ||= access_token.get('me', :headers => { 'Content-Type' => 'application/json' }).parsed
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
