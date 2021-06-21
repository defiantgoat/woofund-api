require 'net/http'
require 'json'
require 'jwt'

module WooWooFund
  
  module JwtTokenValidationHelper

    ALG = 'RS256'.freeze

    module TOKEN_STATUS_TEXT
      VALID = 'VALID'.freeze
      INVALID = 'INVALID'.freeze
      EXPIRED = 'EXPIRED'.freeze
      UNABLE_TO_DECODE = 'UNABLE TO DECODE TOKEN'.freeze
      UNABLE_TO_VALIDATE = 'UNABLE TO VALIDATE TOKEN'.freeze
      IMMATURE_SIGNATURE = 'IMMATURE SIGNATURE'.freeze
      VERIFICATION_ERROR = 'VERIFICATION ERROR'.freeze
      UNABLE_TO_CONTACT_SERVER = 'UNABLE TO CONTACT IDENTITY SERVER'.freeze
    end

    module TOKEN_STATUS_CODE
      INVALID = 0
      VALID = 1
    end

    # ------------------------------------------------------------------------------------------------------------------

    def self.validate(encoded_jwt, jwks_uri, issuer, kid = nil)

      # Assume token is invalid and unable to be verifed initially
      status_response = {
        :status_code => TOKEN_STATUS_CODE::INVALID,
        :status_text => TOKEN_STATUS_TEXT::UNABLE_TO_VALIDATE
      }

      # This is just a defensive check. This should never occur honestly.
      if encoded_jwt.nil? || jwks_uri.nil? || issuer.nil?
        return status_response
      end

      # If no kid was passed, then decode an unvalidated token and find kid in header
      if kid.nil?
        begin
          unverified_token = JWT.decode encoded_jwt, nil, false
          header = unverified_token[1] || nil
          kid = header['kid'] || nil
          puts kid
          
          # If there is no kid at this point, the token cannot be validated as there is no way to match up.
          if kid.nil?
            return status_response
          end
          
          rescue JWT::DecodeError
            status_response[:status_text] = TOKEN_STATUS_TEXT::UNABLE_TO_DECODE
            return status_response
        end
      end

      # GET the public keyset from the well known url endpoint.
      begin
        # jwt_public_keys = Net::HTTP.get(URI(jwks_uri))

        # For POC we use a self signed cert with a long lived token we will just embed in the client.
        jwt_public_keys = {
          "keys"=>[
            {
              "kty"=>"RSA",
              "kid"=>"mock-kid",
              "n"=>"n",
              "e"=>"e",
              "use"=>"sig",
              "x5c"=>["MIICuzCCAaOgAwIBAgIBADANBgkqhkiG9w0BAQUFADAhMR8wHQYDVQQDDBZhZG1pbi5uZWFybWFwLmNvbS9DPUFVMB4XDTIxMDYxOTIyNTM0OVoXDTIyMDYxOTIyNTM0OVowITEfMB0GA1UEAwwWYWRtaW4ubmVhcm1hcC5jb20vQz1BVTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANgbllAg3kx5+/lJq5j6jbDeCxrUVh4on7shx61/dltlHW5F9DEsmOLx3EpDLs4VkJGPPeDivSFHW+Ukop7awKyx62MTqc7wUznISXoE+QmGvWoqzUzYWfmWEH+iuSzj5YiB7mVSBDJhA4kzQqv6/Hz1Ht2KRhZ3CoqN6wKzfRAwxlPB/VxNb+bdytGMFa1uesNBpB4NCydOnGHLzizLga5v0JGQL44YyS/f2ntpzuKky0Dm0F8maY1inOLc+1pdMX3y/UQVop6JpBJYslvKrwIlBzsTiMqDpLf6c2vl2jU9rsqyca+F/wtuOV156GPHqspCMLUk3hnmrUKhd69LCLsCAwEAATANBgkqhkiG9w0BAQUFAAOCAQEAzGe4l8J8HSNmtS7Cx0OV+Wukn5uIdAXjdtA9NP2G6AQYGbhyaGd1HkdY7cShId+NIpLHAu7vlsedlItzKduwEJXXuQAEaQhAGsN8pO3O2G2B4Hbv6E3gh1IojBDvOPML0bCZ3C8gcuk/8kzuTUIZ0ZVL8a6d7Xk2hC2oXLQcaYIeSKQHbyD0veouaimmGwm0dq6TvGG9D7mAtoKdI5qEu1tixrmwrwxNv745g+LDtP7ZpSBi9fJ6cl/coJyyd7OHarfz0U4s6diOrE+t/AyO6aEmNFktj2d3DD9CLw619Clz5pd6N4ftO8anOZGAgw7j2J3HSQyqmwJNwd2I2IAzBg=="]
            }
          ]}

        # If the HTTP request throws any error, assume that the token cannot be validated
        rescue StandardError
          status_response[:status_text] = TOKEN_STATUS_TEXT::UNABLE_TO_CONTACT_SERVER
          return status_response
      end

      # If by some chance a empty array is returned, then the token cannot be validated.
      if jwt_public_keys.empty?
        return status_response
      end
      
      keys = jwt_public_keys

      filtered_keys = filter_signing_keys keys['keys']

      # If no keys match the filter criteria, then the token cannot be validated.
      if filtered_keys.empty?
        return status_response
      end

      # find the associated keyset with the same kid key value pair
      key_to_use = find_signing_key(filtered_keys, kid)

      puts key_to_use

      if key_to_use.nil?
        return status_response
      end
      
      # create a certificate instance from the x5c base64 encoded binary cert used to sign the token
      cert = OpenSSL::X509::Certificate.new(Base64.decode64(key_to_use['raw_key']))

      begin
        # decode and validate the token now with the key and issuer, if no error is thrown, then it is valid
        validated_token = JWT.decode encoded_jwt, cert.public_key, true, {iss: issuer, verify_iss: true, algorithm: ALG}
      
        rescue JWT::ExpiredSignature
          status_response[:status_text] = TOKEN_STATUS_TEXT::EXPIRED

        rescue JWT::VerificationError
          status_response[:status_text] = TOKEN_STATUS_TEXT::VERIFICATION_ERROR

        rescue JWT::ImmatureSignature
          status_response[:status_text] = TOKEN_STATUS_TEXT::IMMATURE_SIGNATURE

        rescue JWT::DecodeError
          status_response[:status_text] = TOKEN_STATUS_TEXT::UNABLE_TO_DECODE

        rescue StandardError
          status_response[:status_text] = TOKEN_STATUS_TEXT::UNABLE_TO_VALIDATE

        else
          status_response[:status_code] = TOKEN_STATUS_CODE::VALID
          status_response[:status_text] = TOKEN_STATUS_TEXT::VALID   
          status_response[:payload] = validated_token[0]             
      end  

      # finally return the status after proper validation has been performed and succeded or errored out.
      status_response
    end

    # ------------------------------------------------------------------------------------------------------------------

    # Even though only 1 keyset is typically included, best practice per JWT is to always filter the array
    # in case other keysets are added in the future.
    def self.filter_signing_keys(keys)
      keys.select{ |key| key['use'] === 'sig' && key['kty'] === 'RSA' && key['kid'] && ((key['x5c'] && key['x5c'].length > 0) || (key['n'] && key['e']))}
        .map{|key| {'kid' => key['kid'], 'nbf' => key['nbf'], 'raw_key' => key['x5c'].first }}
    end

    # ------------------------------------------------------------------------------------------------------------------

    def self.find_signing_key(keys, kid)
      keys.select{|keys| keys['kid'] === kid}.first
    end

    # ------------------------------------------------------------------------------------------------------------------
  end
end