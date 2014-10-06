## Activities

Process Github activity streams from issues and pull requests as provided by
the GHTorrent project.

### activities

Extract activity streams from pull requests and issues. The output format is:

```
pullreq_or_issue_id,user,action,created_at
```

where:

 * `pullreq_or_issue_id`: the issue or pull request id on Github
 * `user`:  the user that performed the activity
 * `action`: the action performed
 * `created_at`: the timestamp the action was performed in seconds since the epoch


### graphs

Create collaboration graphs for developers participating in pull requests and
issues. The graphs are generated per time window (by default 6 months). The
graph is by default undirected, so developer pairs `[d1,d2]` and `[d2,d1]`
are treated as being the same link, but a command line option can generate
directed graphs.
A file is generated per timewindow. A link fade parameter (by default 2 months)
ensures that adjacent collaborations are persisted between timewindows.
The output format is:

```
from,to,weight
```

where:

  *`from`: The originating developer node
  *`to`: The target developer node
  *`weight`: The number of interactions between the developers

The file name format is:

```
graph-owner-repo-[d,u]-timewindow_duration-link_fading_duration-from-to.txt
```