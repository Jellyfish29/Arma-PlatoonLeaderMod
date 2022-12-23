pl_bounding_cords = [0,0,0];
pl_bounding_mode = "full";
pl_bounding_draw_array = [];
pl_draw_tank_hunt_array = [];
pl_suppress_area_size = 20;
pl_suppress_cords = [0,0,0];
pl_supppress_continuous = false;
pl_draw_suppression_array = [];
pl_sweep_cords = [0,0,0];
pl_sweep_area_size = 35;
pl_attack_mode = "normal";



pl_suppressive_fire_position = {
    params [["_group", (hcSelected player) select 0], ["_sfpPos", []], ["_cords", []]];
    private ["_markerName", "_targets", "_pos", "_units", "_leader", "_area", "_mPos", "_markerPosName", "_leaderPos"];

    // _group = (hcSelected player) select 0;

    // if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0 and (_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    // if (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) > 0) exitWith {};

    if ((_group getVariable ["pl_is_suppressing", false])) exitWith {_group setVariable ["pl_is_suppressing", false]};

    pl_suppress_area_size = 50;

    _markerName = format ["%1suppress%2", _group, random 1];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor "colorOrange";
    _markerName setMarkerAlpha 0.2;
    _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];

    if (_cords isEqualTo []) then {

        if (visibleMap or !(isNull findDisplay 2000)) then {
            _leaderPos = getPos (leader _group);
            if !(_sfpPos isEqualTo []) then {
                _leaderPos = _sfpPos;
            };
            private _rangelimiter = 500;
            if (vehicle (leader _group) != (leader _group)) then { _rangelimiter = 1000};

            _markerBorderName = str (random 2);
            createMarker [_markerBorderName, _leaderPos];
            _markerBorderName setMarkerShape "ELLIPSE";
            _markerBorderName setMarkerBrush "Border";
            _markerBorderName setMarkerColor "colorOrange";
            _markerBorderName setMarkerAlpha 0.8;
            _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];
            
            _message = "Select Position <br /><br />
                <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>30 Seconds</t> <br />
                <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />
                <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>Cancel</t> <br />";
            hint parseText _message;
            onMapSingleClick {
                pl_suppress_cords = _pos;
                if (_shift) then {pl_cancel_strike = true};
                pl_mapClicked = true;
                hintSilent "";
                onMapSingleClick "";
            };

            player enableSimulation false;

            if !(_sfpPos isEqualTo []) then {
                pl_show_watchpos_selector = true;
            };

            while {!pl_mapClicked} do {
                // sleep 0.1;
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                if ((_mPos distance2D _leaderPos) <= _rangelimiter) then {
                    _markerName setMarkerPos _mPos;
                };
                // _markerName setMarkerPos _mPos;
                if (inputAction "MoveForward" > 0) then {pl_suppress_area_size = pl_suppress_area_size + 5; sleep 0.05};
                if (inputAction "MoveBack" > 0) then {pl_suppress_area_size = pl_suppress_area_size - 5; sleep 0.05};
                _markerName setMarkerSize [pl_suppress_area_size, pl_suppress_area_size];
                if (pl_suppress_area_size >= 150) then {pl_suppress_area_size = 150};
                if (pl_suppress_area_size <= 10) then {pl_suppress_area_size = 10};
            };

            pl_show_watchpos_selector = false;

            player enableSimulation true;

            pl_mapClicked = false;
            _cords = getMarkerPos _markerName;
            _area = pl_suppress_area_size;
            deleteMarker _markerBorderName;
        }
        else
        {
            _cords = screenToWorld [0.5,0.5];
            _area = 25;
        };
    } else {
        _markerName setMarkerPos _cords;
        _area = 30;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};


    if !(_sfpPos isEqualTo []) then {

        pl_at_targets_indicator pushBack [_sfpPos, _cords];

        waitUntil {sleep 0.5; !(_group getVariable ["pl_task_planed", false])};

        sleep 2;
        if (vehicle (leader _group) == (leader _group)) then {

            waitUntil {(({_x getVariable ["pl_in_position", false]} count (units _group)) == count (units _group)) or !(_group getVariable ["onTask", false])};
            if !(_group getVariable ["onTask", false]) exitWith {pl_cancel_strike = true};
        } else {
            waitUntil {(_group getVariable ["pl_in_position", false]) or !(_group getVariable ["onTask", false])};
            if !(_group getVariable ["onTask", false]) exitWith {pl_cancel_strike = true};
        };
        pl_at_targets_indicator = pl_at_targets_indicator - [[_sfpPos, _cords]];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};

    if (_group getVariable ["pl_in_position", false]) then {
        _markerPosName = format ["defenceAreaDir%1", _group];
        _markerPosName setMarkerType "marker_sfp";
    } else {
        _markerPosName  = format ["afp%1", _group];
        createMarker [_markerPosName , getPos (vehicle (leader _group))];
        _markerPosName setMarkerDir ((leader _group) getDir _cords);
        _markerPosName  setMarkerType "marker_afp";
        _markerPosName  setMarkerColor pl_side_color;
    };   

    
    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa";
    _leader = leader _group;
    pl_draw_suppression_array pushBack [_cords, _leader, false, _icon];
    [_group, "suppress", 1] call pl_voice_radio_answer;
    

    _group setVariable ["pl_is_suppressing", true];
    // check if enemy in Area
    // _allTargets = nearestObjects [_cords, ["Man", "Car", "Truck", "Tank"], _area, true];
    _getTargets = {
        params ["_cords", "_area"];
        private _targetsPos = [];
        private _allTargets = _cords nearEntities [["Man", "Car", "Truck", "Tank"], _area];
        {
            _targetsPos pushBack (getPosATL _x);
        } forEach (_allTargets select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        // if no enemy target buildings;
        private _buildings = nearestObjects [_cords, ["house"], _area];
        if !((count _buildings) == 0) then {
            {
                _bPos = [0,0,2] vectorAdd (getPosATL _x);
                _targetsPos pushBack _bPos;
            } forEach _buildings;
        };

        // add Random Possitions
        if (_targetsPos isEqualTo []) then {
            for "_i" from 0 to 5 do {
                _rPos = [[[_cords, _area]], nil] call BIS_fnc_randomPos;
                _targetsPos pushBack _rPos;
            };
        };
        private _return = ATLToASL (selectRandom _targetsPos);
        _return
    };

    private _units = (units _group);

    if (_group getVariable ["pl_inf_attached", false]) then {
        _vicGroup = _group getVariable ["pl_attached_vicGrp", grpNull];
        _units = _units + (units _vicGroup);
    };

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_he;
    };

    while {(_group getVariable ["pl_is_suppressing", true]) and !(isNull _group)} do {
        {
            _unit = _x;
            if (((leader _group) != (vehicle (leader _group))) or (((primaryweapon _unit call BIS_fnc_itemtype) select 1) == "MachineGun") or (random 1) > 0.25) then {
                _unit = _x;
                _pos = [_cords, _area] call _getTargets;
                _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];

                if !(_vis isEqualTo []) then {
                    _targetPos = (_vis select 0) select 0;
                    if ((_targetPos distance2D _unit) > pl_suppression_min_distance and !([_unit, _targetPos] call pl_friendly_check) and !(getNumber ( configFile >> "CfgVehicles" >> typeOf _unit >> "attendant" ) isEqualTo 1)) then {
                        _unit doSuppressiveFire _targetPos
                    };
                };
            };
        } forEach _units ;
        _time = time + 15;
        waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["pl_is_suppressing", false])};
        if ((([_group] call pl_get_ammo_group_state)#0) == "Red") exitWith {};
    };

    sleep 0.5;

    // waitUntil {sleep 0.5; (({(currentCommand _x) isEqualTo "Suppress"} count (units _group)) <= 0 and !(_group getVariable ["pl_is_suppressing", false])) or !alive (leader _group)};

    if (leader _group != vehicle (leader _group)) then {
        [vehicle (leader _group)] call pl_load_ap;
    };

    deleteMarker _markerName;
    if (_group getVariable ["pl_in_position", false]) then {
        _markerPosName = format ["defenceAreaDir%1", _group];
        _markerPosName setMarkerType "marker_position";
    } else {
        deleteMarker _markerPosName;
    };

    pl_draw_suppression_array = pl_draw_suppression_array - [[_cords, _leader, false, _icon]];
};

