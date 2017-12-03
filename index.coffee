_ = require 'lodash'
{Client} = require('pg')
fs = require 'fs'
path = require 'path'
postgresCSVLog = require 'postgres-csvlog'
Tail = require 'always-tail2'
Writable = require('stream').Writable

# Returns the newest CSV log file in the given directory.
findLatestLogFilename = (directory, callback) ->
  fs.readdir directory, (err, filenames) ->
    return callback err if err?

    latest = _(filenames)
      .filter (filename) -> filename.endsWith('.csv')
      .sort()
      .last()

    callback null, path.join(directory, latest)

class TraceEmitter extends Writable
  constructor: (@fn) ->
    super {objectMode: true}

  _write: (record, encoding, callback) =>
    {duration, sql_state_code} = record

    if record.sql_state_code isnt '00000' or not duration?
      setImmediate callback
    else
      @fn record, callback

# Calls :fn: on a JSON object representing a log entry every time a new entry is
# produced in :logFile:.
watchLogFile = (logFile, fn, callback) ->
  tail = new Tail logFile, '\n', {start: 0, interval: 500}
  logParser = postgresCSVLog()
  traceEmitter = new TraceEmitter(fn)

  tail.on 'error', callback
  tail.on 'line', (logLine) ->
    logParser.write logLine
    logParser.write '\n'

  logParser.pipe traceEmitter

# Calls :fn: whenever a new log entry is produced in the latest log file. The
# whole script restarts whenever a new log file is detected.
exports.watchLatestLogFile = (directory, fn, callback) ->
  findLatestLogFilename directory, (err, currentLogFile) ->
    callback err if err?

    watchLogFile currentLogFile, fn, callback

    # If a new log file is detected wait 10 seconds and then restart the script.
    fs.watch directory, (ev, filename) ->
      return unless ev is 'rename'
      findLatestLogFilename (err, newLogFile) ->
        if newLogFile isnt currentLogFile
          setTimeout (-> process.exit()), 10000

exports.writeRecordToDB = (record, callback) ->
  client = new Client()
  # pg-node will automatically use the config variables PGUSER, PGHOST, etc.
  client.connect()

  client.query 'INSERT INTO auto_explain_logs SELECT $1', [record], callback
