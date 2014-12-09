# Description:
#   like iDoneThis, but for Slack, except iDoneThis now integrates with Slack so this is
#   really just messing
#
#
# Commands:
# wedid I did <do something> — stores "do something" as a completed task
# wedid I can't <do something> — stores "do something" as a failed/blocked task
# wedid I will <do something> — stores "do something" as something to remind you about tomorrow
# wedid what — display a sumary of everyone's status' for the day
#

module.exports = (robot) ->
  
  robot.respond /I (can't|didn't|couldn't|haven't) (.+)/i, (msg) ->
    failed = msg.match[2]
    add 'did_not', failed, msg.message.user.name
    msg.send "Ah, no worries. Let me know when you #{failed}"
    
  robot.respond /I (will) (.+)/i, (msg) ->
    tomorrow = msg.match[2]
    add 'will', tomorrow, msg.message.user.name
    msg.send "Roger that, I'll remind you to: #{tomorrow}"
    
  robot.respond /I (did|\w+ed) (.+)/i, (msg) ->    
    idid = msg.match[2]
    add 'did', idid, msg.message.user.name
    msg.send ":tada: Well done!"
    
  robot.respond /what.*/i, (msg) ->
    summary_message = summary()
    msg.send summary_message
    
  robot.router.post '/wedid/what', (req, res) ->
    room   = '#general'
    robot.messageRoom room, summary()
    res.send 'OK'
    
  robot.error (err, msg) ->
    robot.logger.error err, msg

    if msg?
      msg.reply "Sorry, I think I'm broken"
      
  summary = () ->
    journal = get_journal()
    lines = for type, updates of journal
      for person, messages of updates
        person_msgs = for message in messages
           "#{type} — #{message} [@#{person}]" 
        person_msgs?.join '\n'
    message = lines?.join('\n')
    message
        
  add = (type, message, person) ->
    journal = get_journal()
    type_msgs = journal[type]
    person_msgs = type_msgs[person]
    unless person_msgs
      person_msgs = [] 
      type_msgs[person] = person_msgs
    person_msgs.push message
    save_journal journal
  
  get_journal = () ->
    key = get_key()
    journal = robot.brain.get key
#     console.log "Getting", key, journal
    unless journal?
      journal = default_journal()
    journal
  
  get_key = () ->
    today = new Date()
    dd = today.getDate()
    mm = today.getMonth()+1
    yyyy = today.getFullYear()
    "#{yyyy}-#{mm}-#{dd}"

  save_journal = (journal) ->
    key = get_key()
    robot.brain.set key, journal
    
  default_journal = () ->
    {
      'did': []
      'did_not': []
      'will': []
    }

