#!/usr/bin/env ruby

require 'net/ssh'

module SshCon
  def self.connect(host)
  opt = {
    :keys => '/home/thirai/novakey01',
    :passphrase => '',
    :port => 22
  }
    Net::SSH.start(host, 'root', opt) do |ssh|
      stderr = ""
      ssh.exec!("echo test") do |channel, stream, data|
        stderr << data if stream == :stderr
      end
      return stderr
    end
  rescue
    stderr = "can not connect via ssh"
    return stderr
  end
end

# p = SshCon.connect("10.200.10.2")
# p p

