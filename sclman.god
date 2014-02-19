God.watch do |w|
    w.name = "sclman"
    w.start = "cd /home/thirai/sclman;bundle exec ruby /home/thirai/sclman/sclman.rb start > /tmp/sclman.god.start"
    w.stop = "cd /home/thirai/sclman;bundle exec ruby /home/thirai/sclman/sclman.rb stop"
    w.keepalive
end
