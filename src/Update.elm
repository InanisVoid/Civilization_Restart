module Update exposing (update)
import Messages exposing (Msg(..))
import Model exposing (Model,Me,State(..),Direction(..),Dialogues, Sentence, AnimationState,defaultMe,mapToViewBox,GameState(..),sentenceInit,Side(..))
import Shape exposing (Rec,Rectangle,Circle,CollideDirection(..),recCollisionTest,recUpdate,recInit, recCollisionTest,circleRecTest,circleCollisonTest)
import Map.Map exposing (Map,mapConfig,Treasure,treasureInit)
import Config exposing (playerSpeed,viewBoxMax,bulletSpeed)
import Weapon exposing (Bullet,bulletConfig,ShooterType(..),defaultWeapon,Weapon,generateBullet,Arsenal(..))
import Debug
import UpdateSkill exposing (updateSkill)
-- import Svg.Attributes exposing (viewBox)
-- import Html.Attributes exposing (value)
import Map.MapGenerator exposing (roomGenerator,roomInit)
import Map.MapDisplay exposing (showMap, mapWithGate,mapInit)
import Map.MonsterGenerator exposing (updateMonster,updateRoomList)
import Map.TreasureGenerator exposing (updateTreasure)
import Animation.PlayerMoving exposing (playerMove)
import Control.ExplosionControl exposing (updateExplosion,explosionToViewbox)
import Synthesis.UpdateSynthesis exposing (updateSynthesis)
import Synthesis.Package exposing (packageUpdate)
import Attributes exposing (setCurrentAttr,getCurrentAttr, AttrType(..),defaultAttr)
import Skill exposing (subSysBerserker,skillDualWield)
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Start ->
            let
                init =
                    { myself = defaultMe
                    , bullet = []
                    , bulletViewbox = []
                    , map = mapInit
                    , rooms = roomInit
                    , viewbox = mapToViewBox defaultMe mapInit
                    , size = (0, 0)
                    , state = Others
                    , currentDialogues = [{sentenceInit | text = "hello", side = Left}, {sentenceInit | text = "bad", side = Right}, {sentenceInit | text = "badddddd", side = Left}, {sentenceInit | text = "good", side = Right}]
                    , explosion = []
                    , explosionViewbox = []
                    , paused = False
                    , gameState = Playing
                    , storey = 1
                    }
            in
                (init, Cmd.none)
        Pause ->
            ( {model|gameState=Paused}, Cmd.none)
        Resume ->
            ( {model|gameState=Playing}, Cmd.none)
        ChangeGameState ->
            let
                newModel =
                    case model.gameState of
                        Playing -> {model|gameState=Paused}
                        Paused -> {model|gameState=Playing}
                        Stopped -> {model|gameState=Playing}
            in
                (newModel, Cmd.none)
        MoveLeft on ->
            let 
                pTemp = model.myself 
                me= {pTemp | moveLeft = on, moveRight =  False, preDirection=DirectionLeft}
            in
                ( {model| myself= me}
                , Cmd.none
                )

        MoveRight on ->
            let 
                pTemp =  model.myself
                me= {pTemp | moveRight = on, moveLeft = False, preDirection=DirectionRight}
            in
                ( {model| myself= me}
                , Cmd.none
                )

        MoveUp on ->
            let
                pTemp =  model.myself 
                me= {pTemp | moveUp = on, moveDown =  False}
            in
                ( {model| myself= me}
                , Cmd.none
                )

        MoveDown on ->
            let 
                pTemp =  model.myself
                me= {pTemp | moveDown = on, moveUp = False}
            in
                ( {model| myself= me}
                , Cmd.none
                )
        
        -- Map ->
        --  ({model | map = not model.map},Cmd.none)
        
        MouseMove newMouseData ->
            let 
                pTemp = model.myself 
                -- d2 = Debug.log "mePos" (pTemp.x,pTemp.y)
                -- d = Debug.log "mouse" newMouseData 
                me = {pTemp | mouseData = mouseDataUpdate model newMouseData}
                getDirection = 
                    if (Tuple.first me.mouseData)>=500 then
                        DirectionRight
                    else 
                        DirectionLeft
            in 
                ({model|myself = {me|weaponDirection=getDirection}},Cmd.none)
        
        MouseDown ->
            let
                pTemp = model.myself
                me = {pTemp | fire = True}
                {-
                newShoot = fireBullet model.myself.currentWeapon me.mouseData (me.x,me.y)
                newBullet = newShoot ++ model.bullet
                -}
                -- newBulletViewbox = List.map (\value -> {value| x=500,y=500}) newBullet
            in
                ({model|myself = me},Cmd.none)
        
        MouseUp ->
            let
                pTemp =  model.myself
                weapon=pTemp.currentWeapon
                me= {pTemp|fire=False,currentWeapon={weapon|hasFired=False}}
            in
                ({model|myself = me},Cmd.none) 
        FMsg ->  -- FMsg
            if model.gameState == Playing then
                if model.state == NextStage then
                    let
                        roomNew =
                            roomGenerator (model.storey+1) (Tuple.second model.rooms) 

                        mapNew = mapWithGate (Tuple.first roomNew) (List.length (Tuple.first roomNew)) mapConfig (Tuple.second model.rooms)
                        meTemp = model.myself
                        meNew = {defaultMe|weapons=meTemp.weapons,currentWeapon=meTemp.currentWeapon,package=meTemp.package}
                        -- it should be updated when dialogues are saved in every room
                        newDialogues = updateDialogues model
                    in
                        ({model|myself=meNew,rooms=roomNew,map=mapNew,viewbox=mapNew,state=Dialogue,currentDialogues=newDialogues,gameState=Paused,storey=model.storey+1},Cmd.none)
                else 
                    case model.state of
                        PickTreasure t ->
                            let
                                meTemp = model.myself
                                package = meTemp.package
                                newPackage = packageUpdate package t
                                newTreasureList = List.filter (\value->value/=t) model.map.treasure
                                mapTemp = model.map
                                mapNew = {mapTemp|treasure=newTreasureList}
                            in
                                ({model|myself={meTemp|package=newPackage},map=mapNew},Cmd.none)
                        _ ->
                            (model, Cmd.none)
            else
                (model, Cmd.none)
        Tick time ->
            if model.paused then
                (model, Cmd.none)
            else
                (animate model, Cmd.none)

        NextSentence ->
            (updateSentence 0 model, Cmd.none)

        -- the dialogue should be displayed when the player enters a new room actually
        ShowDialogue ->
            ({ model | state = Dialogue, gameState = Paused}, Cmd.none)

        ChangeWeapon number ->
            if model.gameState == Playing then
                (changeWeapon (number - 1) model, Cmd.none)
            else
                (model, Cmd.none)

        ChangeWeapon_ ->
            if model.gameState == Playing then
                (changeWeapon (modBy 4 model.myself.currentWeapon.number) model, Cmd.none)
            else
                (model, Cmd.none)

        Resize width height ->
            ( { model | size = ( toFloat width, toFloat height ) }
            , Cmd.none
            )

        GetViewport { viewport } ->
            ( { model
                | size =
                    ( viewport.width
                    , viewport.height
                    )
              }
            , Cmd.none
            )
        
        SkillChange skillMsg ->
            updateSkill skillMsg model
        
        SynthesisSystem systhesisMsg ->
            updateSynthesis systhesisMsg model

        DualWield ->
            (updateDualWield model, Cmd.none)

        Noop ->
            let 
                pTemp =  model.myself
                me= {pTemp | moveDown = False, moveUp = False, moveRight =False, moveLeft=False}
            in
                ( {model| myself= me}
                , Cmd.none
                )

