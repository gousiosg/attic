require "activities/version"

module Activities


  # Loads all activities and returns an array of tuples formatted like this:
  # [:issue_or_pullreq_id, :user, :action, :created_at]
  def all_activities(owner, repo)
    n = 0
    pullreqs = pullreq_ids(owner, repo).flat_map do |pullreq|
      pullreq_activities(pullreq[:id]).map do |line|
        n += 1
        STDERR.print "\rLoading #{n} pull request activities"
        [pullreq[:pull_req], line[:user], line[:action], line[:created_at].to_i]
      end
    end
    puts
    n = 0
    issues = issue_ids(owner, repo).flat_map do |issue|
      issue_activities(issue[:id]).map do |line|
        n += 1
        STDERR.print "\rLoading #{n} issue activities"
        [issue[:issue], line[:user], line[:action], line[:created_at].to_i]
      end
    end
    puts
    (pullreqs + issues).sort{|a,b| b[0] <=> a[0]}
  end

  def pullreq_ids(owner, repo)
    q = <<-QUERY
    select pr.pullreq_id as pull_req, pr.id as id
    from pull_requests pr, projects p, users u
    where pr.base_repo_id = p.id
      and p.owner_id = u.id
      and u.login = ?
      and p.name = ?
    order by pr.pullreq_id desc
    QUERY
    db.fetch(q, owner, repo).all
  end

  def issue_ids(owner, repo)
    q = <<-QUERY
    select i.issue_id as issue, i.id as id
    from issues i, projects p, users u
    where i.repo_id = p.id
      and p.owner_id = u.id
      and u.login = ?
      and p.name = ?
      and i.pull_request_id is null
    order by i.issue_id desc
    QUERY
    db.fetch(q, owner, repo).all
  end

  def pullreq_activities(id)
    q = <<-QUERY
    select user, action, created_at from
    (
      select prh.action as action, prh.created_at as created_at, u.login as user
      from pull_request_history prh, users u
      where prh.pull_request_id = ?
        and prh.actor_id = u.id
      union
      select ie.action as action, ie.created_at as created_at, u.login as user
      from issues i, issue_events ie, users u
      where ie.issue_id = i.id
        and i.pull_request_id = ?
        and ie.actor_id = u.id
      union
      select 'discussed' as action, ic.created_at as created_at, u.login as user
      from issues i, issue_comments ic, users u
      where ic.issue_id = i.id
        and u.id = ic.user_id
        and i.pull_request_id = ?
      union
      select 'reviewed' as action, prc.created_at as created_at, u.login as user
      from pull_request_comments prc, users u
      where prc.user_id = u.id
        and prc.pull_request_id = ?
    ) as actions
    order by created_at;
    QUERY
    db.fetch(q, id, id, id, id).all
  end

  def issue_activities(id)
    q = <<-QUERY
    select user, action, created_at from
    (
      select ie.action as action, ie.created_at as created_at, u.login as user
      from issues i, issue_events ie, users u
      where ie.issue_id = i.id
      and i.id = ?
      and ie.actor_id = u.id
      union
      select 'discussed' as action, ic.created_at as created_at, u.login as user
      from issues i, issue_comments ic, users u
      where ic.issue_id = i.id
      and u.id = ic.user_id
      and i.id = ?
    ) as actions
    order by created_at;
    QUERY
    db.fetch(q, id, id).all
  end

end
