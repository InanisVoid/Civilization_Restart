module Monster.Boss exposing (bossGenerator,updateBoss)

import Shape exposing (Rectangle,recCollisionTest,recInit,recUpdate,circleCollisonTest,circleRecTest,Circle )
import Map.Map exposing (Boss,BossType,Obstacle,Boss,BossType,ShootingType,AttackMode(..))
import Model exposing (..)
import Config exposing (bulletSpeed)
import Weapon exposing(Bullet,ShooterType(..))
import Random exposing (..)
import Time exposing (now,posixToMillis)



bossTypeList : List BossType 
bossTypeList = 
    let
        m1=bossType1
        m2=bossType2
        
    in 
        [m1,m2,m1,m2]



bossGenerator : Random.Seed ->List Obstacle -> Int ->  List Boss
bossGenerator seed0 obstacle storey=
    let
        
        -- obstacle = room.obstacles
        
        bossList= bossBuilding [] obstacle (modBy 2 storey ) seed0
    in
        bossList






bossBuilding : List Boss -> List Obstacle -> Int -> Random.Seed -> List Boss
bossBuilding bossList obstacles bossNum  seed0=
    let
        xTemp = 1000
        yTemp =   1000
        
        bossTypeTemp = 
            let
                headType =List.head <| List.drop bossNum bossTypeList 
            in 
                case headType of 
                    Just a ->
                        a
                    Nothing ->
                        BossType 500 0 0 0 "black" [] 
        bossPos =  Rectangle (toFloat xTemp) (toFloat yTemp) bossTypeTemp.width bossTypeTemp.height recInit

        bossNew = Map.Map.Boss (recUpdate bossPos) 0  bossTypeTemp  seed0 False 0 0

    in 
        
            
         [bossNew]

bossType1 : BossType
bossType1 = 
    let
        stype1 = [shootingType1]
    in
        BossType 500 1 200 200 "red" stype1 

bossType2 : BossType
bossType2 = 
    let
        stype2 = [shootingType2]
    in
        BossType 500 1 200 200 "blue" stype2 

shootingType1 : ShootingType
shootingType1 = 
    ShootingType Circled 10 0 30 10 5 10    

shootingType2 : ShootingType
shootingType2 = 
    ShootingType Targeted 5 20 30 5 5 10 

 
                

updateBoss_ : Boss -> List Bullet -> Boss
updateBoss_ boss bullets =
    let
        hitBullets = bullets
                  |> List.filter (\b -> b.from == Weapon.Player)
                  |> List.filter (\b -> circleRecTest  b.hitbox boss.position.edge)
        bossType_ = boss.bossType
        newBossType = {bossType_ | hp = bossType_.hp - List.sum (List.map (\b -> b.force) hitBullets)}
        {- debug test
        newBossType =
                if List.isEmpty hitBullets then
                    bossType_
                else
                    Debug.log "hitBoss" {bossType_ | hp = bossType_.hp - toFloat(20 * (List.length hitBullets)), color = "Green"}
        -}
    in
        {boss | bossType = newBossType}

updateBoss : List Boss -> List Bullet -> Me -> (List Boss,List Bullet)
updateBoss boss bullets me =
    let
        finalBoss = boss
                     |> List.filter (\m -> m.bossType.hp > 0)
                     |> List.map (\m -> updateBoss_ m bullets)
    in
         allBossAct finalBoss me bullets

allBossAct:  List Boss -> Me  -> List Bullet -> (List Boss,List Bullet)
allBossAct bossList me bulletList = 
    let 
        
        newBossList = List.map  (bossAct me) bossList

        newBulletList = bossShoot newBossList me bulletList

    in
        (newBossList,newBulletList)


bossAct :  Me -> Boss ->  Boss
bossAct  me boss = 
    let 
        
        
        distx = abs (me.x - boss.position.edge.cx)
        disty = abs (me.y - boss.position.edge.cy)

        

        checkActive = 
            (distx <= 500) || (disty<=500)

        firstShootingType = List.head boss.bossType.shootingType

        nowShootingType = 
            case firstShootingType of 
                    Just a ->
                        a
                    Nothing ->
                        shootingType1

                

        checkCanShoot =
            let 
                count = boss.timeBeforeAttack
            in  
                if boss.active then 
                    if count ==0 
                        then nowShootingType.bulletInterval  
                        else  count-1  
                else count


        
        
    in 
         {boss|active=checkActive,timeBeforeAttack=checkCanShoot} 

bossShoot : List Boss -> Me -> List Bullet -> List Bullet
bossShoot bossList me bulletList = 
 

        bulletList ++ List.concat (List.map (newBullet me) bossList)

newBullet : Me ->  Boss ->List Bullet
newBullet me boss = 
            let
                
                firstShootingType = List.head boss.bossType.shootingType

                nowShootingType = 
                    case firstShootingType of 
                        Just a ->
                            a
                        Nothing ->
                            shootingType1
                

            in
                if (boss.timeBeforeAttack==0) && (boss.active) then 
                    case nowShootingType.attackMode of
                        Circled ->
                            circledShoot boss nowShootingType.bulletNum nowShootingType [] 
                        Targeted ->
                            targetedShoot boss nowShootingType.bulletNum nowShootingType [] boss.seed me
                    
                    
                    else []

circledShoot : Boss -> Int -> ShootingType ->List Bullet -> List Bullet
circledShoot boss num shootingType bullitList =
    let
        angle = (360 / toFloat  shootingType.bulletNum) * (toFloat num)

        speedx= cos (degrees angle) * shootingType.speed
        speedy= sin (degrees angle)* shootingType.speed
        
        oneNewBullet : Bullet
        oneNewBullet = Bullet boss.position.edge.cx  boss.position.edge.cy shootingType.r (Circle boss.position.edge.cx boss.position.edge.cy 5) speedx speedy False Weapon.Monster shootingType.attack

    in
        if num==0 then bullitList
            else circledShoot boss (num - 1) shootingType (oneNewBullet :: bullitList )

targetedShoot : Boss -> Int -> ShootingType ->List Bullet -> Random.Seed -> Me ->List Bullet
targetedShoot boss num shootingType bullitList seed me=
    let
        

        distx =  me.x - boss.position.edge.cx
        disty =  me.y - boss.position.edge.cy

        dist = sqrt ((distx)^2 + (disty)^2)

        numtodirx  = 
            (cos (degrees directiondiff))
        numtodiry  = 
            (sin (degrees directiondiff))  

        

        (directiondiff,seed1) =  Random.step (Random.float -shootingType.direction shootingType.direction) seed

        disriedSpeedx= 
             (distx / dist)
        disriedSpeedy= 
            (disty / dist)

        speedx = disriedSpeedx * numtodirx - numtodiry * disriedSpeedy

        speedy = disriedSpeedx * numtodiry + numtodirx * disriedSpeedy
        
        oneNewBullet : Bullet
        oneNewBullet = Bullet boss.position.edge.cx  boss.position.edge.cy shootingType.r (Circle boss.position.edge.cx boss.position.edge.cy 5) (10*(speedx )) (10*(speedy )) False Weapon.Monster shootingType.attack

    in
        if num==0 then bullitList
            else targetedShoot boss (num - 1) shootingType (oneNewBullet :: bullitList ) seed1 me