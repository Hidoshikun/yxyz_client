个人用Erlang编写了一个简陋的客户端模拟程序，对应网上广为流传的英雄远征Erlang服务端源码（之前没发现源码里就有模拟客户端的代码，发现之后看了下，感觉协议也不太对的上......），可以完成平台登录，创建角色，进入游戏的操作，用来观察玩家登录的完整过程足够了。

此处只有客户端的代码，服务端代码流传很广个人就不上传了，完整的客户端和服务端代码打包在百度云中自取：
链接：https://pan.baidu.com/s/1_M4ddOFgACdlxEKpjqDW2w  提取码：cwjd 

如果有感兴趣的同学对其继续完善，甚至能还原游戏内大部分的功能的话，请务必通知我去玩一下。

为了配合客户端的登录以及方便调试，服务端主要进行了以下修改：
0.安装mysql，新建数据库并导入sdzmmo.sql文件，在common.hrl中修改数据库连接参数
1.添加shell内便捷热更新方法：在shell内调用u(ModuleName)即可。具体添加的内容：util:mu/1函数，user_defualt.erl模块
2.修改了心跳包最大超时时间，修改sd_reader.erl中的HEART_TIMEOUT，不至于让客户端挂一会就断开连接挂掉
3.屏蔽了通行证验证，pp_account:is_bad_pass/4返回true
4.服务器使用了sasl自带的日志系统，可在log.config中进行配置，如果需要查看错误信息，需要使用rb模块进行查看

https://blog.csdn.net/s291547/article/details/88935204 这是个人对Erlang游戏源码进行分析的最后一篇文章，里面有对源码的一些总结。