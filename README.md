mydns is used for anti dns polution, inspired by [chinadns](https://github.com/clowwindy/ChinaDNS)

the main dns lookup process is as follows:

 1 checking the internal dns cache.
   if found and ttl valid ,return cached item
   
 2 lookup in domestic resolvers , check the result against chnroute.txt. if found in file, this ip is in  domestic use. return. 
  
 3 lookup in oversea dns resolver. if success, update internal cache. return .
 
 4 Its better to use dnscrypt-proxy to ensure oversea dns query will not be poluted.
 
 
####  INSTALL
   
   mydns is a ruby program  and use rubydns,so use gem to install rubydns first.
   
    sudo gem install rubydns
    git clone https://github.com/mikechen163/mydns.git
    cd mydns
    sudo ruby mydns.rb

the program default listen on 127.0.0.1:53,then use dig to test.

    dig @localhost -p 53 www.google.com     
   
#### LICENSE
   
The MIT License (MIT)

Copyright (c) 2015 mike chen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
    