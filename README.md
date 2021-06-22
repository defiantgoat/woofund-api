# WooWooFund API Application
## Environment
The application was developed on a Mac running BigSur with the following environment:
* Ruby v 2.7.3 (via rbenv)
* Bundler v 2.1.4

## Technologies Used
* Ruby
* Sinatra

## Important Setup for Ubuntu 20.04
The api was run on an Ubuntu 20.04 virtual machine via VM Fusion.
* Your Ubuntu Machine needs ruby and nodejs installed.
* The API uses ImageMagick to convert PDF files to images. A functionality that has been disabled in Ubuntu and requires editing the ImageMagick policy.xml file.
Run the following (if you need to on your machine of VM) A VM is recommended.
* `sudo apt update`
* `sudo apt install imagemagick`
* `sudo apt install ghostscript`
### Update the ImageMagick policy.xml
* Use whatever text editing method you like to edit the following file
* `/etc/ImageMagick-6/policy.xml`
* Comment out or delete the following line: `<policy domain="coder" rights="none" pattern="PDF" />`

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
* The Dockerfile needs to be updated to account for the ImageMagick policy issues and to install ImageMagick and Ghostscript in the image.