changeWeapon : Int -> Model -> Model
changeWeapon number model =
    let
        weapon = List.head (List.drop number model.myself.weapons)
        newWeapon =
            case weapon of
                Just a ->
                    a
                Nothing ->
                    defaultWeapon
        pTemp = model.myself
        me = { pTemp | currentWeapon = newWeapon}
    in
        {model | myself = me}

mouseDataUpdate : Model -> (Float,Float) -> (Float,Float)  
mouseDataUpdate model mousedata = 
    let
        ( w, h ) =
            model.size
        
        configheight =1000
        configwidth = 1000
        r =
            if w / h > 1 then
                Basics.min 1 (h / configwidth)

            else
                Basics.min 1 (w / configheight)
        -- d1=Debug.log "r" r 

        xLeft = (w - configwidth*r) / 2 
        yTop = (h - configheight*r) / 2

        (mx,my) = 
            mousedata 

    in
        ((mx - xLeft)/r, (my - yTop)/r)


fireBullet_ : Weapon -> (Float, Float) -> (Float, Float) -> Bool -> (List Bullet, Weapon)
fireBullet_ weapon (mouseX,mouseY) (meX, meY) dual=
    let
        bullet = fireBullet weapon (mouseX,mouseY) (meX, meY) dual
        (newShoot, fireFlag, counter) =
            if weapon.counter <= 0 then
                if weapon.auto then
                    (bullet, False, weapon.period)
                else if weapon.hasFired then
                    ([], True, 0)
                else
                    (bullet, True, weapon.period)
            else
                ([], weapon.hasFired, weapon.counter)
    in
        (newShoot, {weapon|hasFired=fireFlag,counter=counter})

