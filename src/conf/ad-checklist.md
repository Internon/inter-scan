###### Generic Active Directory

- [ ] Check for known vulnerabilities in AD
- [ ] Check for Vulnerable Certificate Template

###### Checks on a server joined to AD

- [ ] BloodHound (Execute this with SYSTEM account)
- [ ] Search credentials on files
- [ ] Retrieve credentials of other users in memory (As admin)
- [ ] SMB Relay
- [ ] If the server is being used by more people force NTLM authentications to steal credentials from the victim by creating a file
- [ ] Kerberoasting with SYSTEM account (It will use the server account $server)
- [ ] Asreproast with the real list of user


###### Checks without user

- [ ] Search credentials in opened network shares
- [ ] Asreproast with a list of users
- [ ] Bruteforce attack or password spray attack (Careful blocking policies)
- [ ] If there is a network share where you can write force NTLM authentications to steal credentials from the victima by creating a file

###### Checks with user

- [ ] BloodHound (Execute this with each user you retrieve to see the possible lateral movements)
- [ ] Kerberoast
- [ ] Asreproast with the real user list
- [ ] Search credentials in network shares (SYSVOL, etc)
- [ ] Check lateral movement with bloodhound and make a pass the hash or pass the ticket
- [ ] Retrieve credentials of other users in memory
- [ ] Check privileges of your account and the posisbilities to make some attacks (RBCD, LAPS read, add to group, dcsync, etc)
- [ ] If there is a network share where you can write force NTLM authentications to steal credentials from the victim by creating a file

