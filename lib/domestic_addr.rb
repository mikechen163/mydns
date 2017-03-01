module Domestic_address 

	 # def initialize(domestic_addr_file,force_domestic_file)
  #   	    load_domestic_file(domestic_addr_file)
  #   	    load_force_domestic_file(force_domestic_file)


  #   end

    def load_domestic_ip_file(fname)
		@ta = []
        File.open(fname) do |file|
	        file.each_line do |line|
	          code = line.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+/)[0]
	          #p code
	          t1 = code.index('/')
	          mask_len = code[t1+1..code.length-1].to_i
              mask = ('1'*mask_len+'0'*(32-mask_len)).to_i(2)
	          
	          @ta.push( [ (to_hex(code[0..t1-1]) & mask),mask,mask_len,code])
            end
          end



         # p @ta.length
         
         # @ta.each do |x|
         #   puts "#{(x[0].to_s(16))},#{to_ip(x[0])},#{x[1].to_s(16)},#{x[2]},#{x[3]}" 
         # end
	end #load_domectic_file

  def b_match_domestic?(ip_hex,list)

      len = list.length
      if (1==len)
         mask = list[0][1]
         if ((ip_hex & mask) == list[0][0])
            return true
         else
            return false
         end
      else
        
        pos = len/2
        ele = list[pos]
        mask = ele[1]
        res = ele[0]

        if ((ip_hex & mask) == res)
           return true
        end

        if (ip_hex > res)
          return false if (len == 2)
          return b_match_domestic?(ip_hex,list[(pos+1)..(len-1)])
        else
          return b_match_domestic?(ip_hex,list[0..(pos-1)])
        end
      end
  end #of function

  # def b_match_domestic?(ip_hex,list)

  #     len = list.length
  #     puts "#{ip_hex} ,#{len}, #{list}"

  #     if (1==len)
        
  #        if (ip_hex   == list[0])
  #           return true
  #        else
  #           return false
  #        end
  #     else
        
  #       pos = len/2
  #       ele = list[pos]

  #       if (ip_hex == ele)
  #          return true
  #       end

  #       if (ip_hex > ele)
  #         return false if (len == 2)
  #         return b_match_domestic?(ip_hex,list[(pos+1)..(len-1)])
  #       else
  #         return b_match_domestic?(ip_hex,list[0..(pos-1)])
  #       end
  #     end
  # end #of function

    def  match_domestic?(ip)
        ip_hex = to_hex(ip) 

        return b_match_domestic?(ip_hex,@ta)
        

        # @ta.each do |na|
        #     res = na[0]
        #     mask = na[1]
        #     mat = ip_hex & mask
        #     if (mat == res)
        #         # p show_ele(na)
        #         # p ip_hex.to_s(16)
        #         # p mat.to_s(16)
        #         # p to_ip(ip_hex)             
        #         return true
        #     end

        #     #return true if (ip_hex & mask) == res 
        # end

        # return false
    end #belong_to

	# def load_force_domestic_file(fname)
	# 	@force_list = []
 #        File.open(fname) do |file|
	#         file.each_line do |line|

	#           @force_list.push(line.strip) if line.strip.length>0
 #            end
 #          end

 #        #@force_list.each {|x| p x}
	# end #load_force_domectic_file

	

	# def is_force_domain?(name)
	# 	@force_list.each do |line|
	# 		found = name.index(line)
	# 		return true if found!=nil
	# 	end
	# 	return false
	# end



	def show_ele(x)
	  "#{(x[0].to_s(16))},#{to_ip(x[0])},#{x[1].to_s(16)},#{x[2]},#{x[3]}" 
	end

    def to_ip(hn)
    	s=hn.to_s(16)
    	if s.length == 8
    	  (s[0..1].to_i(16)).to_s+'.'+(s[2..3].to_i(16)).to_s+'.'+(s[4..5].to_i(16)).to_s+'.'+(s[6..7].to_i(16)).to_s
        else
       	  (s[0].to_i(16)).to_s+'.'+(s[1..2].to_i(16)).to_s+'.'+(s[3..4].to_i(16)).to_s+'.'+(s[5..6].to_i(16)).to_s 	
        end
    end

	def  to_hex(s)
		#p s
	    return (s.split('.').inject('') {|res,var| res << ("%02x" % var.to_i )}).to_i(16)
	    #p s.split('.')
	end

	

end

 # da=Domestic_address.new('chnroute.txt','domestic_name.conf')
 # cache = []
 # da.load_cache(cache,'oversea.conf')
 # cache.each {|h| puts "#{h[:name]} #{h[:ip]} "}

# da.load_domestic_file('chnroute.txt')
# #p da.to_hex('192.168.3.21')
# #

#  p da.belong_to?('43.227.156.2').to_s
#  p da.belong_to?('223.255.240.2').to_s
