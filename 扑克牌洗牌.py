import random
poker = []
poker1 = []
poker1s = []
poker11s=[]
poker2 = []
poker2s = []
poker22s =[]
poker3 = []
poker3s = []
poker33s = []
for i in range(4):
    for j in range(2,15):
        if i == 0:
            if j<=10:
                poker.append("黑桃"+str(j))
            elif j == 11:
                poker.append("黑桃A")
            elif j == 12:
                poker.append("黑桃J")
            elif j == 13:
                poker.append("黑桃Q")
            elif j == 14:
                poker.append("黑桃K")
        if i == 1:
            if j <= 10:
                poker.append("红桃"+str(j))
            elif j == 11:
                poker.append("红桃A")
            elif j == 12:
                poker.append("红桃J")
            elif j == 13:
                poker.append("红桃Q")
            elif j == 14:
                poker.append("红桃K")
        if i == 2:
            if j <= 10:
                poker.append("梅花"+str(j))
            elif j == 11:
                poker.append("梅花A")
            elif j == 12:
                poker.append("梅花J")
            elif j == 13:
                poker.append("梅花Q")
            elif j == 14:
                poker.append("梅花K")
        if i == 3:
            if j <= 10:
                poker.append("方块"+str(j))
            elif j == 11:
                poker.append("方块A")
            elif j == 12:
                poker.append("方块J")
            elif j == 13:
                poker.append("方块Q")
            elif j == 14:
                poker.append("方块K")
poker.append("大王")
poker.append("小王")
random.shuffle(poker)
for i in range(0,len(poker)):
    if i<20:
        poker1.append(poker[i])
    elif i>=20 and i<37:
        poker2.append(poker[i])
    elif i>=37 and i<len(poker):
        poker3.append(poker[i])
print("庄家手牌：",poker1)
print("玩家1手牌：",poker2)
print("玩家2手牌：",poker3)
if(("大王" not in poker1)and("小王" not in poker1)):
    poker1s=sorted(poker1,key=lambda x:x[2])
    poker11s=sorted(poker1s,key=len)
elif ("大王" in poker1) and ("小王" not in poker1):
    poker1.remove("大王")
    poker1s = sorted(poker1, key=lambda x: x[2])
    poker11s = sorted(poker1s, key=len)
    poker11s.append("大王")
elif ("小王" in poker1) and ("大王" not in poker1):
    poker1.remove("小王")
    poker1s = sorted(poker1, key=lambda x: x[2])
    poker11s = sorted(poker1s, key=len)
    poker11s.append("小王")
elif ("小王" in poker1) and ("大王" in poker1):
    poker1.remove("大王")
    poker1.remove("小王")
    poker1s = sorted(poker1, key=lambda x: x[2])
    poker11s = sorted(poker1s, key=len)
    poker11s.append("小王")
    poker11s.append("大王")

if(("大王" not in poker2)and("小王" not in poker2)):
    poker2s=sorted(poker2,key=lambda x:x[2])
    poker22s=sorted(poker2s,key=len)
elif ("大王" in poker2) and ("小王" not in poker2):
    poker2.remove("大王")
    poker2s = sorted(poker2, key=lambda x: x[2])
    poker22s = sorted(poker2s, key=len)
    poker22s.append("大王")
elif ("小王" in poker2) and ("大王" not in poker2):
    poker2.remove("小王")
    poker2s = sorted(poker2, key=lambda x: x[2])
    poker22s = sorted(poker2s, key=len)
    poker22s.append("小王")
elif ("小王" in poker2) and ("大王" in poker2):
    poker2.remove("大王")
    poker2.remove("小王")
    poker2s = sorted(poker2, key=lambda x: x[2])
    poker22s = sorted(poker2s, key=len)
    poker22s.append("小王")
    poker22s.append("大王")

if(("大王" not in poker3)and("小王" not in poker3)):
    poker3s=sorted(poker3,key=lambda x:x[2])
    poker33s=sorted(poker3s,key=len)
elif ("大王" in poker3) and ("小王" not in poker3):
    poker3.remove("大王")
    poker3s = sorted(poker3, key=lambda x: x[2])
    poker33s = sorted(poker3s, key=len)
    poker33s.append("大王")
elif ("小王" in poker3) and ("大王" not in poker3):
    poker3.remove("小王")
    poker3s = sorted(poker3, key=lambda x: x[2])
    poker33s = sorted(poker3s, key=len)
    poker33s.append("小王")
elif ("小王" in poker3) and ("大王" in poker3):
    poker3.remove("大王")
    poker3.remove("小王")
    poker3s = sorted(poker3, key=lambda x: x[2])
    poker33s = sorted(poker3s, key=len)
    poker33s.append("小王")
    poker33s.append("大王")
print("理牌中…………")
print("………………………")
print("………………………")
print("庄家牌：",poker11s)
print("玩家1牌：",poker22s)
print("玩家2牌：",poker33s)

