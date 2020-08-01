module Synthesis.Material exposing (Material,WeaponMaterial,MaterialNeeded,bulletNeeded,weaponMaterial)
type alias Material =
    { steel : Int   
    , copper : Int 
    , wolfram : Int 
    , uranium  : Int 
    }

type alias MaterialNeeded =
    { level1 : Material
    , level2 : Material
    , level3 : Material 
    , level4 : Material 
    }

type alias WeaponMaterial =
    { pistol : MaterialNeeded
    , gatling : MaterialNeeded
    , mortar : MaterialNeeded
    , shotgun : MaterialNeeded
    }

pistolNeeded : MaterialNeeded 
pistolNeeded = 
    { level1 = Material 1 1 1 1
    , level2 = Material 2 2 2 2
    , level3 = Material 3 3 3 3
    , level4 = Material 4 4 4 4
    }

gatlingNeeded : MaterialNeeded 
gatlingNeeded = 
    { level1 = Material 2 2 1 1
    , level2 = Material 4 3 2 2
    , level3 = Material 6 4 2 2
    , level4 = Material 8 5 3 3
    }

motarNeeded : MaterialNeeded 
motarNeeded = 
    { level1 = Material 2 2 3 3
    , level2 = Material 4 4 5 5
    , level3 = Material 4 4 7 7
    , level4 = Material 4 4 9 9
    }

shotgunNeeded : MaterialNeeded 
shotgunNeeded = 
    { level1 = Material 1 3 3 2
    , level2 = Material 2 4 3 2
    , level3 = Material 3 5 4 3
    , level4 = Material 4 6 4 4
    }

bulletNeeded : Material 
bulletNeeded = Material 1 1 1 1

weaponMaterial : WeaponMaterial
weaponMaterial = WeaponMaterial pistolNeeded gatlingNeeded motarNeeded shotgunNeeded