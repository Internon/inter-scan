# inter-scan

Inter-scan is a tool based on modules that are on the folder src/modules and plugins that are on the folder src/plugins that in fact are wrappers of executing some tools in order to automate usual processes.
The tool can be executed with an interactive mode and as a full scan or a module scan.

## Example 

------------   INTERNON   ------------------  
Usage: /usr/bin/inter-scan [OPTIONS]  
  Options:  
          -I {file with targets by line}  
          -i {IP or IP/CIDR or domain}  
          -t {} number of threads to use in all modules (Default 20)  
          -m {all/MODULE-NUMBER (Check the number on -l parameter)}  
          -s {all/SPEED-NUMBER} (Check the number on -l parameter) Important: slower is thorough  
          -l {any} List modules and speed  
          -i Interactive execution  
          -c {company name} for extra recon  
          -p execute plugins  
          -e exclude domain recon, just perform the target  
  Examples:  
          /usr/bin/inter-scan -i 127.0.0.1 -s all -m all -c {COMPANY} -t 30  
          /usr/bin/inter-scan -l any  
          /usr/bin/inter-scan -I targets.txt -m all -c {COMPANY} -t 30  
          
## Speed (-s)

all  
quick (2)  
slow (3)  
slowest (4)

## Scan type (-m)

module based (number of the module)  
fullscan (all)  
targetscan (all with option -e)

## Scanner modules

- Domain recon
- Port scan (Nmap)
- Vulnerability recon (Services parsing and some special ports recon + generate file wiht IPs and domains)
- Web recon (http ports and fuzzing)
- Web attack (Nuclei)
- Subdomain takeover attack (Subjack)

## Scanner plugins

- Parameter fuzzing and XSS check
- Web attack with Burp (Needed BurpSuitePro)
- Dictionary creation
- Github dorking (GitDorker)
- Cloud buckets scan (Aws-extender-cli)

## TO-DO

- [x] Add a parameter to exclude the plugins execution
- [ ] Work with github submodules to add the sub-modules folder when git clone
- [x] Perform an installer file 
- [ ] Perform a docker

