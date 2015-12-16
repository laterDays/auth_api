# Authentication Overview

```
iOS App                       Rails                               Amazon (AWS)
                              Doorkeeper (OAUTH): Add app   
                              [/oauth/authorized_applications]      
                              |
                              |
hardcode info to <----------- Show client_id, client_secret
app?                          Give redirect uri
|  
|                                            
v
let my user use you ----->    Devise: Lets check user
                              [/]        
                                  |
                                  v
                              OK?
                                  |
                                  v
                              Doorkeeper (OAUTH): OK
                                  |
                                  v
                              let me get AWS Cognito info ------> OK?
                                                                  |
                                                                  v
                              recieve a cognito token <---------- here's a token
                                  |
                                  v
recieve tokens <------------- OK, I'll send     
|                             OAUTH and cognito token
|                             
v
get AWS Credentials --------------------------------------------> OK?
                                                                  |
                                                                  v
recieve credentials <-------------------------------------------- here's your 
|                                                                 credentials
|
v
use OAUTH token to talk to app -> server API access
use credentials to talk to AWS -------------------------------->  S3 access

```


# Amazon Prep:

## A. Prepare amazon user profile:

1. Go to AWS (https://console.aws.amazon.com/iam/home) and sign in.
2. On left panel, "Details", click "Users"
3. Click "Create new users", note the Access Key Id and Secret. Download Credentials.
4. Click on your newly created user.
5. Click on the "Permissions" tab and click "Attach Policy". Add the "AmazonCognitoDeveloperAuthenticatedIdentities" policy.

## B. Prepare Amazon S3 Bucket

1. Got to AWS (https://console.aws.amazon.com/s3/home)
2. Click "Create Bucket"
3. Note your your S3 bucket name

## C. Prepare Amazon Cognito Identity Pool

1. Got to AWS (https://console.aws.amazon.com/cognito/home) and sign in.
2. Click "Create new identity pool"
3. Choose an identity pool name
4. Expand "Authentication Providers". Click the Custom tab and write "video-test-api.herokuapp.com"
5. In the next page, click "Allow", to allow the creation of the IAM roles.
6. Go to https://console.aws.amazon.com/iam/home.
7. On left panel, "Details", click "Roles"
8. Click on the "...AuthRole" that was created with your identity pool.
9. In the "Permissions" tab, in "Inline Policies", click "Create Role Policy"
10. Select "Policy Generator"
11. 
```
  Effect: Allow
  Amazon Service: Amazon S3
  Actions: DeleteObject, GetObject, PutObject
  Resource: arn:aws:s3:::YOUR-S3-BUCKET-NAME/*
```
12. Click "Add Statement" then "Next step" then "Apply Policy"



# Rails Prep:

## Amazon Config

Change the code in /config/environments/development.rb,
```
  creds = JSON.load(File.read('../access/auth-dev/creds.json'))
  Aws.config.update({
    region: 'us-east-1',
    credentials: Aws::Credentials.new(creds['AWS_ACCESS_KEY_ID'], creds['AWS_SECRET_ACCESS_KEY'])
  })
```
Make sure the first line points to some local file on your computer that contains a json with your amazon IAM User credentials (create a file like this):
```
  creds.json
  . . . . . . . . . . . . . . . . 
  {                                               # from the above steps:
    "AWS_ACCESS_KEY_ID":"your_access_key_id",     # step A3
    "AWS_SECRET_ACCESS_KEY":"your_secret_key"     # step A3
    "S3_REGION":"us-east-1",                      # part B         
    "IDENTITY_POOL_ID":"your_identity_pool_id",   # part C
    "IDENTITY_POOL_PROVIDER":"video-test-api.herokuapp.com"
  }
  . . . . . . . . . . . . . . . .
```
Also, change the region in Aws.config.update `({region:"your_amazon_s3_region" ... })`

```
User 
  -> "AmazonCognitoDeveloperAuthenticatedIdentities" permissions 
    -> Cognito Identity Pool Access
      -> Amazon S3 Access
     
```

## Email Config

Change the code in /config/environments/development.rb again for email credentials. Rails will use this information to email confirmation emails. The first line below shows where you can create your access json file, or you can change that line to a more fitting location. You will form the file in a similar fashion to creds.json in the above section.

```
  email_creds = JSON.load(File.read('../access/auth-dev/email.json'))
  config.action_mailer.default_url_options = { :host => 'localhost' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "smtp.gmail.com",
    :port                 => 587,
    :domain               => email_creds["domain"],
    :user_name            => email_creds["user_name"],
    :password             => email_creds["password"],
    :authentication       => 'plain',
    :enable_starttls_auto => true  }

  . . . . . . . . . . . . . . . . 
```

## Config Variables

Set the following environmental variables `ENV["name"]`
```
AWS_ACCESS_KEY_ID       # Amazon Web Services - Step A3
AWS_SECRET_ACCESS_KEY   # Amazon Web Services - Step A3
IDENTITY_POOL_ID        # Amazon Cognito - Part C
IDENTITY_POOL_PROVIDER  # Amazon Cognito - Part C
S3_BUCKET_NAME          # Amazon S3 - Part B
S3_REGION               # Amazon S3 - Part B

EMAIL_DOMAIN
EMAIL_PW                # not the safest way of doing things!
EMAIL_USER
```

# The API

### /api/v1/...

#### ... aws_cognito_auth

If your user was authenticated via Devise (user login - through app or web), the user can make this API call to recieve an amazon Cognito Identity ID. The server will respond to an authenticated call with a json of the following format:
```
  {
    "identity_id":"your_identity_pool_id",
    "token":"cognito_token"
  }
```