pl_throw_granade_at_target = {
    params ["_unit", "_target"];

    private _safetyDistance = 15;
    if ([getpos _target] call pl_is_indoor) then {
        _safetyDistance = 5;
    };

    if ((_unit distance2D _target) > 30) exitWith {_target setVariable ["pl_nade_cd", time + 10]; false};
    if ((_unit distance2D _target) < _safetyDistance) exitWith {_target setVariable ["pl_nade_cd", time + 10]; false};

    if ([_unit, getPos _target, _safetyDistance] call pl_friendly_check_excact) exitWith {false};

    _unit setVariable ["pl_hg_target", _target];
    _unit forceSpeed 0;
    _unit doWatch _target;
    _unit doTarget _target;
    _eh = _unit addEventHandler ["FiredMan", {
            params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

            if (_muzzle isEqualto 'HandGrenadeMuzzle') then {
                [_unit, _projectile] spawn {
                    params ["_unit", "_projectile"];

                    _target = _unit getVariable ["pl_hg_target", objNull];

                    _vel = [_unit, getPos _target, 30] call pl_THROW_VEL;

                    _projectile setVelocity _vel;

                    sleep 3;
                    // waitUntil{ (vectorMagnitude velocity _projectile) < 0.02 };


                    _projectile setPosASL ((getPosASLVisual _target) vectorAdd [1 - (random 2), 1 - (random 2), 1]);
                    // _projectile setPosASL (getPosATLVisual _target);

                    // _m = createMarker [str (random 2), getPosASLVisual _target];
                    // _m setMarkerType "mil_dot";
                    _unit setVariable ["pl_hg_target", nil];
                };
                _unit removeEventHandler [_thisEvent, _thisEventHandler];
                
            };
        }];
    _target setVariable ["pl_nade_cd", time + 8];
    sleep 1;
    _fired = [_unit, 'HandGrenadeMuzzle'] call BIS_fnc_fire;
    _unit forceSpeed -1;
    _fired
};

