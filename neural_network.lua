-- основа кода - python пример из книги ..

-- нужно прочитать, что делает следущий код и погонять на каких-то данных
function perceptronTraining(eta, x):
local w = {}
--for i in range(len(x[0])):
for k, v in pairs(#x[1]) do
    --w.append((random.randrange(-5, 5)) / 50.)
    table.insert(w, math.random(-5, 5) / 50)
end

local weightsChanged = true
while weightsChanged:
    weightsChanged = false
    --for xj in x:
    for xj in pairs(x) do
        --t, o, currx = xj[0], 0, [i] + xj[1:len(xj)]
        local t, o, currx = xj[1], 1, 
        --for i in xrange(len(w)):
            --o += w[i] * currx[i]
            --if o > 0:
                --o = 1
            --else:
                --o = -1
            --if (o == t): continue
            --weightsChanged = True
            --for i in xrange(len(w)):
                --w[i] += eta * (t - 0) * currx[i]
--return w
--[[
   [
   [def perceptronGradientDescent(eta0, x, NUMBER_OF_STEPS):
   ["""
   ["""
   [import random
   [eta, w, deltaw = eta0, [], []
   [for i in xrange(len(x[0])):
   [    w.append((random.randrange(-5, 5)) / 50.)
   [    deltaw.append(0)
   [for i in xrange(NUMBER_OF_STEPS):
   [    if ((NUMBER_OF_STEPS > 100) and (i % (NUMBER_OF_STEPS / 5)) == 0):
   [        eta = eta / 2.
   [    for i in xrange(len(w)):
   [        deltaw[i] = 0
   [    for xj in x:
   [        t, o, currx = xj[0], 0, [1] + xj[1:len(xj)]
   [        for i in xrange(len(w)):
   [            o += w[i] * currx[i]
   [        for i in xrange(len(w)):
   [            deltaw[i] += eta * (t - o) * currx[i]
   [    for i in xrange(len(w)):
   [        w[i] += deltaw[i]
   [return w
   [
   ['''
   [какие данные использовать для обучения?
   [как загружать данные из файла?
   [как визуализировать результаты обучения?
   [как подобрать структуру сети?
   ['''
   ]]
