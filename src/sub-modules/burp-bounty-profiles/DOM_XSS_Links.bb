[
  {
    "Name": "DOM_XSS_Links",
    "Enabled": true,
    "Scanner": 2,
    "Author": "@six2dez1",
    "Payloads": [],
    "Encoder": [],
    "UrlEncode": false,
    "CharsToUrlEncode": "",
    "Grep": [
      "true,Or,(\\.(src|href|data|location|code|action)\\s*[\\\"\u0027\\]]*\\s*\\+?\\s*\u003d)|((replace|assign|navigate|getResponseHeader|open(Dialog)?|showModalDialog|eval|evaluate|execCommand|execScript|setTimeout|setInterval)\\s*[\\\"\u0027\\]]*\\s*\\()"
    ],
    "Tags": [
      "All"
    ],
    "PayloadResponse": false,
    "NotResponse": false,
    "TimeOut1": "",
    "TimeOut2": "",
    "isTime": false,
    "contentLength": "",
    "iscontentLength": false,
    "CaseSensitive": false,
    "ExcludeHTTP": false,
    "OnlyHTTP": false,
    "IsContentType": true,
    "ContentType": "text/css,image/jpeg,image/png,image/svg+xml,image/gif,image/tiff,image/webp,image/x-icon,application/font-woff,image/vnd.microsoft.icon,font/ttf,font/woff2",
    "HttpResponseCode": "",
    "NegativeCT": true,
    "IsResponseCode": false,
    "ResponseCode": "",
    "NegativeRC": false,
    "urlextension": "",
    "isurlextension": false,
    "NegativeUrlExtension": false,
    "MatchType": 2,
    "Scope": 0,
    "RedirType": 0,
    "MaxRedir": 0,
    "payloadPosition": 0,
    "payloadsFile": "",
    "grepsFile": "",
    "IssueName": "DOM XSS Links",
    "IssueSeverity": "Information",
    "IssueConfidence": "Certain",
    "IssueDetail": "",
    "RemediationDetail": "",
    "IssueBackground": "",
    "RemediationBackground": "",
    "Header": [],
    "VariationAttributes": [],
    "InsertionPointType": [],
    "Scanas": false,
    "Scantype": 0,
    "pathDiscovery": false
  }
]