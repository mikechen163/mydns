require 'rubydns'
require 'time'
require_relative 'domestic_addr'
require 'yaml'
require 'celluloid/io'

# class InvalidProtocolError < StandardError
# end

# class InvalidResponseError < StandardError
# end

# class DecodeError < StandardError
# end

# class IOError < StandardError
# end


class MyResolver < RubyDNS::Resolver

    include Domestic_address

    def initialize(servers, options = {})
            @config=YAML.load(File.open('_config.yml'))

    	    @cache=[]
    	    #load_cache(make_file_name(@config["ovsroute"]))
    	    @oversea_resolve = File.open(make_file_name(@config["ovsroute"]),'a')

            load_domestic_ip_file(make_file_name(@config["chnroute"]))

            @domestic_server_list = @config["domestic_dns_resolver"].collect do |h|
              h.values.each_with_index.collect {|x,i| i==0 ? x.to_sym : x}
            end

            @oversea_server_list = @config["oversea_dns_resolver"].collect do |h|
              h.values.each_with_index.collect {|x,i| i==0 ? x.to_sym : x}
            end

			super
    end

    def get_cache
        return @cache
    end

    def make_file_name(fname)
        return @config["home_directory"]+'/'+fname
    end

  
    def close_file
    	@oversea_resolve.close
    end
	
	def dispatch_request(message)

		    name = get_request_domain_name(message)
		    if (h = @cache.find {|h| (h[:name] == name) and h[:state_valid]}) != nil
		    	t = Time.now
               
                vf_flag = true
                h[:ttl].each do |ttl|
    		           vf_flag = (vf_flag and false) if (t-h[:time] > ttl) # if any ttl is invalid, update cache     
                end

                if vf_flag
                    @logger.debug "Found in cache [#{name} #{h[:ip]}] keep in #{t-h[:time]} seconds" if @logger 
                    return h[:response]
                else
                  #@cache.delete_if {|h| h[:name] == name}
                  h[:state_valid] = false
                end
		    end


            if @config["white_list_mode"] 
                @config["white_list"].values.each do |item|
                   found = name.index(item)
                   if found!=nil
                        response,result = request_oversea_resolver(message) 
                        ip_list = get_iplist_from_response(result)
                        ttl_list = get_ttl_from_response(result)
                        @logger.debug "Whitelist oversea resolver [#{name} #{ip_list} #{ttl_list}]" if @logger     
                        return response
                   end
                end
            end

		 	#domestic_resp, domestic_addr = get_domestic_reponse(message)
            response, result = query_dns(message,@domestic_server_list,false)

            if @config["white_list_mode"] 
              @logger.debug "Whitelist domestic resolver [#{name}  [#{arr_to_s(get_iplist_from_response(result))}]] " if @logger
              return response  
            end

            if (result.length!=0) and force_using_domestic?(name)
              @logger.debug "Force domestic resolver [#{name}  [#{arr_to_s(get_iplist_from_response(result))}]] " if @logger
		      return response  
		    end
		 	
		 	#@logger.debug "domestic_addr =  #{domestic_addr} " if @logger 
             ip_list = get_iplist_from_response(result)
		 	if (ip_list.length!=0) and  match_domestic?(ip_list[0].to_s)
		 		#do not buffer domestic ip
                @logger.debug "Found in domestic range,[#{name} #{ip_list}]" if @logger 
		 		return response 

		 	else
                response_r,result_r = request_oversea_resolver(message) 

                final_site = ""
                ip_list = get_iplist_from_response(result_r)
                if (ip_list.length!=0) and  match_domestic?(ip_list[0].to_s)
                    final_site = "domestic"
                else
                    final_site = "oversea"
                    response,result = response_r,result_r
                end

                ip_list = get_iplist_from_response(result)
                ttl_list = get_ttl_from_response(result)
                @logger.debug "Using #{final_site} resolver [#{name} #{ip_list} #{ttl_list}]" if @logger     
                return response
            end
            
		end #end of dispatch

        private

        def request_oversea_resolver(message)
            name = get_request_domain_name(message)
            response,result  = query_dns(message,@oversea_server_list,true)
                
                if (result.length!=0) 
                    #h=Hash.new
                    if ((h = @cache.find {|h| (h[:name] == name) }) == nil)  #not found
                        
                        h=Hash.new
                        h[:name] = get_request_domain_name(message)
                        h[:ip]   = get_iplist_from_response(result)
                        h[:ttl]  = get_ttl_from_response(result)
                        h[:response] = response
                        h[:time] = Time.now
                        h[:state_valid] = true
                        @cache.push(h) 
                        #append_record(h[:name],h[:ip])
                    else #found,  h[:state_valid] must be false
                        h[:name] = get_request_domain_name(message)
                        h[:ip]   = get_iplist_from_response(result)
                        h[:ttl]  = get_ttl_from_response(result)
                        h[:response] = response
                        h[:time] = Time.now
                        h[:state_valid] = true
                        @logger.debug "Updating [#{h[:name]} [#{arr_to_s(h[:ip])}] [#{arr_to_s(h[:ttl])}] " if @logger
                        #append_record(h[:name],h[:ip])
                    end
                    append_record(h[:name],arr_to_s(h[:ip]))

                else #result == 0
                    t= Time.now
                    if ((h = @cache.find {|h| (h[:name] == name) }) != nil) and (t-h[:time] < @config["longest_valid_ttl"]) #found
                        @logger.debug "Oversea dns invalid, using cache [#{h[:name]} [#{arr_to_s(h[:ip])}] [#{arr_to_s(h[:ttl])}] " if @logger
                        return h[:response],result
                    end
                end
                
                #ip_list = get_iplist_from_response(result)
                #ttl_list = get_ttl_from_response(result)
                #@logger.debug "Using oversea resolver [#{name} #{ip_list} #{ttl_list}]" if @logger
                return response , result
        end

		def get_type_a_address(name,response,oversea_flag=false)
			result = []

            #return result if response==nil
			#return result if response.answer==nil
			#@logger.debug "get_address #{response.inspect} " if @logger
            
            response.answer.each do |res|
	            res.each do |x|
	              #@logger.debug "get_address #{x.class} " if @logger
                  if  x.class ==  Resolv::DNS::Resource::IN::A #only process A type record
    	              	result.push([x.address.to_s,x.ttl.to_i]) #if x!=nil
                  end
                  if x.class == Resolv::DNS::Resource::IN::CNAME
                        name = x.name.to_s
                        result.push([name[0..name.length-2],x.ttl.to_i]) #if x!=nil
                  end
                  #@logger.debug "Uknown type #{x.inspect} " if @logger
	           

	            end
            end
            #@logger.debug "#{result.inspect} " if @logger

            # result.each do |addr| 
            # 	@logger.debug "oversea  get_address  #{addr} " if @logger and oversea_flag
            # 	@logger.debug "domestic get_address  #{addr} " if @logger and not oversea_flag
            # end

            #ip_list = result.inject(""){|r,v| r<<(v+' ')}
            # ip_list =""
            # result.each do |addr|
            # 	ip_list << ("#{addr[0]}:#{addr[1].to_i}")
            # end 
            
            # ip_list = arr_to_s(get_iplist_from_response(result))
            # ttl_list = arr_to_s(get_ttl_from_response(result))

            # #if ip_list!=""
            #   @logger.debug "oversea  : address=/#{name}/#{ip_list}/#{ttl_list}" if @logger and oversea_flag
            #   @logger.debug "domestic : address=/#{name}/#{ip_list}/#{ttl_list} " if @logger and not oversea_flag
            # #end

			return result
		end

		def query_dns(message,server_list,oversea_flag=false)
			request = Request.new(message,server_list)
			request.each do |server|
	
				@logger.debug "[#{message.id}] Sending request [#{get_request_domain_name(message)}] to server #{server.inspect}" if @logger
				
				begin
					response = nil
					
					# This may be causing a problem, perhaps try:
					# 	after(timeout) { socket.close }
					# https://github.com/celluloid/celluloid-io/issues/121
					timeout(request_timeout) do
						response = try_server(request, server)
					end
					
					if valid_response(message, response)
						addr = get_type_a_address(get_request_domain_name(message),response,oversea_flag)
						return response , addr
					end
				# rescue Task::TimeoutError
				# 	@logger.debug "[#{message.id}] Request timed out!" if @logger
				# rescue InvalidResponseError
				# 	@logger.warn "[#{message.id}] Invalid response from network: #{$!}!" if @logger
				# rescue DecodeError
				# 	@logger.warn "[#{message.id}] Error while decoding data from network: #{$!}!" if @logger
				# rescue IOError
				# 	@logger.warn "[#{message.id}] Error while reading from network: #{$!}!" if @logger
                rescue Exception => e     
				end
			end

			return nil,[]
		end #end of query_dns

		# def get_domestic_reponse(message)
  #           server_list = @config["domestic_dns_resolver"].collect do |h|
  #             h.values.each_with_index.collect {|x,i| i==0 ? x.to_sym : x}
  #           end

  #           return query_dns(message,server_list)
		# 	#return query_dns(message, [[:udp, "192.168.1.1", 53],[:udp, "223.5.5.5", 53],[:udp, "14.18.142.2", 53]])
		# end 
		# def get_oversea_reponse(message)

  #            server_list = @config["oversea_dns_resolver"].collect do |h|
  #             h.values.each_with_index.collect {|x,i| i==0 ? x.to_sym : x}
  #           end

  #           return query_dns(message,server_list,true)
		# 	#return query_dns(message, [[:udp, "127.0.0.1", 5533]],true)
		# end 

		def get_request_domain_name(message)
			name = message.question[0][0].to_s
		   return name[0..name.length-2]
	    end

	    def append_record(name,ip)
    	  #@logger.debug "Writing oversea: #{name} #{ip}" if @logger 
    	  @oversea_resolve.puts("address=/#{name}/#{ip}")
	    end

	    # def match_domestic?(ip)
	    # 	return @domestic_addr.belong_to?(ip)
	    # end

	    def force_using_domestic?(ip)
	    	@config["force_using_domestic_resolve"].values.each do |line|
              len = line.length
              if line[len-1] == '$'
                len2 = ip.length
                 return true if ip[(len2-len+1)..len2-1] == line[0..len-2]
              else
                found = ip.index(line)
                return true if found!=nil
              end
            end
            return false
	    end

	    def get_iplist_from_response(result)
            return result.collect{|addr| addr[0]}
		end

		def get_ttl_from_response(result)
            return result.collect{|addr| addr[1]}
		end

		def arr_to_s(arr)
			arr.inject(""){|r,v| r<<"#{v.to_s} "}.strip
		end
        
        def load_cache(fname)
		   File.open(fname) do |file|
	        file.each_line do |line|
	          temp,name,iplist = line.split('/')
	          if (h = @cache.find {|h| h[:name] == name}) == nil
	          	 h=Hash.new
		 	     h[:name] = name
		 		 h[:ip]   = iplist.split(' ')
		 		 h[:ttl]  =  h[:ip].collect {|x| @config["default_ttl"]} # 11 minitues default
		 		 h[:time] = Time.now
		 		 h[:state_valid] = true
		 		 h[:response] = make_response(h)
		 		 @cache.push(h) 
	          else #this domain exists
	          	update_flag = false
	          	iplist.split(' ').each do |ip|
	          	  if (nr=h[:ip].find{|x| x==ip})==nil
	          	  	h[:ip].push(ip)
                    h[:ttl].push @config["default_ttl"]
	          	  	update_flag = true
	          	  end
	          	end
	            h[:response] = make_response(h) if update_flag
	          end

            end
          end
	end #end of load_cache

    def cname?(s)
        s.split('.').each {|word| return true if word.scan(/[a-z]+/).length > 0 }
        return false
    end
	def make_response(h)
		response = Resolv::DNS::Message.new
		response.add_question(h[:name],Resolv::DNS::Resource::IN::A)

        h[:ip].sort.reverse.each do |ip|
        	# ip.split('.').collect{|x| x.to_i}.pack ('C4')
          if cname?(ip)
            ip=Resolv::DNS::Resource::IN::CNAME.new(Resolv::DNS::Name.create(ip))
          else  
		    ip=Resolv::DNS::Resource::IN::A.new(ip)
          end

		  def ip.ttl= (ttl)
		  	@ttl = ttl
		  end
		  ip.ttl = h[:ttl][0]
		  response.add_answer(h[:name],h[:ttl][0],ip)
	    end
	end
		
end


if $0 == __FILE__
 #puts "#{$0}" 

 mr=MyResolver.new([[:udp,'129.168.1.1',53]])

 mr.load_cache(make_file_name(@config["ovsroute"]))

 def a2s(arr)
    arr.inject(""){|r,v| r<<"#{v.to_s} "}.strip
 end

 mr.get_cache.each do |h|
    puts "#{h[:name]}=#{a2s(h[:ip])}"
 end

 #exit(1)

end