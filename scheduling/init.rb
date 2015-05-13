# encoding: UTF-8
require_relative './jobs'

# Start jobs
scheduler = ApiScheduler.new
scheduler.startApiMaintenance '1s'