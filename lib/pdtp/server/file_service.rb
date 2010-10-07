#--
# Copyright (C) 2006-08 Medioh, Inc. (info@medioh.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.org/
#++

require 'digest/sha1'
require 'digest/sha2'

module PDTP
  class Server
    # The file service manages file information and serves files
    class FileService
      attr_reader :client_id
      
      # FIXME this really shouldn't be necessary
      attr_accessor :chunk_transfers
      
      def initialize(host, port)
        @host, @addr, @port = host, IPSocket.getaddress(host), port
        @chunk_size = 512000
        @root = nil
        @enabled = false
        @files = {}
        @chunk_transfers = {}
        
        # FIXME perhaps a better approach to generating this is in order
        @client_id = Digest::SHA1.hexdigest "--#{Time.now}--#{rand}--"
      end
      
      # Address of the file service
      def remote_addr; @addr; end
      
      # Port of the file service
      def listen_port; @port; end
      
      def enable(path, options = {})
        raise "already enabled" if @enabled
        @enabled = true
        @root = path.gsub(/\/$/, '')
        rescan
      end
      
      def rescan
        processed = []
        
        Dir.glob(File.join(@root, '**', '*')).each do |path|
          url = url_for path.gsub(@root, '')
          processed << url
          
          stat = File.stat(path)
          @files[url] ||= Info.new(path, stat.size, @chunk_size) if stat.file?
        end
        
        unprocessed = @files.keys - processed
        unprocessed.each { |url| @files.delete url }
      end
      
      def [](url)
        info = @files[url]
        return info unless info.nil?
        
        # If the path didn't match, rescan and try again
        rescan
        @files[url]
      end
      
      def each(&block); @files.each(&block); end      
      def map(&block); @files.map(&block); end
      
      #######
      private
      #######
      
      def url_for(path)
        "http://#{@host}#{path}"
      end
      
      class Info
        attr_reader :path, :size, :chunks, :chunk_size, :streaming
        
        def initialize(path, size, chunk_size, streaming = false)
          @path, @size, @chunk_size, @streaming = path, size, chunk_size, streaming
          @chunks = @size / @chunk_size + (@size % @chunk_size == 0 ? 0 : 1)
          @chunk_digests = []
        end
        
        # Byte range for a given chunk
        def byte_range(chunk_id)
          start = chunk_id * @chunk_size
          start..(start + chunk_size(chunk_id) - 1)
        end
        
        # Chunk ID of the given byte range
        def chunk_range_for_byte_range(byte_range)
          unless byte_range.begin % @chunk_size == 0
            raise ArgumentError, "range start not chunk aligned"
          end
          
          chunk_begin = byte_range.begin / @chunk_size
          
          if byte_range.end == @size - 1
            chunk_end = @chunks
          elsif byte_range.end - byte_range.begin == @chunk_size - 1
            chunk_end = (byte_range.end + 1) / @chunk_size - 1
          else raise ArgumentError, "range end not chunk aligned"
          end
          
          raise ArgumentError, "range start exceeds range end" if chunk_begin > chunk_end
          
          chunk_begin..chunk_end
        end
        
        # Size of a given chunk
        def chunk_size(chunk_id = nil)
          return @chunk_size if chunk_id.nil?
          return if chunk_id < 0 or chunk_id >= @chunks
          chunk_id == @chunks - 1 ? @size - @chunk_size * chunk_id : @chunk_size
        end
        
        # SHA256 digest for a given chunk
        def chunk_digest(chunk_id)
          raise ArgumentError, "invalid chunk ID" if chunk_id < 0 or chunk_id > chunks
          @chunk_digests[chunk_id] || generate_chunk_digest(chunk_id)
        end
        
        # Cache the SHA256 digest of the given chunk ID
        def digest_chunk(chunk_id, data)
          digest = Digest::SHA256.hexdigest data
          @chunk_digests[chunk_id] = digest
          digest
        end
        
        #######
        private
        #######
        
        def generate_chunk_digest(chunk_id)
          File.open(@path) do |file|
            file.pos = chunk_id * @chunk_size
            digest_chunk chunk_id, file.read(chunk_size(chunk_id))
          end
        end
      end
      
      # A Mongrel::HttpHandler for the file service
      class Handler < Mongrel::HttpHandler
        def initialize(dispatcher, file_service)
          @dispatcher, @file_service = dispatcher, file_service
        end
        
        def process(request, response)
          peer_id = request.params["HTTP_X_PDTP_PEER_ID"]
          return send_error(response, 400, "X-PDTP-Peer-ID header unspecified") unless peer_id
          
          # GET is the only allowable method
          unless request.params["REQUEST_METHOD"] == 'GET'
            return send_error(response, 405, "Method #{request.params["REQUEST_METHOD"]} unavailable")
          end

          url = "http://" + request.params["HTTP_HOST"] + request.params["REQUEST_PATH"]
          
          unless (file_info = @file_service[url])
            return send_error(response, 404, "The requested file #{url} was not found")
          end
          
          unless (byte_range = parse_range_header request.params["HTTP_RANGE"])
            return send_error(response, 400, "Invalid or missing HTTP Range header")
          end
          
          transfer_id = ChunkTransfer.generate_id @file_service.client_id, peer_id, url, byte_range
          transfer = @file_service.chunk_transfers[transfer_id]
          
          remote_addr = request.params["REMOTE_ADDR"]
          unless transfer and remote_addr = transfer.connector.remote_addr
            return send_error(response, 403, "Transfer unauthorized by server") 
          end
          
          send_chunk response, file_info, transfer
        end
        
        #######
        private
        #######
        
        def parse_range_header(range_header)
          return unless range_header
          return unless range = range_header.scan(/bytes=([0-9]+)-([0-9]+)/).first
          Integer(range[0])..Integer(range[1])
        end
        
        def send_chunk(response, file_info, transfer)
          byte_range = transfer.byte_range
          
          data = File.open(file_info.path) do |file|
            file.pos = transfer.byte_range.begin
            file.read file_info.chunk_size(transfer.chunk_id)
          end
          
          file_info.digest_chunk transfer.chunk_id, data
          
          response.start(206) do |head, out|
            head['Content-Range'] = "bytes #{byte_range.begin}-#{byte_range.end}/#{file_info.size}"
            out << data  
          end
        end
        
        def send_error(response, code, message)
          response.start(code) { |_, out| out << message }
          nil
        end
      end
    end
  end
end