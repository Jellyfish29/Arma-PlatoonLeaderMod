// pl_substr = {
//     private ["_find", "_string", "_find_len", "_str", "_found", "_pos"];
//     _find = _this select 0;
//     _string = toArray (_this select 1);
//     _find_len = count toArray _find;
//     _str = [] + _string;
//     _str resize _find_len;
//     _found = false;
//     _pos = 0;
//     for "_i" from _find_len to count _string do {
//         if (toString _str == _find) exitWith {_found = true};
//         _str set [_find_len, _string select _i];
//         _str set [0, "x"];
//         _str = _str - ["x"];
//         _pos = _pos + 1;
//     };
//     if (!_found) then {
//         _pos = -1;
//     };
//     _pos
// };

// How much ammo a magazine has
// Params:
// 0: our tank object
// 1: magazine name
pl_has_ammo = {
    params ["_unit", "_mag"];
    private ["_ammo", "_mag", "_unit"];
    _ammo = 0;
    {
        if (_mag == _x select 0) exitWith {_ammo = _x select 1};
    } foreach (magazinesAmmo _unit);
    _ammo
};

// Loads a round into cannon
// Params:
// 0: our tank object
// 1: magazine name to load
pl_load_mag = {
    private ["_unit", "_mag", "_mag_ammo", "_all_mags"];
    _unit = _this select 0;
    _mag = _this select 1;
    _all_mags = magazinesAmmo _unit;
    _mag_ammo = [_unit, _mag] call pl_has_ammo;
    {
        _unit removeMagazine (_x select 0);
    } foreach _all_mags;
    _unit addMagazine [_mag, _mag_ammo];
    _all_mags = _all_mags - [[_mag, _mag_ammo]];
    {
        _unit addMagazine _x;
    } foreach _all_mags;
};

pl_load_he = {
    params ["_unit"];
    private ["_he_round"];
    _he_round = "";
    {
      if (["he", _x] call BIS_fnc_inString) then {_he_round = _x};
    } foreach (magazines _unit);
    if !(_he_round isEqualTo "") then {
        if ([_unit, _he_round] call pl_has_ammo > 0) then {
            [_unit, _he_round] call pl_load_mag;
        };
    };
};

pl_load_ap = {
    params ["_unit"];
    private ["_ap_round"];
    _ap_round = "";
    {
      if (["ap", _x] call BIS_fnc_inString) then {_ap_round = _x};
      if (["sabot", _x] call BIS_fnc_inString) then {_ap_round = _x};
    } foreach (magazines _unit);

    if !(_ap_round isEqualTo "") then {
        if ([_unit, _ap_round] call pl_has_ammo > 0) then {
            [_unit, _ap_round] call pl_load_mag;
        };
    };
};

pl_bounding_move_team = {
    params ["_team", "_movePosArray", "_wpPos", "_group", "_unitPos"];

    for "_i" from 0 to (count _team) - 1 do {
        _unit = _team#_i;
        _movePos = _movePosArray#_i;
        if ((_unit distance2D _movePos) > 3) then {
            if (currentCommand _unit isNotEqualTo "MOVE" or (speed _unit) == 0) then {
                doStop _unit;
                [_unit, true] call pl_enable_force_move;
                _unit setUnitPos "UP";
                _unit doMove _movePos;
                _unit setDestination [_movePos, "LEADER DIRECT", true];
            };
        }
        else
        {
            doStop _unit;
            [_unit, false] call pl_enable_force_move;
            _unit disableAI "PATH";
            _unit setUnitPos _unitPos;
        };
    };
    if (({currentCommand _x isEqualTo "MOVE"} count (_team select {alive _x and !(_x getVariable ["pl_wia", false])})) == 0 or ({(_x distance2D _wpPos) < 15} count _team > 0) or (waypoints _group isEqualTo [])) exitWith {true};
    false
};

pl_quick_suppress = {
    params ["_unit", "_targetPos"];

    _vis = lineIntersectsSurfaces [eyePos _unit, _targetPos, _unit, vehicle _unit, true, 1];

    if !(_vis isEqualTo []) then {
        _targetPos = (_vis select 0) select 0;
    };
    
    if ((_targetPos distance2D _unit) > 25 and !([_targetPos] call pl_friendly_check)) then {
        _unit doSuppressiveFire _targetPos;
    };

};

pl_enable_force_move = {
    params ["_unit", "_state"];
    if (_state) then {
        _unit enableAI "PATH";
        _unit disableAI "COVER";
        _unit disableAI "AUTOTARGET";
        _unit disableAI "TARGET";
        _unit disableAI "SUPPRESSION";
        _unit disableAI "WEAPONAIM";
        _unit setUnitCombatMode "BLUE";
        _unit setBehaviourStrong "AWARE";
    }
    else
    {
        _unit enableAI "COVER";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "WEAPONAIM";
        _unit setUnitCombatMode "YELLOW";
    };
};

