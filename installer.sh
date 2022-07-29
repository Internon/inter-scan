#!/bin/bash

go install github.com/tomnomnom/assetfinder@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
sudo apt install dnsgen
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/haccer/subjack@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/ffuf/ffuf@latest
