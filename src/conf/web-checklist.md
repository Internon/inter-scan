###### Generic Web

- [ ] Review screenshot folder
- [ ] Review fuzzing status files
- [ ] Configure the extender on BurpSuite"s session handling rule editor and be careful with the automatic logout
- [ ] Execute BurpSuite/Zap active and passive scans (Remember to have configured the extensions and browse all the web page)
- [ ] Find IDORs with Authorize extension of BurpSuite
- [ ] Check known vulnerabilities of services found
- [ ] Execute fuzzing as an authenticated user
- [ ] Check other dangerous functionalities (File upload, send email, etc)

###### Registration

- [ ] Duplicate registration \(try with uppercase, +1@..., dots in name, etc\)
- [ ] Overwrite existing user \(existing user takeover\)
- [ ] Username uniqueness
- [ ] Weak password policy \(user=password, password=123456,111111,abcabc,qwerty12\)
- [ ] Insufficient email verification process \(also my%00email@mail.com for account tko\)
- [ ] Weak registration implementation or allows disposable email addresses
- [ ] Fuzz after user creation to check if any folder have been overwritten or created with your profile name
- [ ] Add only spaces in password
- [ ] Long password \(&gt;200\) leads to DoS
- [ ] Corrupt authentication and session defects: Sign up, don't verify, request change password, change, check if account is active.
- [ ] Try to re-register repeating same request with same password and different password too
- [ ] If JSON request, add comma {“email”:“victim@mail.com”,”hacker@mail.com”,“token”:”xxxxxxxxxx”}
- [ ] Lack of confirmation -&gt; try to register with company email.
- [ ] Check OAuth with social media registration
- [ ] Check state parameter on social media registration
- [ ] Try to capture integration url leading integration takeover
- [ ] Check redirection in register page after login
- [ ] Rate limit on account creation
- [ ] XSS on name or email

###### Authentication

