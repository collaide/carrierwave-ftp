class SFTPConnection
  include Singleton

  attr_reader :sftp

  def self.connection(host, user, options)
    @@host = host
    @@user = user
    @@options = options
  end

  private

  def initialize
    @sftp ||= Net::SFTP.start(@@host, @@user, @@options)
  end
end