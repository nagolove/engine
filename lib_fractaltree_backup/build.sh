#gcc  -o a.out ./main.cpp -I/usr/include/SDL2 -D_REENTRANT -pthread -lSDL2 
#g++ -std=c++17 -o a.out ./main.cpp -I/usr/include/SDL2 -D_REENTRANT -pthread -lSDL2 
g++ -shared -Wall -o fractaltree.so ./fractaltree.cpp 
