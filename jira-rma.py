### NOTE: SEE jira.txt FOR MORE NOTES AND DEVICE LIST !!!
# vim macro for formatting contact info; TODO remove when done writing this script
# df:xi{ "name": "A",jdd0df:xkJa"phone": "A",j0df:xkJa"email": "A" }jj0

import requests
import base64
import json


### BEGINNING OF USER VARIABLES SECTION ###

email_address = 'hshabbir@evertz.com' # your Evertz email address
user_id = '' # your accountId; TODO Remove if not needed if extracted from API key
api_key = '' # TODO scramble before sharing this file with others as this is my personal key; your API key created on the following page: https://id.atlassian.com/manage-profile/security/api-tokens
items_per_line = 8

### END OF USER VARIABLES SECTION ###


### Variables and Helper Functions Section
# Contacts List (NOTE: modify and verify before running program)
db = { # TODO copy in from jira.txt; type is {{[{}]}}; sort names
    "UND": {
        "contacts": [
        "locations": [] 
    }
}

devices = [ "7800EMR-IO", "7800FC", "7800FR" ] # TODO copy in from jira.txt

RMA_types = ['repair', 'loaner', 'repair+loaner', 'standard', 'extended']

severities = [
    { "value": "L1", "id": "11523" },
    { "value": "L2", "id": "11524" },
    { "value": "L3", "id": "11525" },
    { "value": "L4", "id": "11526" },
]

def inf_input(message, callback, cond): # TODO strip all spaces from input?
    while True:
        val = callback(input(message).strip())
        if not cond(val):
            print("?")
            continue
        else:
            return val

id = lambda x: x
# TODO remove the two lines below once done
#num = inf_input("Enter 5 digits: ", id, lambda x: len(x) == 5)
#contact = inf_input("Contact Name: ", lambda x: list(filter(lambda contact: contact['name'] == x, contacts)), lambda x: len(x) == 1)


### Inputs Section; TODO "" should not cause error on non-default inputs
ticket = inf_input('Ticket Key (eg. DOM-740): ', lambda x: x.upper(), lambda x: x[:x.find("-")] in list(db.keys())) # the ticket you wish to RMA
project = ticket[:ticket.find("-")]

print('RMA Types: ', ' '.join([ f'[{idx+1}] {x}   ' for idx, x in enumerate(RMA_types) ]))
RMA_type = inf_input('RMA Type (1/2/3/4/5; default 1): ', lambda x: 1 if x == "" else int(x), lambda x: x >= 1 and x <= 5) - 1 # get index of rma list

severity = inf_input('Severity Level (1/2/3/4; default 3): ', lambda x: 3 if x == "" else int(x), lambda x: x >= 1 and x <= 4) - 1 # get index of severities

part_number = inf_input('Part Number (must match device from ECOweb): ', lambda x: x.upper(), lambda x: x in devices)
old_sn = inf_input('Old Serial Number (10 digits): ', id, lambda x: len(x) == 10)
new_sn = inf_input('New Serial Number (default None): ', lambda x: "None" if x == "" else x, lambda x: len(x) == 10 or x == "None")
firmware = (lambda x: "TBD" if x == "" else x)(input('Required Firmware (default: TBD): ').strip())

description = input('Problem Description (one line): ').strip()

names = [ f'   [{idx+1}] {x["name"]}' for idx, x in enumerate(db[project]['contacts']) ]
print('Contact Names:\n' + '\n'.join([' '.join(names[i:i + items_per_line]) for i in range(0, len(names), items_per_line)]))
contact = int(inf_input(f'Contact Name (1-{len(names)}): ', id, lambda x: x != "" and int(x) >= 1 and int(x) <= len(names))) # to get index of contact



### API call section
ticket_api_url = f"https://evertz.atlassian.net/rest/api/3/issue/{ticket}?expand=renderedFields"
ticket_response = \ 
    requests.get(ticket_api_url, 
                 headers={ 
                          'Authorization': 'Basic {}'.format(base64.b64encode( f'{email_address}:{api_key}'.encode('ascii'))
                                                             .decode('ascii')) })

ticket_response.json()["id"] # id is 323963


toc_api_url = f"https://evertz.atlassian.net/rest/api/3/issue/{ticket_response.json()['id']}/properties/k15t.backbone.syncinfo"
toc_response = \
        requests.get(toc_api_url, 
                     headers={ 
                              'Authorization': 'Basic {}'.format(base64.b64encode(
                                  f'{email_address}:{api_key}'.encode('ascii')).decode('ascii')) 
                              })

toc = toc_response.json()['value']['remoteIssueKey'][0] # toc key is TOC-18222


###### TODO Work on the below section


"""
"customfield_10803": { "value": "L1", "id": "11523" },
"customfield_10803": { "value": "L2", "id": "11524" },
"customfield_10803": { "value": "L4", "id": "11526" },

"customfield_11718": { "value": "Notre Dame", "id": "11979" },
"customfield_11718": { "value": "Rogers Media", "id": "11531" },

"customfield_12301": { "value": "Repair", "id": "11903" },
"customfield_12301": { "value": "Standard Warranty", "id": "11901" },
"customfield_12301": { "value": "Extended Warranty", "id": "12408" },

"customfield_12900": [ { "value": "Toronto", "id": "16299" } ], 
"""

# Create subtask on TOC issue and fill out details for that subtask (eg. create a subtask like TOC-18410)
# multiline text fields take atlassian Document Format content
# content will be in: update, fields, issueType, parent (issue_number above)
subtask_payload = json.dumps({
  "fields": {
    "summary": "TESTING (PLEASE IGNORE)",
    "parent": { "key": toc }, # the ticket key you want to create RMA subtasks on
    "issuetype": { "id": "10400" }, # the ID related to RMA; stays the same each time
    "project": { "id": "13000" }, # the ID related to TOC; stays the same each time
    "customfield_10803": { "value": "L3", "id": "11525" }, # Severity
    "customfield_11718": { "value": "", "id": "11978" }, # Customer
    "customfield_12301": { "value": "Loaner", "id": "11902" }, # RMA Type
    "customfield_12303": "7814UC-4K", # Part Number
    "customfield_12900": [ { "value": "Burlington", "id": "12600" } ], # Site Location
    "customfield_13402": "TBD", # Required Firmware
    "customfield_12501": "", # Old Serial Number
    "customfield_12552": { # Problem Description textarea ############# CONTINUE FROM HERE TO MAKE SURE DEFAULTS ARE CORRECT !!!!!!!!!!!
      "version": 1,
      "type": "doc",
      "content": [
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Problem Description: UC will not pass video, tried multiple slots same results." }, { "type": "hardBreak" },
            { "type": "text", "text": "Firmware Required: TBD" }, { "type": "hardBreak" },
            { "type": "text", "text": "IP Addresses:" }, { "type": "hardBreak" },
            { "type": "text", "text": "Sign off required by:" }
          ]
        }
      ]
    }
    "customfield_12336": { # Contact Information textarea
      "version": 1,
      "type": "doc",
      "content": [
        { "type": "paragraph", "content": [] },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Contact Information" }, { "type": "hardBreak" },
            { "type": "text", "text": "Contact Name: Jamie Verbrugge" }, { "type": "hardBreak" },
            { "type": "text", "text": "Company Name: Dome Productions" }, { "type": "hardBreak" },
            { "type": "text", "text": "Phone Number: 416 550-6624" }, { "type": "hardBreak" },
            { "type": "text", "text": "Email Address: Jamie.Verbrugge@bellmedia.ca" }, { "type": "hardBreak" },
            { "type": "text", "text": "Additional Email Address (to CC): evtoc@evertz.com, hshabbir@evertz.com, misaac@evertz.com, vkohli@evertz.com" }, { "type": "hardBreak" },
            { "type": "text", "text": "Type: Warranty Replacement" }, { "type": "hardBreak" },
            { "type": "text", "text": "S/N: " }, { "type": "hardBreak" },
            { "type": "text", "text": "RMA Urgently Needed: Yes" }, { "type": "hardBreak" },
            { "type": "text", "text": "Flag to someone upon receipt:" }, { "type": "hardBreak" },
            { "type": "text", "text": "Verified by someone prior to shipping:" }, { "type": "hardBreak" },
            { "type": "text", "text": "Urgent (requires expedited FA turn-around):" }, { "type": "hardBreak" },
            { "type": "text", "text": "HOT RMA (expedited FA information required):" }, { "type": "hardBreak" },
            { "type": "text", "text": "Contact authorizes automatic return of unit if Failure Analysis finds no fault:" }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Equipment covered under SLA (Yes/No): Yes" }, { "type": "hardBreak" },
            { "type": "text", "text": "Timeline:" }
          ]
        },
        {
          "type": "paragraph",
          "content": [ { "type": "text", "text": "Notes:" } ]
        },
        {
          "type": "paragraph",
          "content": [ { "type": "text", "text": "Site/Truck:" }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Shipping Address:" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Billing Address:" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }, { "type": "hardBreak" },
            { "type": "text", "text": "" }
          ]
        }
      ]
    } # End Contact Information textarea
  }
})


subtask_response = \
        requests.request("POST", 
                         "https://evertz.atlassian.net/rest/api/3/issue",
                         data=subtask_payload,
                         headers={ 
                                  'Accept': 'application/json', 
                                  'Content-Type': 'application/json', 
                                  'Authorization': 'Basic {}'.format(base64.b64encode(
                                      f'{email_address}:{api_key}'.encode('ascii')).decode('ascii')) 
                                  })


subtask_response.json()
subtask_response.status_code # 400


print(json.dumps(json.loads(subtask_response.text), sort_keys=True, indent=4, separators=(',', ': ')))


######
#issue_number = input('Enter the TOC issue number: ').strip()

# task_url will be used to 
#if issue_number[:4] == 'TOC-':
    #task_url = 'https://evertz.atlassian.net/browse/' + issue_number
#else:
    #task_url = 'https://evertz.atlassian.net/browse/TOC-' + issue_number
