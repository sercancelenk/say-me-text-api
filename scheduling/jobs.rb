require 'rufus-scheduler'
require 'date'

scheduler = Rufus::Scheduler.new

class ApiScheduler
  def initialize
    @scheduler = Rufus::Scheduler.new
  end
  def startApiMaintenance period
    @scheduler.every period.to_s do
      puts "Blah Balh"
    end
  end
end