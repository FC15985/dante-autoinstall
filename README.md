# dante-autoinstall
Dante Socks5 auto install script

service sockd start      # 启动服务
service sockd stop       # 停止服务
service sockd restart    # 重启服务
service sockd status     # 查看状态
service sockd tail       # 查看日志

curl https://ifconfig.co --socks5 127.0.0.1:2020 --proxy-user 用户名:密码
