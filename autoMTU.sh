#!/bin/bash
IPV4=0
IPV6=1
MTU=$((1500-28))
[[ $IPV4$IPV6 = 01 ]] && ping6 -c1 -W1 -s $MTU -Mdo 2606:4700:d0::a29f:c001 >/dev/null 2>&1 || ping -c1 -W1 -s $MTU -Mdo 162.159.193.10 >/dev/null 2>&1
until [[ $? = 0 || $MTU -le $((1280+80-28)) ]]
do
MTU=$((MTU-10))
[[ $IPV4$IPV6 = 01 ]] && ping6 -c1 -W1 -s $MTU -Mdo 2606:4700:d0::a29f:c001 >/dev/null 2>&1 || ping -c1 -W1 -s $MTU -Mdo 162.159.193.10 >/dev/null 2>&1
done

if [[ $MTU -eq $((1500-28)) ]]; then MTU=$MTU
elif [[ $MTU -le $((1280+80-28)) ]]; then MTU=$((1280+80-28))
else
	for ((i=0; i<9; i++)); do
	(( MTU++ ))
	( [[ $IPV4$IPV6 = 01 ]] && ping6 -c1 -W1 -s $MTU -Mdo 2606:4700:d0::a29f:c001 >/dev/null 2>&1 || ping -c1 -W1 -s $MTU -Mdo 162.159.193.10 >/dev/null 2>&1 ) || break
	done
	(( MTU-- ))
fi

MTU=$((MTU+28-80))

[[ -e /etc/wireguard/wgcf.conf ]] && sed -i "s/MTU.*/MTU = $MTU/g" /etc/wireguard/wgcf.conf

echo $MTU
