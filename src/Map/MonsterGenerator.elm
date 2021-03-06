
module Map.MonsterGenerator exposing (monsterGenerator,updateMonster,updateRoomList)
import Shape exposing (Rectangle,recCollisionTest,recInit,recUpdate,circleCollisonTest)
import Map.Map exposing (Monster,MonsterType,Obstacle,Boss)
import Random
import Weapon exposing(Bullet,ShooterType(..))
import Model exposing (Me)
import Attributes exposing (getCurrentAttr,getMaxAttr,AttrType(..),defaultAttr)
import Monster.Monster exposing (allMonsterAct)
import Skill exposing (getSubSys, getSkill)
import Bomb exposing (Bombs,bombToHitbox)
-- import Map.Map exposing (Obstacle)
-- import Shape exposing (recInit)



monsterTypeNum : Int 
monsterTypeNum = 3

monsterTypeList : List MonsterType 
monsterTypeList = 
    let

        m1=MonsterType 30 30 20 "#Robot1"
        m2=MonsterType 60 60  20 "#Robot1"
        m7=MonsterType 200 200 20 "#Robot1"
        m3=MonsterType 300 300 40 "#Robot2"
        m4=MonsterType 600 600 40 "#Robot2"
        m5=MonsterType 1000 1000 60 "#Robot3"
        m6=MonsterType 2000 2000 60 "#Robot3"

    in 
        [m1,m2,m7,m3,m4,m5,m6,m6,m6,m6,m5]



monsterGenerator : Random.Seed -> List Obstacle -> Int ->(List Monster,Random.Seed)
monsterGenerator seed0 obstacle storey=
    let
        (number,seed1) = Random.step (Random.int (storey //3 +7) (storey // 3  + 9)) seed0
        -- obstacle = room.obstacles
        
        (monsterList,seed2) = monsterBuilding [] number obstacle seed1 storey
    in
        (monsterList,seed2)


checkMonsterCollison : Monster -> List Obstacle -> List Monster -> Bool
checkMonsterCollison monster obstacles monsterList=
    let
        monsterRegion=monster.region
        obstaclePosList = List.map (\value -> value.position) obstacles
        monsterRegList = List.map (\value->value.region) monsterList
        obstacleCol=List.filter (recCollisionTest monsterRegion.edge) <| List.map (\value->value.edge) (obstaclePosList++monsterRegList)
    in
        List.isEmpty obstacleCol



monsterBuilding : List Monster -> Int -> List Obstacle -> Random.Seed -> Int -> (List Monster,Random.Seed)
monsterBuilding monsterList number obstacles seed0 storey=
    let
        (xTemp,seed1) = Random.step (Random.int 300 1500) seed0
        (yTemp,seed2) = Random.step (Random.int 300 1500) seed1
        (typeTemp, seed3) =Random.step (Random.int 0 storey) seed2
        (monsterSpeed, seed4) = Random.step (Random.float 1 3 ) seed3
        getMonsterType = 
            let
                headType =List.head <| List.drop typeTemp monsterTypeList 
            in 
                case headType of 
                    Just a ->
                        a
                    Nothing ->
                        MonsterType 0 0 0 ""

        monsterTypeTemp = getMonsterType

        monsterRegion = Rectangle (toFloat xTemp) (toFloat yTemp) 150 150 recInit
        monsterPos = Shape.Circle  (toFloat xTemp + 75) (toFloat yTemp + 75) 20 

        monsterNew = Map.Map.Monster monsterPos (recUpdate monsterRegion)  monsterTypeTemp 0 seed3 False 1 monsterSpeed 0 False

    in 
        if number==0 then
            (monsterList,seed3)
        else
            if checkMonsterCollison monsterNew obstacles monsterList then
                monsterBuilding (monsterNew :: monsterList) (number - 1) obstacles seed3 storey
            else 
                monsterBuilding  monsterList number obstacles seed4 storey

updateMonster_ : Monster -> List Bullet -> Bombs -> Me -> Monster
updateMonster_ monster bullets bombs me =
    let
        hitBullets = bullets
                  |> List.filter (\b -> b.from == Player)
                  |> List.filter (\b -> circleCollisonTest b.hitbox monster.position)
        hitBombs = bombs
                |> List.map bombToHitbox
                |> List.filter (\b -> circleCollisonTest b monster.position)
        monsterType_ = monster.monsterType
        -- Skill Battle Fervor can influence the attack
        sub = getSubSys me.skillSys 2
        skill = getSkill sub (0,4)
        battleFervorFactor = 
            if skill.unlocked then
            let
                maxHealth = getMaxAttr Health me.attr
                currentHealth = getCurrentAttr Health me.attr
                loseHealthRate = 1 - toFloat currentHealth / toFloat maxHealth
            in
                1 + loseHealthRate / 2
            else
                1
        -- Skill Explosion is Art will influence the attack of bombs
        subMechanic = getSubSys me.skillSys 1
        skillExplode = getSkill subMechanic (1,4)
        explodeFactor = if skillExplode.unlocked then 800 else 200
        bulletHurt = List.sum (List.map (\b -> b.force) hitBullets)
        bombHurt = (Basics.toFloat <| List.length hitBombs) * explodeFactor
        attackFactor = (getCurrentAttr Attack me.attr |> toFloat) / (getCurrentAttr Attack defaultAttr |> toFloat) * battleFervorFactor
        damage = attackFactor * (bulletHurt + bombHurt)
        newMonsterType = {monsterType_ | hp = monsterType_.hp - damage}
        {- debug test
        newMonsterType =
                if List.isEmpty hitBullets then
                    monsterType_
                else
                    Debug.log "hitMonster" {monsterType_ | hp = monsterType_.hp - toFloat(20 * (List.length hitBullets)), color = "Green"}
        -}
    in
        {monster | monsterType = newMonsterType}

updateMonster : List Monster -> List Bullet -> Bombs -> Me -> (List Monster,List Bullet)
updateMonster monsters bullets bombs me =
    let
        finalMonsters = monsters
                     |> List.filter (\m -> m.monsterType.hp > 0)
                     |> List.map (\m -> updateMonster_ m bullets bombs me)
    in
        allMonsterAct finalMonsters me bullets

updateRoomList : List Monster -> Int  -> List Int -> List Boss -> List Int 
updateRoomList monsterList number nowRoomList boss = 
    
    if number <= 0 then nowRoomList 
        else if checkClearRoom number monsterList boss then number :: (updateRoomList  monsterList (number - 1)  nowRoomList boss )
            else updateRoomList monsterList (number - 1) nowRoomList boss


checkClearRoom : Int -> List Monster -> List Boss -> Bool
checkClearRoom roomNumber monsterList boss=
    let
        monsterInRoom = List.filter (\b -> b.roomNum == roomNumber) monsterList

        bossInRoom = List.filter (\b -> b.roomNum == roomNumber) boss

        
    in
        ((List.length monsterInRoom) == 0)&&((List.length bossInRoom) == 0)