- [ ] Username enumeration
- [ ] Resilience to password guessing
- [ ] Account recovery function
- [ ] "Remember me" function
- [ ] Impersonation function
- [ ] Unsafe distribution of credentials
- [ ] Fail-open conditions
- [ ] Multi-stage mechanisms
- [ ] SQL Injections
- [ ] Auto-complete testing
- [ ] Lack of password confirmation on change email, password or 2FA \(try change response\)
- [ ] Weak login function over HTTP and HTTPS if both are available
- [ ] User account lockout mechanism on brute force attack
- [ ] Check for password wordlist \([cewl](https://github.com/digininja/CeWL) and [burp-goldenNuggets](https://github.com/GainSec/GoldenNuggets-1)\)
- [ ] Test 0auth login functionality for Open Redirection
- [ ] Test response tampering in SAML authentication
- [ ] In OTP check guessable codes and race conditions
- [ ] OTP, check response manipulation for bypass
- [ ] OTP, try bruteforce
- [ ] If JWT, check common flaws
- [ ] Browser cache weakness \(eg Pragma, Expires, Max-age\)
- [ ] After register, logout, clean cache, go to home page and paste your profile url in browser, check for "login?next=accounts/profile" for open redirect or XSS with "/login?next=javascript:alert\(1\);//"
- [ ] Try login with common [credentials](https://github.com/ihebski/DefaultCreds-cheat-sheet)

###### Session

- [ ] Session handling
- [ ] Test tokens for meaning
- [ ] Test tokens for predictability
- [ ] Insecure transmission of tokens
- [ ] Disclosure of tokens in logs
- [ ] Mapping of tokens to sessions
- [ ] Session termination
- [ ] Session fixation
- [ ] Cross-site request forgery
- [ ] Cookie scope
- [ ] Decode Cookie \(Base64, hex, URL etc.\)
- [ ] Cookie expiration time
- [ ] Check HTTPOnly and Secure flags
- [ ] Use same cookie from a different effective IP address or system
- [ ] Access controls
- [ ] Effectiveness of controls using multiple accounts
- [ ] Insecure access control methods \(request parameters, Referer header, etc\)
- [ ] Check for concurrent login through different machine/IP
- [ ] Bypass AntiCSRF tokens
- [ ] Weak generated security questions
- [ ] Path traversal on cookies
- [ ] Reuse cookie after session closed
- [ ] Logout and click browser "go back" function \(Alt + Left arrow\)
- [ ] 2 instances open, 1st change or reset password, refresh 2nd instance
- [ ] With privileged user perform privileged actions, try to repeat with unprivileged user cookie.

###### Profile/Account details

- [ ] Find parameter with user id and try to tamper in order to get the details of other users
- [ ] Create a list of features that are pertaining to a user account only and try CSRF
- [ ] Change email id and update with any existing email id. Check if its getting validated on server or not
- [ ] Check any new email confirmation link and what if user doesn't confirm
- [ ] File upload: [eicar](https://secure.eicar.org/eicar.com.txt), No Size Limit, File extension, Filter Bypass, [burp](https://github.com/portswigger/upload-scanner) extension, RCE
- [ ] CSV import/export: Command Injection, XSS, macro injection
- [ ] Check profile picture URL and find email id/user info or [EXIF Geolocation Data](http://exif.regex.info/exif.cgi)
- [ ] Imagetragick in picture profile upload
- [ ] [Metadata](https://github.com/exiftool/exiftool) of all downloadable files \(Geolocation, usernames\)
- [ ] Account deletion option and try to reactivate with "Forgot password" feature
- [ ] Try bruteforce enumeration when change any user unique parameter
- [ ] Check application request re-authentication for sensitive operations
- [ ] Try parameter pollution to add two values of same field
- [ ] Check different roles policy

###### Forgot/reset password

- [ ] Invalidate session on Logout and Password reset
- [ ] Uniqueness of forget password reset link/code
- [ ] Reset links expiration time
- [ ] Find user id or other sensitive fields in reset link and tamper them
- [ ] Request 2 reset passwords links and use the older
- [ ] Check if many requests have sequential tokens
- [ ] Use username@burp\_collab.net and analyze the callback
- [ ] Host header injection for token leakage
- [ ] Add X-Forwarded-Host: evil.com to receive the reset link with evil.com
- [ ] Email crafting like victim@gmail.com@target.com
- [ ] IDOR in reset link
- [ ] Capture reset token and use with other email/userID
- [ ] No TLD in email parameter
- [ ] User carbon copy email=victim@mail.com%0a%0dcc:hacker@mail.com
- [ ] Long password \(&gt;200\) leads to DoS
- [ ] No rate limit, capture request and send over 1000 times
- [ ] Check encryption in reset password token
- [ ] Token leak in referer header
- [ ] Append second email param and value
- [ ] Understand how token is generated \(timestamp, username, birthdate,...\)
- [ ] Response manipulation

###### CAPTCHA

- [ ] Send old captcha value. 
- [ ] Send old captcha value with old session ID.
- [ ] Request captcha absolute path like www.url.com/captcha/1.png
- [ ] Remove captcha with any adblocker and request again
- [ ] Bypass with OCR tool \([easy one](https://github.com/pry0cc/prys-hacks/blob/master/image-to-text)\)
- [ ] Change from POST to GET
- [ ] Remove captcha parameter
- [ ] Convert JSON request to normal
- [ ] Try header injections

###### Security Headers

- [ ] X-XSS-Protection
- [ ] Strict-Transport-Security
- [ ] Content-Security-Policy
- [ ] Public-Key-Pins
- [ ] X-Frame-Options
- [ ] X-Content-Type-Options
- [ ] Referer-Policy
- [ ] Cache-Control
- [ ] Expires

###### Credentials

- [ ] Execute the BruteForce attack or the password spray attack with default accounts credentials (Be careful with blocking policies)
- [ ] Execute the BruteForce attack or the password spray attack with found accounts credentials (Be careful with blocking policies)
- [ ] Execute the BruteForce attack or the password spray attack with own dictionaries generated (Be careful with blocking policies)

###### Additional with time

- [ ] If you have time, execute SQLMap in all requests with parameters
- [ ] Execute OWASP checklist