animate :  Model -> Model
animate  model =
    -- (model,Cmd.none)
    let
        me = model.myself
        attr = me.attr
        (newMe_,collision) = speedCase me model.map
        (newShoot, weapon) = if model.myself.fire then
                                 if getCurrentAttr Clip attr > 0 then
                                    fireBullet_ model.myself.currentWeapon me.mouseData (me.x,me.y) model.myself.dualWield
                                 else
                                    ([], model.myself.currentWeapon)
                             else
                                ([], model.myself.currentWeapon)
        newAttr = setCurrentAttr Clip -(List.length newShoot) attr
        number = Debug.log "number" (getCurrentAttr Clip newAttr)
        newMe = {newMe_|attr=newAttr}
        -- This is for the cooling time of weapons
        weaponCounter =
            if weapon.counter <= 0 then
                0
            else
                weapon.counter - 1
        newWeapons = List.map (\w -> {w | period = (getCurrentAttr ShootSpeed defaultAttr |> toFloat) / (getCurrentAttr ShootSpeed newAttr |> toFloat) * w.maxPeriod}) newMe.weapons
        newPeriod = Debug.log "newPeriod" ((getCurrentAttr ShootSpeed defaultAttr |> toFloat) / (getCurrentAttr ShootSpeed newAttr |> toFloat) * newMe.currentWeapon.maxPeriod)
        newBullet_ =  newShoot ++ model.bullet
        (newMonsters,newBullet) = updateMonster model.map.monsters newBullet_ me
        newClearList = updateRoomList model.map.monsters model.map.roomCount []
        newTreasure = updateTreasure model.map.treasure newClearList
        map = model.map
        newMap = {map | monsters = newMonsters,treasure=newTreasure}
        newViewbox = mapToViewBox newMe newMap
        (newBulletList, filteredBulletList, hurtPlayer) = updateBullet newMe model.map newBullet collision
        newBulletListViewbox = bulletToViewBox newMe newBulletList
        newExplosion = updateExplosion model.explosion filteredBulletList
        newExplosionViewbox = explosionToViewbox newMe newExplosion
        newState = updateState model
        meHit = hit hurtPlayer newMe
        dual = Debug.log "dual" model.myself.dualWield
    in
        {model| myself = {meHit|weapons=newWeapons,counter=newMe.counter+1,url=playerMove newMe,currentWeapon={weapon|counter=weaponCounter,period=newPeriod}},
                viewbox=newViewbox, map = newMap, bullet= newBulletList,bulletViewbox=newBulletListViewbox,state = newState,
                explosion=newExplosion,explosionViewbox=newExplosionViewbox}



