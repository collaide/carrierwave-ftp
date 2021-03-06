require 'carrierwave'
require 'carrierwave/storage/ftp/ex_sftp'

module CarrierWave
  module Storage
    class SFTP < Abstract
      def store!(file)
        f = CarrierWave::Storage::SFTP::File.new(uploader, self, uploader.store_path)
        f.store(file)
        f
      end

      def retrieve!(identifier)
        CarrierWave::Storage::SFTP::File.new(uploader, self, uploader.store_path(identifier))
      end

      class File
        attr_reader :path

        def initialize(uploader, base, path)
          @uploader, @base, @path = uploader, base, path
        end

        def store(file)
          connection do |sftp|
            sftp.mkdir_p!(::File.dirname full_path)
            sftp.upload!(file.path, full_path)
          end
        end

        def url
          tempfile =  Tempfile.new('sftp')
          connection do |sftp|
            sftp.download(full_path, tempfile)
          end
          tempfile
        end

        def filename(options = {})
          url.gsub(/.*\/(.*?$)/, '\1')
        end

        def to_file
          temp_file = Tempfile.new(filename)
          temp_file.binmode
          temp_file.write read
          temp_file
        end

        def size
          size = nil

          connection do |sftp|
            size = sftp.stat!(full_path).size
          end

          size
        end

        def exists?
          size ? true : false
        end

        def read
          connection do |sftp|
            sftp.file.open(full_path).read
          end
        end

        def content_type
          @content_type || ''
        end

        def content_type=(new_content_type)
          @content_type = new_content_type
        end

        def delete
          connection do |sftp|
            sftp.remove!(full_path)
          end
        rescue
        end

        private

        def full_path
          "#{@uploader.sftp_folder}/#{path}"
        end

        def connection
          SFTPConnection.connection(@uploader.sftp_host, @uploader.sftp_user, @uploader.sftp_options)
          yield SFTPConnection.instance.sftp
        end

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
      end
    end
  end
end

CarrierWave::Storage.autoload :SFTP, 'carrierwave/storage/sftp'

class CarrierWave::Uploader::Base
  add_config :sftp_host
  add_config :sftp_user
  add_config :sftp_options
  add_config :sftp_folder
  add_config :sftp_url

  configure do |config|
    config.storage_engines[:sftp] = "CarrierWave::Storage::SFTP"
    config.sftp_host = "localhost"
    config.sftp_user = "anonymous"
    config.sftp_options = {}
    config.sftp_folder = ""
    config.sftp_url = "http://localhost"
  end
end
