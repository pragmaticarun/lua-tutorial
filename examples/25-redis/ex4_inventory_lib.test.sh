# host: redis
R="redis-cli -p ${REDIS_PORT:-6379} --no-raw"
$R -x FUNCTION LOAD REPLACE < ex4_inventory_lib.lua
$R SET stock:{sku1} 5
$R FCALL inv_reserve 1 stock:{sku1} 2
$R FCALL inv_reserve 1 stock:{sku1} 4
$R FCALL inv_reserve 1 stock:{sku1} -1
$R FCALL_RO inv_available 1 stock:{sku1}
$R FCALL_RO inv_reserve 1 stock:{sku1} 1
