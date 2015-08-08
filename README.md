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
    
------------------------    
#### 1 概述

要封锁某个网站，除了通过GFW禁止此网站之外，还可以通过DNS污染的方式，限制用户不能得到此网站正确的IP地址。 通过GFW限制网站，就像关闭了到达目的地的直达航班，还可以通过转机的方式到达；然而DNS污染直接修改了地图，用户在地图上根本找不到目的地。

在查询地图的时候，如果发现用户访问某个限制的地址，那么DNS污染就直接修改返回的结果，导致用户访问的地址，不是正确的地址。通过[dnscrypt-proxy](https://github.com/jedisct1/dnscrypt-proxy/)这个项目，访问DNS的请求被全程加密，从而可以解决DNS返回结果被污染的问题。

但这带来了新问题：

1 国外的DNS服务器，对于国内的ip域名的解析，很可能不是最合适的。例如电信网的用户访问国内的网站，国内的DNS服务器会根据发起源是电信网络，返回位于电信网络内的服务器位置，而海外的服务器返回结果则是和发起网络无关的，很可能返回一个位于联通网络的服务器，导致网站访问超慢。

2 国外DNS服务器本身访问时延就不小，因此整个网络访问速度也变慢。

[chinadns](https://github.com/clowwindy/ChinaDNS)通过检查网站的IP地址列表，是否属于国内地址，从而解决了整个问题。

#### 2 解决方案设计

 解决这个问题需要一个运行在本机上的DNS缓存服务器。由于就运行在本机，所以不存在被污染的问题。方案设计如下
 
 1 首先查看本地dns缓存，如果找到对应的那么项目，且ttl值合法，那么返回缓存中dns条目。否则进入步骤2
 
 2 访问国内的dns服务器，检查返回结果中的ip地址，是否属于国内地址，如果是国内地址那么直接返回结果给用户。如果此IP地址不是国内地址那么进入步骤3
 
 3 通过dnscrypt访问海外的dns服务器，如果返回值有效，更新缓存，返回结果给用户

   
#### LICENSE
   
The MIT License (MIT)

Copyright (C) 2015 mike chen

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.    