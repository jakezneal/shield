# Workflow

How work reaches shield in this project, and who makes product decisions. The Dispatcher reads this at the start of every shield command. `/shield-init` can fill it in. The defaults below make shield work from plain requests with no tickets and no product roles.

## Tickets

- Source: none
  <!-- none: plain requests. local: .tickets/ in this repository. jira: a Jira project. -->
- Local ticket prefix: T
- Jira site:
  <!-- for example yourteam.atlassian.net -->
- Jira project key:
- Jira ready query:
  <!-- JQL for tickets ready to work on, in priority order. For example:
       project = ABC AND status = "Selected for Development" ORDER BY Rank -->
- Jira status for In progress:
- Jira status for Review:
- Jira updates: ask
  <!-- ask: shield shows each transition, comment or new ticket and waits for your yes.
       off: shield never writes to Jira and gives you text to paste instead. -->

## Product roles

- Product Owner: none
- Product Manager: none
  <!-- none: you make product decisions as they come up.
       human: a person holds the role. Shield labels their decisions and prepares notes for them.
       agent: shield's AI role does the job, escalating to you whenever it can't decide. -->

## Notes

- _Anything else about how this team works that shield should follow. Role titles only; no names or contact details._
