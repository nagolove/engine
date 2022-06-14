set confirm off

add-symbol-file diamond_and_square.so 

#break diamond_and_square_reset
#commands
#set $mapSize=ctx->mapSize
##print (double[$mapSize][$mapSize])ctx->map
#eval "print (double[%d][%d])ctx->map", $mapSize, $mapSize
#end

set confirm on
