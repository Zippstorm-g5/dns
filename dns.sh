#!/bin/bash
# -*- coding:utf-8 -*-

# 检查jq是否已安装
if ! command -v jq &> /dev/null; then
    echo "jq 未安装，开始安装..."

    # 更新包信息
    sudo apt update

    # 安装jq
    sudo apt install jq -y

    echo "jq 安装完成。"
else
    echo "jq 已安装，跳过安装步骤。"
fi

echo -n "解析类型:(A or AAAA) "
read ip_type

username=$(jq -r '.inbounds[0].users[0].username' /usr/local/etc/sing-box/config.json)


countrycode=${username: -5:2}


RECORD_ID=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/${CF_Zone_ID}/dns_records?name=${countrycode}.zippstorm.com" \
     -H "Authorization: Bearer ${CF_Token}" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')


if [ "$ip_type" == "A" ]; then
    # 如果IP类型是A，获取IPv4地址
    address=$(curl -4 ip.sb)
elif [ "$ip_type" == "AAAA" ]; then
    # 如果IP类型是AAAA，获取IPv6地址
    address=$(curl -6 ip.sb)
else
    echo "Unknown IP type: $ip_type"
    exit 1
fi
echo $countrycode
echo $address
echo $RECORD_ID
if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "null" ]; then
     curl -X POST "https://api.cloudflare.com/client/v4/zones/${CF_Zone_ID}/dns_records" \
          -H "Authorization: Bearer ${CF_Token}" \
          -H "Content-Type: application/json" \
          --data "{\"type\":\"${ip_type}\",\"name\":\"${countrycode}.zippstorm.com\",\"content\":\"${address}\",\"ttl\":60,\"proxied\":false}"
else
     curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_Zone_ID}/dns_records/${RECORD_ID}" \
          -H "Authorization: Bearer ${CF_Token}" \
          -H "Content-Type:application/json" \
          --data "{\"type\":\"${ip_type}\",\"name\":\"${countrycode}.zippstorm.com\",\"content\":\"${address}\",\"ttl\":60,\"proxied\":false}"
fi