// [cursorTarget, target_1] spawn pl_throw_granade_at_target;

pl_throw_smoke_at_pos = {
    params ["_unit", "_smokePos"];

    if ((_unit distance2D _smokePos) > 50) exitWith {false}; 

    _unit forceSpeed 0;
    _unit setVariable ["pl_smoke_pos", _smokePos];

    _eh = _unit addEventHandler ["FiredMan", {
            params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

            if (_muzzle isEqualto "SmokeShellMuzzle") then {
                [_unit, _projectile] spawn {
                    params ["_unit", "_projectile"];

                    _smokePos = _unit getVariable ["pl_smoke_pos", getpos _unit];

                    _vel = [_unit, _smokePos, 50] call pl_THROW_VEL;

                    _projectile setVelocity _vel;

                    // sleep 2;
                    waitUntil{ (vectorMagnitude velocity _projectile) < 0.02 };

                    _projectile setPos (_unit getVariable ["pl_smoke_pos", getpos _unit]);

                    _unit setVariable ["pl_smoke_pos", nil];

                };
                _unit removeEventHandler [_thisEvent, _thisEventHandler];
                
            };
        }];
    sleep 0.5;
    _fired = [_unit, "SmokeShellMuzzle"] call BIS_fnc_fire;
    _unit forceSpeed -1;
    _fired
};

