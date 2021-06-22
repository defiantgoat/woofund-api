# WooWooFund API Application
## Environment
The application was developed on a Mac running BigSur with the following environment:
* Ruby v 2.7.3 (via rbenv)
* Bundler v 2.1.4

## Technologies Used
* Ruby
* Sinatra

## To Run
* Pull Repo to local environment
* Run the following at the project's root
  * Run `bundle install` to install required Gems
  * Run `ruby start_rackup` to start the application in local development mode
  * The application will run at http://localhost:9292/api/

## Known Issues and Limitations
* API uses JWT for authentication.
  * As a proof of concept, a self signed certificate was used to create a long lived token (6 months) that is [embeded](https://github.com/defiantgoat/woowoofund-app/blob/main/src/client/reducers/index.ts#L14) in the [client](https://github.com/defiantgoat/woowoofund-app).
  * The API [embeds the public keys from the certificate](https://github.com/defiantgoat/woowoofund-api/blob/main/lib/jwt_token_validation_helper.rb#L74) in order to validate the long lived token.
* As a POC, no database was created, instead a flat JSON file is used to store and retreive data for the [client](https://github.com/defiantgoat/woowoofund-app).