speedCase : Me -> Map-> (Me,(Bool,Bool))
speedCase me map= 
    let 
        speedFactor = (getCurrentAttr Speed me.attr |> toFloat) / (getCurrentAttr Speed defaultAttr |> toFloat)
        speed = speedFactor * playerSpeed
        getNewXSpeed =
            if me.moveLeft then 
                (True,-speed)
            else
                if me.moveRight then
                  (True,speed)
                else
                    (False,0)
        
        (horizontal,newXspeed)=getNewXSpeed
        
        getNewYSpeed =  
            if me.moveUp then 
                (True,-speed)
            else
                if me.moveDown then
                  (True,speed)
                else
                    (False,0)

        (vertical,newYspeed)=getNewYSpeed

        getSpeed = 
            case (horizontal,vertical) of
                (True,True) ->
                    (newXspeed/1.414,newYspeed/1.414)
                _ ->
                    (newXspeed,newYspeed)
        (xSpeedFinalTemp,ySpeedFinalTemp) = getSpeed
        
        (newXTemp,newYTemp) = (me.x+xSpeedFinalTemp,me.y+ySpeedFinalTemp) --Todo
        -- -- recTemp = Rec newX newY (viewBoxMax/2) (viewBoxMax/2)

        collideType = wallCollisionTest (Circle newXTemp newYTemp 50) (map.obstacles++(List.map (\value->value.position) map.walls)++map.roads) 
        -- d = Debug.log "Type" collideType
        -- d = Debug.log "x"
        getCollideType collideList  = 
            case List.head collideList of 
                Just a ->
                    a
                _ ->
                    NoCollide 0
        (typeA,typeB) = (getCollideType collideType, getCollideType<|List.drop 1 collideType)

        getXY = -- TO DO Road 2墙重合有 bug
            case (typeA,typeB) of
                (FromRight a,NoCollide b) ->
                    ((newXTemp-a,newYTemp),(ySpeedFinalTemp-a,ySpeedFinalTemp),(True,False))
                (FromLeft a,NoCollide b) ->
                    ((newXTemp-a,newYTemp),(ySpeedFinalTemp-a,ySpeedFinalTemp),(True,False))
                (FromUp a,NoCollide b) ->
                    ((newXTemp,newYTemp-a),(xSpeedFinalTemp,ySpeedFinalTemp-a),(False,True))
                (FromDown a,NoCollide b) ->
                    ((newXTemp,newYTemp-a),(xSpeedFinalTemp,ySpeedFinalTemp-a),(False,True))
                
                (FromLeft a, FromUp b) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                (FromLeft a, FromDown b) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                (FromRight a, FromUp b) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                (FromRight a, FromDown b) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                
                (FromUp b, FromLeft a) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                (FromUp b, FromRight a) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                (FromDown b, FromLeft a) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))
                (FromDown b, FromRight a) ->
                    ((newXTemp-a,newYTemp-b),(xSpeedFinalTemp-a,ySpeedFinalTemp-b),(True,True))

                (NoCollide a,NoCollide b) ->
                    ((newXTemp,newYTemp),(xSpeedFinalTemp,ySpeedFinalTemp),(False,False))
                _ ->
                    ((me.x,me.y),(0,0),(False,False))
        
        ((newX,newY),(xSpeedFinal,ySpeedFinal),(collisionX,collisionY)) = getXY
        
    in
        ({me|xSpeed=xSpeedFinal,ySpeed=ySpeedFinal,x=newX,y=newY,hitBox=(Circle newX newY 50)},(collisionX,collisionY))

wallCollisionTest : Circle -> List Rectangle -> List CollideDirection
wallCollisionTest hitbox wallList =
    let
        collide model =
            (Shape.circleRecDirection hitbox model) /= Shape.NoCollide 0
        wallColList=List.filter collide <| List.map (\value->value.edge) wallList
        wallColType = List.map (\value-> Shape.circleRecDirection hitbox value )wallColList
        -- d1=Debug.log "hitbox" hitbox
        -- d2=Debug.log "Col List" wallColList
    in
        -- List.isEmpty wallColList
        listUniq (List.length wallColType) wallColType [] 