pl_fire_ugl_at_target = {
    params ["_unit", "_target"];

    if ((_unit distance2D _target) > 300) exitWith {false};
    if ((_unit distance2D _target) < 30) exitWith {false};

    if ([_unit, getPos _target, 35] call pl_friendly_check_excact) exitWith {false};

    _ugl = (getArray (configfile >> "CfgWeapons" >> primaryWeapon _unit >> "muzzles") - ["SAFE", "this"]) param [0, ""];

    if (_ugl isEqualto "") exitWith {false};

    _unit forceSpeed 0;
    _unit doTarget _target;
    _unit setVariable ["pl_ugl_data", [_ugl, getPosASL _target]];
    _eh = _unit addEventHandler ["FiredMan", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

        _uglData = _unit getVariable "pl_ugl_data";

        if (_muzzle isEqualto (_uglData#0)) then {

            _vel = [_unit, (_uglData#1) getPos [4, (_uglData#1) getDir _unit], 300] call pl_THROW_VEL;

            _projectile setVelocity _vel;

            _unit removeEventHandler [_thisEvent, _thisEventHandler];
        };


    }];

    sleep 1;

    _unit selectWeapon _ugl;
    _unit forceWeaponFire [_ugl, weaponState _unit select 2];

    _unit forceSpeed -1;
    _unit doWatch objNull;
    true

};

pl_assault_position = {
    params ["_group", ["_taskPlanWp", []], ["_cords", []]];
    private ["_mPos", "_movePosArrayCover", "_movePosArrayManuver", "_leftPos", "_rightPos", "_markerPhaselineName", "_cords", "_limiter", "_targets", "_markerName", "_wp", "_icon", "_coverTeam","_manuverTeam", "_formation", "_fastAtk", "_tacticalAtk", "_breakingPoint", "_startPos", "_area", "_vicGroup"];

    pl_sweep_area_size = 35;

    if ((vehicle (leader _group) != leader _group and !(_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false])) and !(_group getVariable ["pl_unload_task_planed", false])) exitWith {hint "Infantry ONLY Task!"};


    _markerName = format ["%1sweeper", _group];
    createMarker [_markerName, [0,0,0]];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "SolidBorder";
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerAlpha 0.35;
    _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];

    _arrowMarkerName = format ["%1arrow", _group];
    createMarker [_arrowMarkerName, [0,0,0]];
    _arrowMarkerName setMarkerType "marker_std_atk";
    _arrowMarkerName setMarkerDir 0;
    _arrowMarkerName setMarkerColor pl_side_color;
    _arrowMarkerName setMarkerSize [1.2, 1.2];

    _markerPhaselineName = format ["%1atk_phase", _group];
    createMarker [_markerPhaselineName, [0,0,0]];
    _markerPhaselineName setMarkerShape "RECTANGLE";
    _markerPhaselineName setMarkerBrush "Solid";
    _markerPhaselineName setMarkerColor pl_side_color;
    _markerPhaselineName setMarkerAlpha 0.7;
    _markerPhaselineName setMarkerSize [pl_sweep_area_size, 0.5];

    if (_cords isEqualTo []) then {

        if !(visibleMap) then {
            if (isNull findDisplay 2000) then {
                [leader _group] call pl_open_tac_forced;
            };
        };
        private _rangelimiterCenter = getPos (leader _group);
        if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};
        private _rangelimiter = 200;
        _markerBorderName = str (random 2);
        createMarker [_markerBorderName, _rangelimiterCenter];
        _markerBorderName setMarkerShape "ELLIPSE";
        _markerBorderName setMarkerBrush "Border";
        _markerBorderName setMarkerColor "colorOrange";
        _markerBorderName setMarkerAlpha 0.8;
        _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

        _message = "Select Assault Location <br /><br />
            <t size='0.8' align='left'> -> LMB</t><t size='0.8' align='right'>SELECT Position</t> <br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />
            <t size='0.8' align='left'> -> W / S</t><t size='0.8' align='right'>INCREASE / DECREASE Size</t> <br />";
        hint parseText _message;
        onMapSingleClick {
            pl_sweep_cords = _pos;
            if (_shift) then {pl_cancel_strike = true};
            pl_mapClicked = true;
            hintSilent "";
            onMapSingleClick "";
        };

        private _rangelimiterCenter = getPos (leader _group);
        if (count _taskPlanWp != 0) then {_rangelimiterCenter = waypointPosition _taskPlanWp};

        player enableSimulation false;

        while {!pl_mapClicked} do {
            // sleep 0.1;
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };

            if (inputAction "MoveForward" > 0) then {pl_sweep_area_size = pl_sweep_area_size + 5; sleep 0.05};
            if (inputAction "MoveBack" > 0) then {pl_sweep_area_size = pl_sweep_area_size - 5; sleep 0.05};
            _markerName setMarkerSize [pl_sweep_area_size, pl_sweep_area_size];
            if (pl_sweep_area_size >= 120) then {pl_sweep_area_size = 120};
            if (pl_sweep_area_size <= 5) then {pl_sweep_area_size = 5};

            if ((_mPos distance2D _rangelimiterCenter) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;

                if (_mPos distance2D (leader _group) > pl_sweep_area_size + 35) then {
                    _phaseDir = _mPos getDir _rangelimiterCenter;
                    _phasePos = _mPos getPos [pl_sweep_area_size + 35, _phaseDir];
                    _markerPhaselineName setMarkerPos _phasePos;
                    _markerPhaselineName setMarkerDir _phaseDir;
                    _markerPhaselineName setMarkerSize [pl_sweep_area_size + 10, 0.5];

                    _arrowPos = _phasePos getPos [-15, _phaseDir];
                    _arrowDir = _phaseDir - 180;
                    _arrowDis = (_rangelimiterCenter distance2D _mPos) / 2;

                    _arrowMarkerName setMarkerPos _arrowPos;
                    _arrowMarkerName setMarkerDir _arrowDir;
                    _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
                } else {
                    _arrowMarkerName setMarkerSize [0,0];
                    _markerPhaselineName setMarkerSize [0,0];
                };
            };


        };

        player enableSimulation true;

        pl_mapClicked = false;
        deleteMarker _markerBorderName;
        _cords = getMarkerPos _markerName;
        _markerName setMarkerPos _cords;
        _markerName setMarkerBrush "Border";
        _area = pl_sweep_area_size;
    } else {
        _area = (((leader _group) distance2D _cords) / 2) + 30;
        _markerName setMarkerPos _cords;
        _markerName setMarkerBrush "Border";
    };

    _rightPos = _cords getPos [pl_sweep_area_size, 90];
    _leftPos = _cords getPos [pl_sweep_area_size, 270];
    pl_draw_text_array pushBack ["ENY", _leftPos, 0.02, pl_side_color_rgb];
    pl_draw_text_array pushBack ["ENY", _rightPos, 0.02, pl_side_color_rgb];

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa";

    if (count _taskPlanWp != 0) then {

        // add Arrow indicator
        pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

        if (vehicle (leader _group) != leader _group) then {
            if !(_group getVariable ["pl_unload_task_planed", false]) then {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 25) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
            } else {
                // waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
                waitUntil {sleep 0.5; ((_group getVariable ["pl_execute_plan", false]) and (_group getVariable ["pl_disembark_finished", false])) or !(_group getVariable ["pl_task_planed", false])};
            };
        } else {
            // waitUntil {sleep 0.5; ((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11 or !(_group getVariable ["pl_task_planed", false])};
            waitUntil {sleep 0.5; (_group getVariable ["pl_execute_plan", false]) or !(_group getVariable ["pl_task_planed", false])};
        };
        _group setVariable ["pl_disembark_finished", nil];

        // remove Arrow indicator
        pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
        _group setVariable ["pl_unload_task_planed", false];
        _group setVariable ["pl_execute_plan", nil];
    };

    if (pl_cancel_strike) exitWith {
        pl_cancel_strike = false;
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        deleteMarker _arrowMarkerName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
     };


    _arrowDir = (leader _group) getDir _cords;
    _arrowDis = ((leader _group) distance2D _cords) / 2;
    _arrowPos = [_arrowDis * (sin _arrowDir), _arrowDis * (cos _arrowDir), 0] vectorAdd (getPos (leader _group));

    pl_draw_text_array pushBack ["SEIZE", _cords, 0.025, pl_side_color_rgb]; 

    [_group, "attack", 1] call pl_voice_radio_answer;

    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _group setVariable ["pl_is_attacking", true];

    _startPos = getPos (leader _group);

    (leader _group) limitSpeed 15;

    _markerName setMarkerPos _cords;

    sleep 2;

    private _machinegunner = objNull;
    private _medic = objNull;

    _group setBehaviour "AWARE";
    (leader _group) limitSpeed 12;

    private _atkTriggerDistance = 15;
    private _approachPos = _cords getPos [_area + 10, _cords getDir _startPos];
    private _endPos = _cords getPos [_area, _approachPos getDir _cords];

    private _startUnitCount = {alive _x and !((lifeState _x) isEqualto "INCAPACITATED")} count (units _group);
    _breakingPoint = round (_startUnitCount * 0.66);
    if (_breakingPoint >= ({alive _x and !((lifeState _x) isEqualto "INCAPACITATED")} count (units _group))) then {_breakingPoint = -1};

    private _mode = ["team", "buddy"] selectRandomWeighted [3, 1];

    if ([_startPos] call pl_is_forest) then {_mode = "team"};
    if ([_startPos] call pl_is_city) then {_mode = "buddy"};



    [_approachPos, _cords, _area,  _group, _markerPhaselineName, _arrowMarkerName] spawn {
        params ["_approachPos", "_cords", "_area",  "_group", "_markerPhaselineName", "_arrowMarkerName"];

        while {(({(_x distance _approachPos) < 25} count (units _group)) == 0) and (_group getVariable ["onTask", true])} do {

            if (_cords distance2D (leader _group) > _area + 20) then {
                _phaseDir = (leader _group) getDir _cords;
                _markerPhaselineName setMarkerDir _phaseDir;

                _arrowPos = (getMarkerPos _markerPhaselineName) getPos [- 15, _phaseDir - 180];
                _arrowDis = ((leader _group) distance2D _cords) / 2;

                _arrowMarkerName setMarkerPos _arrowPos;
                _arrowMarkerName setMarkerDir _phaseDir;
                _arrowMarkerName setMarkerSize [1.5, _arrowDis * 0.02];
            } else {
                _arrowMarkerName setMarkerSize [0,0];
                _markerPhaselineName setMarkerSize [0,0];
            };
            sleep 0.1;
        };
    };

    private _teams = [];

    // APPROACH //

    _mode = "team";

    if (_startPos distance2d _approachPos > 30 and (_taskPlanWp isEqualTo [])) then {
        if (vehicle (leader _group) == leader _group) then {

            _teams = [_mode, _group, _approachPos] call pl_bounding_squad;

        } else {
            [vehicle (leader _group), _approachPos, 5] call pl_vic_advance_to_pos_static;
        };
    } else {
        if (_startPos distance2d _approachPos > 10) then {
            if (vehicle (leader _group) != leader _group) then {
                [vehicle (leader _group), _approachPos, 5] call pl_vic_advance_to_pos_static;
            };
        };
    };

    // waitUntil {sleep 0.5; (({(_x distance _cords) < (_area + _atkTriggerDistance)} count (units _group)) > 0) or !(_group getVariable ["onTask", true])};


    if (!(_group getVariable ["onTask", true])) exitWith {
        deleteMarker _markerName;
        deleteMarker _markerPhaselineName;
        pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];
        pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 
        deleteMarker _arrowMarkerName;
        _group setVariable ["pl_is_attacking", false];
        {
            _x setVariable ["pl_damage_reduction", false];
        } forEach (units _group);
    };


    if (_group getVariable ["pl_has_cargo", false] or _group getVariable ["pl_vic_attached", false]) then {

        private _infGroup = grpNull;
        _medic = objNull;
        private _vic = vehicle (leader _group);
        _vicGroup = _group;

        [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
        sleep 0.1;
        for "_i" from count waypoints _group - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };
        
        _vicGroup setVariable ["pl_on_march", false];

        if (_group getVariable ["pl_has_cargo", false]) then {

            private _cargo = (crew _vic) - (units _group);

            private _cargoGroups = [];
            {
                _unit = _x;

                if !(_unit in (units (group player))) then {
                    _cargoGroups pushBack (group _unit);
                };

                _unit disableAI "AUTOCOMBAT";
                _unit setCombatBehaviour "AWARE";
                _unit setVariable ["pl_damage_reduction", true];
                _unit setHit ["legs", 0];
                unassignVehicle _unit;
                doGetOut _unit;
                [_unit] allowGetIn false;

            } forEach _cargo;

            private _limit = 0;
            {
                if ((count (units _x)) > _limit) then {
                    _limit = count (units _x);
                    _infGroup = _x;
                };
                [_x] spawn pl_reset;
            } forEach _cargoGroups;

            if !(_infGroup getVariable ["pl_show_info", false]) then {
                [_infGroup] call pl_show_group_icon;
            };

            _infGroup leaveVehicle _vic;

            _vic setVariable ["pl_on_transport", nil];
            _group setVariable ["pl_has_cargo", false];

            waitUntil {sleep 0.5; (({vehicle _x != _x} count (units _infGroup)) == 0) or (!alive _vic)};
            sleep 2;
            waitUntil {sleep 0.5; ({unitReady _x} count (units _infGroup)) == (count (units _infGroup))};
        } else {
            _infGroup = _group getVariable ["pl_attached_infGrp", grpNull];
            _group setVariable ["pl_vic_attached", false];
            _group setVariable ["pl_attached_infGrp", nil];

            {
                _x disableAI "AUTOCOMBAT";
                _x setCombatBehaviour "AWARE";
                _x setVariable ["pl_damage_reduction", true];
            } forEach (units _infGroup);
        };

        sleep 1;

        [_infGroup] call pl_reset;

        sleep 0.5;

        [_infGroup] call pl_reset;

        sleep 0.5;

        _infGroup setVariable ["onTask", true];
        _infGroup setVariable ["setSpecial", true];
        _infGroup setVariable ["specialIcon", _icon];
        _infGroup setVariable ["pl_is_attacking", true];

        _startPos = getPos (leader _infGroup);

        (leader _infGroup) limitSpeed 15;

        _vicGroup = _group;
        _group = _infGroup;

        [_vicGroup] spawn pl_reset;

        sleep 0.5;

        [_vicGroup, _infGroup] spawn pl_attach_vic;

        _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) * 0.66);
        if (_breakingPoint >= ({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group))) then {_breakingPoint = -1};

    };

    // ATTACK //

    {
        _unit = _x;
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {_medic = _x};
        if (((primaryweapon _unit call BIS_fnc_itemtype) select 1) == "MachineGun") then {_machinegunner = _unit};
    } forEach (units _group);



    _targets = [];
    _allMen = _cords nearObjects ["Man", _area];
    _vics = _cords nearEntities [["Car", "Tank", "Truck"], _area];
    _targetBuildings = [];

    {
        _targets pushBack _x;
        if ([getPos _x] call pl_is_indoor) then {
            _targetBuildings pushBackUnique (nearestBuilding (getPos _x));

            // _m = createMarker [str (random 1), (getPos _x)];
            // _m setMarkerType "mil_dot";

        };
    } forEach (_allMen select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    _targetBuildings = [_targetBuildings, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

    missionNamespace setVariable [format ["targetBuildings_%1", _group], _targetBuildings];

    {
        _targets pushBack _x;
    } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

    _targets = [_targets, [], {(leader _group) distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;

    // private _breakingPoint = round (({alive _x and !(_x getVariable ["pl_wia", false])} count (units _group)) * 0.66);
    // hint str _breakingPoint;
    
    private _taskTime = time + 240;

    if ((count _targets) == 0) then {

        // {
        //     _x doFollow (leader _group);
        // } forEach (units _group);

        // (leader _group) doMove _cords;
        _time = time + 5;
        waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or (time > _time) or (leader _group) distance2D _cords < 10};
    }
    else
    {

        [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
        sleep 0.1;
        for "_i" from count waypoints _group - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };


        if (_teams isEqualto []) then {
            private _team1 = [];
            private _team2 = [];
            _ii = 0;
            {
                if (_ii % 2 == 0) then {
                    _team1 pushBack _x;
                }
                else
                {
                    _team2 pushBack _x;
                };
                _ii = _ii + 1;
            } forEach ((units _group) select {alive _x and !(_x getVariable ["pl_wia", false])});

            _teams = [_team1, _team2];
        };

        sleep 0.2;
        missionNamespace setVariable [format ["targets_%1", _group], _targets];

        if (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _startUnitCount) then {
            [leader _group, _approachPos] call pl_throw_smoke_at_pos;
        };
        
        if (_machinegunner in (_teams#0)) then {
            _coverTeam = _teams#0;
            _manuverTeam = _teams#1;
        } else {
            _coverTeam = _teams#1;
            _manuverTeam = _teams#0;
        };

        {
            // waitUntil {sleep 0.5; unitReady _x or !alive _x};

            _x enableAI "AUTOCOMBAT";
            _x enableAI "FSM";
            _x forceSpeed 12;

            if (_x == _medic and (_group getVariable ["pl_healing_active", false])) then {
                [_x, 15, _x getDir _cords] spawn pl_find_cover;
                [_group, _x, _startPos] spawn pl_defence_ccp;
                // _x setVariable ["pl_engaging", true];
                _breakingPoint = _breakingPoint - 1;
            } else {

                [_x, _group, _area, _cords, _medic, _machinegunner, _coverTeam, _manuverTeam] spawn {
                    params ["_unit", "_group", "_area", "_cords", "_medic", "_machinegunner", "_coverTeam", "_manuverTeam"];
                    private ["_movePos", "_target"];

                    while {sleep 0.5; (count (missionNamespace getVariable format ["targets_%1", _group])) > 0} do {

                        if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};

                        if ((secondaryWeapon _unit) != "" and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {
                            _target = {
                                _attacker = _x getVariable ["pl_at_enaged_by", objNull];
                                if (!(_x isKindOf "Man") and alive _x and (isNull _attacker or _attacker == _unit)) exitWith {_x};
                                objNull
                            } forEach (missionNamespace getVariable format ["targets_%1", _group]);
                            if !(isNull _target) then {
                                _target setVariable ["pl_at_enaged_by", _unit];
                                _checkPosArray = [];
                                private _atkDir = _unit getDir _target;
                                private _lineStartPos = (getPos _unit) getPos [(_area + 100)  / 2, _atkDir - 90];
                                _lineStartPos = _lineStartPos getPos [8, _atkDir];
                                private _lineOffsetHorizon = 0;
                                private _lineOffsetVertical = (_target distance2D _unit) / 60;
                                _targetDir = getDir _target;
                                for "_i" from 0 to 60 do {
                                    for "_j" from 0 to 60 do { 
                                        _checkPos = _lineStartPos getPos [_lineOffsetHorizon, _atkDir + 90];
                                        _lineOffsetHorizon = _lineOffsetHorizon + ((_area + 100) / 60);

                                        _checkPos = [_checkPos, 1.579] call pl_convert_to_heigth_ASL;

                                        // _m = createMarker [str (random 1), _checkPos];
                                        // _m setMarkerType "mil_dot";
                                        // _m setMarkerSize [0.2, 0.2];

                                        _vis = lineIntersectsSurfaces [_checkPos, AGLToASL (unitAimPosition _target), _target, vehicle _target, true, 1, "VIEW"];
                                        // _vis2 = [_target, "VIEW", _target] checkVisibility [_checkPos, AGLToASL (unitAimPosition _target)];
                                        if (_vis isEqualTo []) then {
                                                _pointDir = _target getDir _checkPos;
                                                if (_pointDir >= (_targetDir - 50) and _pointDir <= (_targetDir + 50)) then {
                                                    // _m setMarkerColor "colorORANGE";
                                                } else {
                                                    if (_target distance2D _checkPos >= 30) then {
                                                        _checkPosArray pushBack _checkPos;
                                                        // _m setMarkerColor "colorRED";
                                                    };
                                                };
                                            };
                                        };
                                    _lineStartPos = _lineStartPos getPos [_lineOffsetVertical, _atkDir];
                                    _lineOffsetHorizon = 0;
                                };
                                _lineOffsetVertical = 0;

                                if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _unit) isEqualTo [])) then {


                                    // _movePos = ([_checkPosArray, [], {_target distance2D _x}, "DESCEND"] call BIS_fnc_sortBy) select 0;
                                    _movePos = ([_checkPosArray, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;
                                    _unit doMove _movePos;
                                    _unit setDestination [_movePos, "FORMATION PLANNED", false];
                                    pl_at_attack_array pushBack [_unit, _target, objNull];

                                    _unit forceSpeed 3;
                                    _unit disableAI "AUTOCOMBAT";
                                    _unit setUnitTrait ["camouflageCoef", 0, true];
                                    _unit disableAi "AIMINGERROR";
                                    _unit setVariable ["pl_engaging", true];
                                    _unit setVariable ['pl_is_at', true];

                                    _unit reveal [_target, 2];
                                    _unit doTarget _target;

                                    _time = time + ((_unit distance _movePos) / 1.6 + 10);
                                    sleep 0.5;
                                    waitUntil {sleep 0.5; (time >= _time or (_unit distance2D _movePos) < 6 or !alive _unit or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]) or !alive _target or (count (crew _target) == 0))};

                                    _time = time + 15;
                                    waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target or (count (crew _target) == 0)};
                                    // pl_at_attack_array = pl_at_attack_array - [[_unit, _movePos]];
                                    if (alive _target) then {_unit setVariable ['pl_is_at', false]; pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]]; continue};
                                    if !(alive _target or !alive _unit or _unit getVariable ["pl_wia", false]) then {_target setVariable ["pl_at_enaged_by", nil]};
                                    pl_at_attack_array = pl_at_attack_array - [[_unit, _target, objNull]];
                                    _unit setVariable ['pl_is_at', false];
                                    _unit setUnitTrait ["camouflageCoef", 1, true];
                                    _unit enableAi "AIMINGERROR";
                                    _unit setVariable ["pl_engaging", false];
                                    _unit enableAI "AUTOTARGET";
                                    _unit setBehaviour "AWARE";
                                    _unit setUnitCombatMode "YELLOW";
                                    _group setVariable ["pl_grp_active_at_soldier", nil];
                                } else {
                                    _target setVariable ["pl_at_enaged_by", nil];
                                };
                                sleep 1;
                            };
                        };

                        // _target = (missionNamespace getVariable format ["targets_%1", _group])#([0,1] call BIS_fnc_randomInt);
                        _target = (missionNamespace getVariable format ["targets_%1", _group])#0;

                        if (!(alive _target) or captive _target) then {
                            (missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target);
                            continue;
                        };

                        if !(isNil "_target") then {
                            if (alive _target and !(captive _target) and (_target isKindOf "Man")) then {
                                _pos = getPosATL _target;
                                _movePos = _pos vectorAdd [0.5 - (random 1), 0.5 - (random 1), 0];
                                // _unit limitSpeed 15;
                                _unit setVariable ["pl_engaging", true];

                                private _unreachableTimeOut = time + 15;
                                if (_unit in _coverTeam) then {
                                    doStop _unit;
                                    sleep 0.2;

                                    _idx = _coverTeam find _unit;


                                    [_unit, 8, _unit getDir _target, true, (getPos _unit) getPos [16, _unit getDir _target]] call pl_find_cover;

                                    _ugled = [_unit, _target] call pl_fire_ugl_at_target;

                                    waitUntil {sleep 0.5; time >= _unreachableTimeOut or !((group _unit) getVariable ["onTask", false]) or !alive _unit};
                                    continue;

                                } else {

                                    _unit setDestination [_movePos, "FORMATION PLANNED", false];
                                    _unit doMove _movePos;

                                    _reachable = [_unit, _movePos, 20] call pl_not_reachable_escape;
                                    _unreachableTimeOut = time + 20;
                                    while {(alive _unit) and (alive _target) and !(captive _target) and !(_unit getVariable ["pl_wia", false]) and ((group _unit) getVariable ["onTask", true]) and (_unreachableTimeOut >= time)} do { // and _reachable
                                        // _unit forceSpeed 3;

                                        _unit forceSpeed ([_unit, _target] call pl_get_assault_speed);

                                        if ((_target getVariable ["pl_naded", false]) and alive _target) then {
                                            _target setVariable ["pl_naded", nil];
                                        };

                                        _sleepTime = time + 3;
                                        waitUntil {sleep 0.5; time >= _sleepTime or !(alive _unit) or !((group _unit) getVariable ["onTask", false])};

                                        if (((_unit weaponState 'HandGrenadeMuzzle')#4) > 0) then {
                                            if ((_unit distance2D _target) < 30 and alive _target and !(_target getVariable ["pl_naded", false]) and time > (_target getVariable ["pl_nade_cd", 0])) then {

                                                // player sideChat "Nade";

                                                // _unit forceSpeed 0;
                                                // _unit doTarget _target;

                                                sleep 0.5;

                                                _naded = [_unit, _target] call pl_throw_granade_at_target;
                                                if (_naded) then {
                                                    // player sideChat "Nade2";
                                                    _target setVariable ["pl_naded", true];
                                                };
                                                // _unit forceSpeed -1;
                                            }; 
                                        };
                                    };
                                    if (time >= _unreachableTimeOut) then {
                                        _target enableAI "PATH";
                                        _target doMove ((getPos _target) findEmptyPosition [10, 100, typeOf _target]);
                                    };
                                };

                                if (!(alive _target) or (captive _target)) then {(missionNamespace getVariable format ["targets_%1", _group]) deleteAt ((missionNamespace getVariable format ["targets_%1", _group]) find _target)};
                            };
                        } else {
                            // [_unit, 15, _unit getDir _cords] spawn pl_find_cover;
                            waitUntil {sleep 0.5; ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true]))};
                        };

                        if ((!alive _unit) or (_unit getVariable ["pl_wia", false]) or !((group _unit) getVariable ["onTask", true])) exitWith {};
                    };
                };
            };
            sleep 0.15;
        } forEach (units _group);

        waitUntil {sleep 0.5; (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint) or (time > _taskTime) or !(_group getVariable ["onTask", true]) or ({!alive _x or (captive _x)} count (missionNamespace getVariable format ["targets_%1", _group]) == count (missionNamespace getVariable format ["targets_%1", _group]))};
    };

    missionNamespace setVariable [format ["targets_%1", _group], nil];
    _group setVariable ["pl_is_attacking", false];

    // remove Icon form wp
    // pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    {
        _x setVariable ["pl_damage_reduction", false];
        _x limitSpeed 5000;
        _x forceSpeed -1;
    } forEach (units _group);
    _group setCombatMode "YELLOW";
    _group setVariable ["pl_combat_mode", false];
    _group enableAttack false;
    // sleep 8;
    deleteMarker _markerName;
    deleteMarker _arrowMarkerName;
    deleteMarker _markerPhaselineName;
    pl_draw_text_array = pl_draw_text_array - [["ENY", _leftPos, 0.02, pl_side_color_rgb]];
    pl_draw_text_array = pl_draw_text_array - [["ENY", _rightPos, 0.02, pl_side_color_rgb]];

    pl_draw_text_array = pl_draw_text_array - [["SEIZE", _cords, 0.025, pl_side_color_rgb]]; 

    if (_group getVariable ["onTask", true]) then {
        [_group] call pl_reset;
        sleep 1;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        if (({alive _x and !((lifeState _x) isEqualTo "INCAPACITATED")} count (units _group)) <= _breakingPoint or time > (_taskTime + 1)) then {
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_map_radio) then {[_group, "...Assault failed!", 20] call pl_map_radio_callout};
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault failed", (groupId _group)]};

            // if (_group getVariable ["pl_sop_atk_disenage", false]) then {
                [_group, _startPos, true] spawn pl_disengage;
            // } else {
            //     [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
            // } forEach (units _group);
        } else {
            if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1 Assault complete", (groupId _group)]};
            if (pl_enable_map_radio) then {[_group, "...Assault Complete!", 20] call pl_map_radio_callout};
            [_group, "atk_complete", 1] call pl_voice_radio_answer;
            // {
            //     [_x, getPos (leader _group), 20] spawn pl_find_cover_allways;
            // } forEach (units _group);
            [_group, [], _cords, _startPos getDir _cords, false, false, _area / 2] spawn pl_defend_position;

        };
    };
};