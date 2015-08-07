mydns is used for anti dns polution, inspired by [chinadns](https://github.com/clowwindy/ChinaDNS)

the main dns lookup process is as follows:

 1 checking the internal dns cache.
   if found and ttl valid ,return cached item
   
 2 lookup in domestic resolvers , check the result against chnroute.txt. if found in file, this ip is in  domestic use. return. 
  
 3 lookup in oversea dns resolver. if success, update internal cache. return .
 
 4 Its better to use dnscrypt-proxy to ensure oversea dns query will not be poluted.
 
 
 email: mikechen163@hotmail.com
 
####  INSTALL
   
   mydns is a ruby program  and use rubydns,so use gem to install rubydns first.
   
    gem install rubydns
    git clone https://github.com/mikechen163/mydns.git
    cd mydns
    ruby mydns.rb

the program default listen on 127.0.0.1:53,then use dig to test.

    dig @localhost -p 53 www.google.com     
   
    
    