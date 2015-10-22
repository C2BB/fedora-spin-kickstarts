appliance-creator -c fedora-arm-artik.ks -d -v --logfile /tmp/appliance.log \
	-o /root/output --format raw \
	--cache /root/cache \
	--vmem 4096 \
	--vcpu 16 \
	--name fedora-arm-artik --version 22 \
	--release fedora-arm-artik
