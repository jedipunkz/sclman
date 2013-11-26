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

def check_ssh(ipaddr, user, key)
  begin
    Net::SSH.start("#{ipaddr}", "#{user}", :keys => ["#{key}"], :passphrase => '', :timeout => 10) do |ssh|
      return 'ok'
    end
  rescue Timeout::Error
    @error = "Timed out"
  rescue Errno::EHOSTUNREACH
    @error = "Host unreachable"
  rescue Errno::ECONNREFUSED
    @error = "Connection refused"
  rescue Net::SSH::AuthenticationFailed
    @error = "Authentication failure"
  rescue Net::SSH::HostKeyMismatch => e
    puts "remembering new key: #{e.fingerprint}"
    e.remember_host!
    retry
  end
end