listUniq : Int -> List CollideDirection -> List CollideDirection -> List CollideDirection
listUniq num orignial now=
    let
        getHead = 
            case List.head orignial of 
                Just a ->
                    a
                _ ->
                    NoCollide 0
        newOriginal = List.drop 1 orignial
        newNow = 
            if List.member getHead now then
                now
            else 
                now ++ [getHead]

    in 
        if num==0 then
            now
        else
            listUniq (num - 1) newOriginal newNow


activateUpdate : Float -> Float -> { a | active : Bool, elapsed : Float } -> { a | active : Bool, elapsed : Float }
activateUpdate interval elapsed state =
    let
        elapsed_ = state.elapsed + elapsed
    in
        if elapsed_ > interval then
            {state | active = True, elapsed = elapsed_ - interval}
        else
            {state | elapsed = elapsed_}

{-
startUpdateSen : Model -> Model
startUpdateSen model =
    if model.changeSentence then
        { model | sentenceState = Just {active = True, elapsed = 0}}
    else
        { model | sentenceState = Nothing}
-}

updateSentence : Float -> Model -> Model
updateSentence elapsed model =
    case model.state of
        Dialogue ->
            let
                head = List.head model.currentDialogues
                end =
                    case head of
                        Just a ->
                            False
                        Nothing ->
                            True
                (state, newDialogues, gameState) =
                    if end then
                        (Others, model.currentDialogues, Playing)
                    else
                        (Dialogue, List.drop 1 model.currentDialogues, Paused)
            in
                {model | state = state, currentDialogues = newDialogues, gameState = gameState}
        _ ->
            model

fireBullet : Weapon -> (Float, Float) -> (Float, Float) -> Bool -> List Bullet
fireBullet weapon (mouseX,mouseY) (meX, meY) dual =
    let
        posX = mouseX
        posY = mouseY

        -- d1=Debug.log "mouse" (posX,posY)
        -- d2=Debug.log "me" (meX,meY)
        unitV = sqrt ((posX - 500) * (posX - 500) + (posY - 520) * (posY - 520))
        -- velocity decomposition

        xTemp = bulletSpeed / unitV * (posX - 500)
        yTemp = bulletSpeed / unitV * (posY - 520)
        bullet = generateBullet weapon
        newCircle = Circle meX (meY+20) bullet.r
        newBullet = {bullet | x=meX,y=(meY+20),hitbox = newCircle, speedX=xTemp, speedY=yTemp}
        bulletList_ =
            case weapon.extraInfo of
                Shotgun ->
                    -- the shotgun will shoot three bullets at one time and has an angle of 30 degrees
                    let
                        bullet1 = {newBullet|speedX=(sqrt 3)/2*xTemp+0.5*yTemp,speedY=(sqrt 3)/2*yTemp-0.5*xTemp}
                        bullet2 = {newBullet|speedX=(sqrt 3)/2*xTemp-0.5*yTemp,speedY=(sqrt 3)/2*yTemp+0.5*xTemp}
                    in
                    [newBullet, bullet1, bullet2]
                _ ->
                    [newBullet]
        bulletList =
            if dual then
                let
                    b1 = bulletList_ |> List.map (\b -> {b|y=b.y + 100})
                    b2 = bulletList_ |> List.map (\b -> {b|y=b.y - 100})
                in
                    List.append b1 b2
            else
                bulletList_
    in
        bulletList



