# Description:
#   give the room a heads up that a pr comment has been made
#
# Commands:
#   hubot list all repos - list all the repos that we own on github
#   hubot list open pr [repo] - list the open pull requests
#   hubot list tracked - list the repos being tracked
#   hubot track <repo> - start tracking on a repo
#   hubot untrack <repo> - stop tracking on a repo
#
# Configuration:
# HUBOT_GITHUB_TOKEN
# HUBOT_GITHUB_OWNER
# HUBOT_GITHUB_DEFAULT_REPO


module.exports = (robot) ->
  github = require('githubot')(robot)
  urlparser = require('url')

  BOT_NAME="PRbot" 
  robot.enter = (res) ->
    res.send "#{BOT_NAME} is in the house!"

  robot.leave = (res) ->
    res.send "#{BOT_NAME} is out of the house!"

  # array of repos we will look at
  trackedRepos = [];

  if !process.env.HUBOT_GITHUB_TOKEN
     throw new Error("Need to provide HUBOT_GITHUB_TOKEN,HUBOT_GITHUB_DEFAULT_REPO and HUBOT_GITHUB_OWNER as environmental variables")

  if process.env.HUBOT_GITHUB_OWNER
     owner = process.env.HUBOT_GITHUB_OWNER
  else
     throw new Error("Need to provide HUBOT_GITHUB_TOKEN,HUBOT_GITHUB_DEFAULT_REPO and HUBOT_GITHUB_OWNER as environmental variables")


  if process.env.HUBOT_GITHUB_DEFAULT_REPO
     defaultrepo = process.env.HUBOT_GITHUB_DEFAULT_REPO
     trackedRepos.push defaultrepo
  else
     throw new Error("Need to provide HUBOT_GITHUB_TOKEN,HUBOT_GITHUB_DEFAULT_REPO and HUBOT_GITHUB_OWNER as environmental variables")


  trackingIntervalId = setInterval () ->
      for repo in trackedRepos
        date = new Date().getTime();
        date -= (60 * 1000); #60 seconds
        dateString = new Date(date).toISOString();

        pullsWithComments = []
        github.get "repos/#{owner}/#{repo}/pulls", (pulls) ->
           for w in pulls 
              pr_number = w.number

              github.get "repos/#{owner}/#{repo}/pulls/#{pr_number}/comments?since=#{dateString}", (comments) ->
                if comments.length > 0
                   if pullsWithComments.indexOf(pr_number) == -1
                      pullsWithComments.push pr_number


              github.get "repos/#{owner}/#{repo}/issues/#{pr_number}/comments?since=#{dateString}", (comments) ->
                if comments.length > 0
                   if pullsWithComments.indexOf(pr_number) == -1
                      pullsWithComments.push pr_number

        #shit .. there is a bug in githubot that might be confusing data with a callback. have to go the timeout route
        pullCheck = () ->
           for x in pullsWithComments
              res.send "#{x} has new comments"
        setTimeout(pullCheck, 5000)


    , 60000


  #######
  # track a repo
  #######
  robot.hear /\btrack\b(.*)/i, (res) ->
    repo = res.match[1].trim()
    if (repo == '' || repo == null)
      repo = defaultrepo

    if trackedRepos.indexOf(repo) ==-1
       trackedRepos.push repo
    else
       res.send "already tracking #{repo}"

  #######
  # untrack a repo
  #######
  robot.hear /\buntrack\b(.*)/i, (res) ->
    repo = res.match[1].trim()
    index = trackedRepos.indexOf(repo);
    if index ==-1
       res.send "wasn't tracking #{repo} anyway"
    else
       trackedRepos.splice(index,1)
       res.send "stopped tracking #{repo}"


  #######
  # list all the tracked repos 
  #######
  robot.hear /\btracked\b/i, (res) ->
    if trackedRepos
      res.send "I'm tracking #{trackedRepos}"
    else
       res.send "I've got nothin.."

  #######
  # list all the repos that we have in github
  #######
  robot.respond /list all repos/i, (res) ->
    #github.get "user/repos", (repos) ->
    github.get "orgs/#{owner}/repos", (repos) ->
       for w in repos 
          if w.private
             visibility = "private"
          else
             visibility = "public"

          res.send "#{w.full_name}:#{visibility}"



  #######
  # list open pull requests on the specified repo
  #######
  robot.respond /list open pr(.*)/i, (res) ->
    repo = res.match[1].trim()
    if (repo == '' || repo == null)
      repo = defaultrepo
    
    res.send "open pulls on #{repo}.."
    github.get "repos/#{owner}/#{repo}/pulls", (pulls) ->
       for w in pulls 
          res.send w.html_url

