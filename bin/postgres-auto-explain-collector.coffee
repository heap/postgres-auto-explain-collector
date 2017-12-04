#!/usr/bin/env coffee

{watchLatestLogFile, writeRecordToDB} = require '..'

{argv} = require 'yargs'
  .help 'h'
  .alias 'h', 'help'
  .usage '''
    Tails the Postgres log and writes query plans to a database.
    '''
  .option 'log-directory',
    describe: 'The directory of the Postgres logs.'
    type: 'string'
    required: true


watchLatestLogFile argv.logDirectory, writeRecordToDB, (err) ->
  process.stdout.write err.message + '\n'
  process.exit 1