updateBullet : Me-> Map -> List Bullet -> (Bool,Bool) -> (List Bullet, List Bullet, List Bullet)
updateBullet me map bullets (collisionX,collisionY) =
    let
        updateXY b =
            let
                -- d2=Debug.log "meX" me.xSpeed
                newX = 
                    if (b.from == Player) &&  not collisionX then 
                        b.hitbox.cx + b.speedX + me.xSpeed
                    else 
                        b.hitbox.cx + b.speedX
                newY = 
                    if (b.from == Player) &&  not collisionY then
                        b.hitbox.cy + b.speedY + me.ySpeed
                    else 
                        b.hitbox.cy + b.speedY
                newHitbox = Circle newX newY b.hitbox.r
            in
                {b|hitbox = newHitbox,x=newX, y=newY}

        allBullets = bullets
                    -- hit wall
                    |> List.filter (\b -> not (List.any (circleRecTest b.hitbox) (List.map .edge (List.map (\value->value.position) map.walls))))
                    -- hit obstacles
                    |> List.filter (\b -> not (List.any (circleRecTest b.hitbox) (List.map .edge map.obstacles)))
                    -- hit doors
                    |> List.filter (\b -> not (List.any (circleRecTest b.hitbox) (List.map .edge map.doors)))
                    -- on the roads
                    |> List.filter (\b -> not (List.any (circleRecTest b.hitbox) (List.map .edge map.roads)))
                    -- hit monsters and are shoot by player
                    |> List.filter (\b -> not (List.any (circleCollisonTest b.hitbox) (List.map .position map.monsters))||(b.from == Monster))
        (flyingBullets, hitPlayer) = List.partition (\b -> (b.from == Player) || not (circleCollisonTest b.hitbox me.hitBox)) allBullets
        finalBullets = List.map updateXY flyingBullets

        filteredBullets= List.filter (\b-> b.from == Player) <| List.filter (\value -> not (List.member value allBullets)) bullets
        
        -- d1=Debug.log "f" filteredBullets  

    in
        (finalBullets,filteredBullets,hitPlayer)


bulletToViewBox : Me -> List Bullet -> List Bullet
bulletToViewBox me bullets=
    List.map (\value->{ value | x=viewBoxMax/2+value.x-me.x,y=viewBoxMax/2 +value.y-me.y}) bullets


updateState : Model -> State
updateState model =
    let
        collideGate = circleRecTest model.myself.hitBox model.map.gate.edge
        collideTreasureList = getCollideTreasure model.map.treasure model.myself
        getTreasure = 
            let 
                temp = List.head collideTreasureList
            in
                case temp of
                    Just a ->
                        a
                    Nothing ->
                        treasureInit 
        -- collideTreasure =/
        newState =
            if collideGate then
                NextStage
            else if  not (List.isEmpty collideTreasureList) then
                PickTreasure getTreasure
            else if model.state == Dialogue then
                Dialogue 
            else
                Others
    in
        newState


getCollideTreasure : List Treasure-> Me -> List Treasure
getCollideTreasure treasureList me= 
    let
        -- d1 =Debug.log "treasure" (List.map (\value -> value.material) treasureList)
        treasureRec = List.map (\value -> value.position ) treasureList
        treasure =List.filter (\value -> (circleRecTest me.hitBox value.position.edge) && (value.canShow == True )) treasureList 

        -- d1 =Debug.log "treasure" (List.map (\value -> value.material) treasure)
    in
        treasure


updateDialogues : Model -> Dialogues
updateDialogues model =
    model.currentDialogues

hit : List Bullet -> Me -> Me
hit bullet me =
    if List.isEmpty bullet then
        me
    else
        let
            totalHurt = bullet
                    |> List.map .force
                    |> List.sum
                    |> Basics.round
            attr = me.attr
            health = getCurrentAttr Health attr
            armor = getCurrentAttr Armor attr
            newAttr = 
                if totalHurt <= armor then     -- the armor is enough to protect the player
                    setCurrentAttr Armor -totalHurt attr
                else if armor > 0 then      -- the armor is broken due to these bullets
                    setCurrentAttr Armor armor attr
                    |> setCurrentAttr Health (totalHurt - armor)
                else
                    setCurrentAttr Health -(min totalHurt health) attr
        in
            {me | attr = newAttr}


updateDualWield : Model -> Model
updateDualWield model =
    let
        dual = model.myself.skillSys.subsys
              |> List.filter (\sub -> sub.id == 2)
              |> List.head
              |> Maybe.withDefault subSysBerserker
              |> .skills
              |> List.filter (\s -> s.id == 1 && s.level == 4)
              |> List.head
              |> Maybe.withDefault skillDualWield
              |> .unlocked
        me = model.myself
        newMe =
            if dual then
                {me|dualWield = not me.dualWield}
            else
                me
    in
        {model|myself=newMe}
