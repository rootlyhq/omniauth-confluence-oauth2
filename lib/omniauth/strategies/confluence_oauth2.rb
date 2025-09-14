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
        raw_info['myself'].dig('account_id') || raw_info['myself'].dig('accountId')
      end

      info do
        {
            name: raw_info['myself'].dig('name') || raw_info['myself'].dig('displayName'),
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

        # NOTE: api.atlassian.com, not auth.atlassian.com!
        accessible_resources_url = 'https://api.atlassian.com/oauth/token/accessible-resources'
        sites = JSON.parse(access_token.get(accessible_resources_url).body)

        # Confluence's OAuth gives us many potential sites. To request information
        # about the user for the OmniAuth hash, pick the first one that has the
        # necessary Confluence user scopes.
        confluence_user_scopes = if options.new_scopes
          %w'read:user:confluence read:content-details:confluence'
        else
          %w'read:confluence-user'
        end

        sites = sites.filter do |candidate_site|
          candidate_site['scopes'].intersect?(confluence_user_scopes)
        end

        if sites.empty?
          raise "No sites found with scope #{confluence_user_scopes}, please ensure the scope #{confluence_user_scopes} is added to your OmniAuth config"
        end

        site = nil
        myself = nil

        sites.each do |candidate_site|
          begin
            if options.new_scopes
              myself = access_token.get("ex/confluence/#{candidate_site["id"]}/wiki/rest/api/user/current", :headers => { 'Content-Type' => 'application/json' }).parsed
            else
              myself = access_token.get('me', :headers => { 'Content-Type' => 'application/json' }).parsed
            end
            site = candidate_site
            break
          rescue ::OAuth2::Error
            next
          end
        end

        raise StandardError, 'Cannot find valid site' unless site
        raise StandardError, 'Cannot fetch current user' unless myself

        @raw_info ||= {
          'site' => site,
          'sites' => sites,
          'myself' => myself
        }
      end
    end
  end
end