pl_position_reached_check = {
    params ["_unit", "_movePos", "_counter"];
    private ["_counter"];

    if ((_unit distance2D _movePos) > 4) then {
        if ((currentCommand _unit isNotEqualTo "MOVE" or ((speed _unit) == 0)) and (_counter % 3) == 0) then {
            doStop _unit;
            _unit setUnitPosWeak "UP";

            _unit setPosATL ([-1 + (random 2), -1 + (random 2), 0] vectorAdd (getPosATLVisual _unit)); 
            _movePos = [-1 + (random 2), -1 + (random 2), 0] vectorAdd _movePos;
            _unit doMove _movePos;
            _unit setDestination [_movePos, "LEADER DIRECT", true];
            _counter = _counter + 1;
            if (_counter == 15) then {
                _pos = (getPos _unit) findEmptyPosition [0, 10, typeOf _unit];
                _unit setPos _pos;
            };
        };
    };
    if (_counter >= 21) then {
        doStop _unit;
        _movePos = _movePos findEmptyPosition [0, _counter + 5, typeOf _unit];
        _unit doMove _movePos;
    };

    if (((_unit distance2D _movePos) < 2 and currentCommand _unit isNotEqualTo "MOVE") or _counter > 20) exitWith {[true, _movePos, _counter]};

    [false, _movePos, _counter];
};


pl_is_forest = {
    params ["_pos"];

    _trees = nearestTerrainObjects [_pos, ["Tree"], 50, false, true];

    if (count _trees > 25) exitWith {true};

    false
};

pl_convert_to_heigth_ASL = {
    params ["_pos", "_height"];

    _pos = ASLToATL _pos;
    _pos = [_pos#0, _pos#1, _height];
    _pos = ATLToASL _pos;

    _pos
};

pl_is_indoor = {
    params ["_pos"];
    _pos = AGLToASL _pos;
    if (lineIntersects [_pos, _pos vectorAdd [0, 0, 10]]) exitWith {true};
    false
};

pl_is_city = {
    params ["_pos"];
    _buildings = nearestTerrainObjects [_pos, ["House"], 50, false, true];
    if (count _buildings >= 3) exitWith {true};
    false
};

pl_fof_check = {
    params ["_pos","_d", "_h"];
    private _c = 0;
    _startPos = [_pos, _h] call pl_convert_to_heigth_ASL;
    for "_i" from 0 to 300 step 25 do {

        _checkPos = [_pos getPos [_i, _d], _h] call pl_convert_to_heigth_ASL;

        _visP = lineIntersectsSurfaces [_startPos, _checkPos, objNull, objNull, true, 1, "VIEW"];

        if !(_visP isEqualTo []) exitWith {};
        _c = _c + 1;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
        // _helper setposASL _checkPos;
    };
    _c
};

pl_get_near_inf_groups = {
    params {"_group", "_distance", ["_side", playerside]};

    private _allies = ((getPos (leader _group)) nearEntities [["Man"], _distance]) select {side (leader _group) == _side};
    private _nearGroups = [];

    {
        _nearGroups pushBackUnique (group _x);
    } forEach _allies;

    _nearGroups
};

pl_find_highest_point = {
    params ["_center", "_radius", ["_uDir", 0]];

    private _scanStart = (_center getPos [_radius / 2, _uDir]) getPos [_radius / 2, _uDir + 90];
    private _widthOffSet = 0;
    private _heigthOffset = 0;
    private _maxZ = 0;
    private _r = _center;
    for "_i" from 0 to 100 do {
        _heigthOffset = 0;
        _scanPos = _scanStart getPos [_widthOffSet, _uDir - 180];
        for "_j" from 0 to 100 do {
            _checkPos = _scanPos getPos [_heigthOffset, _uDir - 90];
            _checkPos = ATLToASL _checkPos;

            // _m = createMarker [str (random 1), _checkPos];
   //       _m setMarkerType "mil_dot";
   //       _m setMarkerSize [0.3, 0.3];

            _z = _checkPos#2;
            if (_z > _maxZ) then {
                _r = _checkPos;
                _maxZ = _z;
            };
            _heigthOffset = _heigthOffset + (_radius / 100);
        };
        _widthOffSet = _widthOffSet + (_radius / 100);
    };

    // _m = createMarker [str (random 1), _r];
    // _m setMarkerColor "colorGreen";
    // _m setMarkerType "mil_dot";
    ASLToATL _r;
    _r
};

pl_friendly_check = {
    params ["_unit", "_pos"];

    // _m = createMarker [str (random 1), _pos];
    // _m setMarkerType "mil_dot";
    // _m setMarkerColor "colorGreen";
    
    _distance = _unit distance2D _pos; 
    _allies = (_pos nearEntities [["Man", "Car", "Tank"], 10 + (_distance * 0.25)]) select {side _x == side _unit};
    // player sideChat str _allies;
    if !(_allies isEqualTo []) exitWith {true};
    false
};

pl_clear_obstacles = {
    params ["_pos", "_radius"];

    {
         deleteVehicle _x;
    } forEach (allDead select {(_x distance2D _pos) < _radius});
    // remove Fences
    {
        deleteVehicle _x;
    } forEach ((_pos nearObjects _radius) select {["fence", typeOf _x] call BIS_fnc_inString or ["barrier", typeOf _x] call BIS_fnc_inString or ["wall", typeOf _x] call BIS_fnc_inString or ["sand", typeOf _x] call BIS_fnc_inString});
    // remove Bunkers
    {
        deleteVehicle _x;;
    } forEach ((_pos nearObjects _radius) select {["bunker", typeOf _x] call BIS_fnc_inString});
    // remove wire
    {
        deleteVehicle _x;
    } forEach ((_pos nearObjects _radius) select {["wire", typeOf _x] call BIS_fnc_inString});
    // kill trees
    {
        _x setDamage 1;
    } forEach (nearestTerrainObjects [_pos, ["TREE", "SMALL TREE", "BUSH"], _radius, false, true]);
};