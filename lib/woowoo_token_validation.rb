require 'net/http'
require 'json'
require 'jwt'
require_relative 'jwt_token_validation_helper'

module WooWooFund
  module TokenValidation

    JWKS_ENDPOINT = 'https://someidentityserver/jwks'.freeze
    ISS = 'https://woowoofund.com'.freeze
    CLIENT_ID = 'woowoofund'.freeze

    # ------------------------------------------------------------------------------------------------------------------

    def self.validate(token)
      # Decode the token without validation to perform pre-checks
      begin
        unverified_token = JWT.decode(token, nil, false)
        payload = unverified_token[0] || nil
        header = unverified_token[1] || nil

      rescue JWT::DecodeError
        # access denied to resources
        return {
          :status_code=> JwtTokenValidationHelper::TOKEN_STATUS_CODE::INVALID,
          :status_text => JwtTokenValidationHelper::TOKEN_STATUS_TEXT::UNABLE_TO_VALIDATE
        }
      end

      # no need to proceed because unverfied token did not pass pre-checks --> access denied
      if !proceed_with_validation(payload, header)
        return {
          :status_code=> JwtTokenValidationHelper::TOKEN_STATUS_CODE::INVALID,
          :status_text => JwtTokenValidationHelper::TOKEN_STATUS_TEXT::UNABLE_TO_VALIDATE
        }
      end

      JwtTokenValidationHelper.validate(token, JWKS_ENDPOINT, ISS, header['kid'])
    end

    # ------------------------------------------------------------------------------------------------------------------

    def self.proceed_with_validation(payload, header)
      proceed = true

      if !payload || !header
        proceed = false
      end

      if header && header['alg'] != JwtTokenValidationHelper::ALG
        proceed = false
      end

      if payload && payload['iss'] != ISS
        proceed = false
      end

      if payload && payload['client_id'] != CLIENT_ID
        proceed = false
      end

      proceed
    end

    # ------------------------------------------------------------------------------------------------------------------

  end
end
