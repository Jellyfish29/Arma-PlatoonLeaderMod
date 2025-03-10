dyn2_opfor_mission_spawner = {
	params ["_locPos", "_missionPos"];

	private _aviableMissionTypes = ["catk", "catk", "catk", "recon", "armor", "convoy"];

	switch (dyn2_missionType) do { 
        case "town_assault" : {};
        case "small_town_assault" : {}; 
        case "field_assault" : {};
        case "air_field_assault" : {_aviableMissionTypes = ["", "air_assault", "recon"]}; 
        default {}; 
    };

	private _missionType = selectRandom _aviableMissionTypes;
	private _success = false; 

	switch (_missionType) do { 
		case "catk" : {_success = [_locPos, _missionPos] call dyn2_OPF_catk};
		case "recon" : {_success = [_locPos, _missionPos] call dyn2_OPF_recon_patrol}; 
		case "armor" : {_success = [_locPos, _missionPos] call dyn2_OPF_armor_attack};
		case "air_assault" : {_success = [_locPos getpos [1000, (getPos player) getDir _locPos], _locPos] call dyn2_OPF_armor_attack};
		case "convoy" : {_succes = [[_locPos getpos [800, _locPos getDir _missionPos], 600] call BIS_fnc_nearestRoad, [_missionPos, 600] call BIS_fnc_nearestRoad, dyn2_standart_trasnport_vehicles, objNull, dyn2_strength + ([1,2] call BIS_fnc_randomInt)] call dyn2_OPF_supply_convoy;};
		case "" : {};
		default {}; 
	};

	_artySuccess = [[3, 6] call BIS_fnc_randomInt, _missionPos] spawn dyn2_OPF_fire_mission;
};

dyn2_OPF_continous_opfor_mission_spawner = {
	params ["_locPos"];

	sleep 60;

	while {true} do {

		sleep ([420, 820] call BIS_fnc_randomInt);

		[_locPos, [] call pl_opfor_get_objective] call dyn2_opfor_mission_spawner;

	};

};

dyn2_OPF_catk = {
	params ["_locPos", "_atkPos", ["_mech", false], ["_exactPos", []]];

	private _atkDir = _locPos getDir _atkPos;
	private _rearPos = _atkPos getPos [[1800, 2600] call BIS_fnc_randomInt, _atkDir - 180];
	private _usedRoads = [];

	if (_exactPos isNotEqualTo []) then {_rearPos = _exactPos};

	for "_i" from 1 to dyn2_strength + 1 do {
		_spawnPos = [[[_rearPos, 200]], [[[allGroups select {(side _x) == playerSide}] call dyn2_find_centroid_of_groups, 1000], "water"]] call BIS_fnc_randomPos;
		// _spawnPos = [[[_rearPos, 200]], ["water"]] call BIS_fnc_randomPos;

		_m = createMarker [str (random 5), _spawnPos];
		_m setMarkerType "mil_objective";


		_grp = [_spawnPos, _atkDir] call dyn2_spawn_squad;
		_grp setBehaviour "SAFE";

		if (((random 1) > 0.5) or _mech) then {
			private _road = [_spawnPos, 800, _usedRoads] call dyn2_nearestRoad;
			_usedRoads pushBack _road;
			private _info = getRoadInfo _road;    
		    private _endings = [_info#6, _info#7];
			_endings = [_endings, [], {_x distance2D _atkPos}, "ASCEND"] call BIS_fnc_sortBy;
		    private _roadDir = (_endings#1) getDir (_endings#0);
		    private _rPos = ASLToATL (_endings#0);

		    _vicR = [_rPos, _roadDir, dyn2_standart_IFV] call dyn2_spawn_vehicle;
		    _vicGrp = _vicR#0;
		    _vic = _vicR#1;
		    {
                _x moveInCargo _vic;
            } forEach (units _grp);
            _grp addVehicle _vic;
            _vic limitSpeed 45;
            _vicGrp addWaypoint [_atkPos, 250];
            _grp enableDynamicSimulation false;
            _vicGrp enableDynamicSimulation false;
            _vicGrp setBehaviour "SAFE";
		} else {
			_grp addWaypoint [_atkPos, 250];
			_grp enableDynamicSimulation false;
		};
	};

	true
};



dyn2_OPF_recon_patrol = {

	params ["_locPos", "_atkPos", ["_exactPos", []]];


	private _atkDir = _locPos getDir _atkPos;
	private _rearPos = _atkPos getPos [[1800, 2600] call BIS_fnc_randomInt, _atkDir - 180];
	if (_exactPos isNotEqualTo []) then {_rearPos = _exactPos};

	for "_i" from 1 to dyn2_strength + 1 + ([0, 1] call BIS_fnc_randomInt) do {
		_spawnPos = [[[_rearPos, 200]], [[[allGroups select {(side _x) == playerSide}] call dyn2_find_centroid_of_groups, 1000], "water"]] call BIS_fnc_randomPos;
		_grp = [_spawnPos, _atkDir, dyn2_standart_recon_team] call dyn2_spawn_squad;

		private _road = [_spawnPos, 800] call dyn2_nearestRoad;
		private _info = getRoadInfo _road;    
	    private _endings = [_info#6, _info#7];
		_endings = [_endings, [], {_x distance2D _atkPos}, "ASCEND"] call BIS_fnc_sortBy;
	    private _roadDir = (_endings#1) getDir (_endings#0);
	    private _rPos = ASLToATL (_endings#0);

	    _vicR = [_rPos, _roadDir, selectRandom dyn2_standart_light_armed_transport] call dyn2_spawn_vehicle;
	    _vicGrp = _vicR#0;
	    _vic = _vicR#1;

	    (leader _grp) moveInAny _vic;
    	{
            _x moveInAny _vic;
        } forEach (units _grp);
        _grp addVehicle _vic;

        {
        	if (vehicle _x == _x) then {deleteVehicle _x};
        } forEach (units _grp);

        _wp = _vicGrp addWaypoint [_atkPos, 40];
        _wp setWaypointType "SAD";
        _vicGrp enableDynamicSimulation false;
            // _vicGrp setBehaviour "SAFE";
		_grp addWaypoint [_atkPos, 40];
		_grp enableDynamicSimulation false;
	};

	true
};

dyn2_OPF_armor_attack = {
	params ["_locPos", "_atkPos", ["_exactPos", []], ["_vicType", dyn2_standart_MBT]];

	private _atkDir = _locPos getDir _atkPos;
	private _rearPos = _atkPos getPos [[2000, 2500] call BIS_fnc_randomInt, _atkDir - 180];
	if (_exactPos isNotEqualTo []) then {_rearPos = _exactPos};

	_spawnPos = [[[_rearPos, 200]], [[[allGroups select {(side _x) == playerSide}] call dyn2_find_centroid_of_groups, 1000], "water"]] call BIS_fnc_randomPos;

	private _road = [_spawnPos, 800] call dyn2_nearestRoad;
	private _info = getRoadInfo _road;    
    private _endings = [_info#6, _info#7];
	_endings = [_endings, [], {_x distance2D _atkPos}, "ASCEND"] call BIS_fnc_sortBy;
    private _roadDir = (_endings#1) getDir (_endings#0);
    private _rPos = ASLToATL (_endings#0);

	_vicR = [_rPos, _roadDir, _vicType] call dyn2_spawn_vehicle; 

	_vicGrp = _vicR#0;
    _vic = _vicR#1;

    _vicGrp addWaypoint [_atkPos, 40];
    _vicGrp enableDynamicSimulation false;

    true

};

dyn2_OPF_heli_insertion = {
	params ["_locPos", "_atkPos"];

	[_locPos, _atkPos] spawn {
		params ["_locPos", "_atkPos"];

		private _approachdir = _locPos getDir _atkPos;
		private _spawnPos = _atkPos getPos [[2500, 3000] call BIS_fnc_randomInt, _approachdir - ([160, 200] call BIS_fnc_randomInt)];

		// private _spawnPos = _atkPos getPos [[1500, 1501] call BIS_fnc_randomInt, _approachdir - ([160, 200] call BIS_fnc_randomInt)];

		for "_i" from 1 to dyn2_strength + 1 + ([0, 1] call BIS_fnc_randomInt) do {

			private _heliGroup = createGroup dyn2_opfor_side;
			_heliGroup setBehaviour "CARELESS";

			_p = [_spawnPos getPos [60 * _i, _approachdir - 180], _approachdir, dyn2_standart_transport_heli, _heliGroup] call BIS_fnc_spawnVehicle;
	    	_heli = _p#0;

	    	[_heli, 120, getPos _heli, "ASL"] call BIS_fnc_setHeight;
		    _heli forceSpeed 300;
		    _heli flyInHeight 70;

		    {
		        _x setSkill 1;
		    } forEach crew (_heli);



	        {
	        	if (vehicle _x == _x) then {deleteVehicle _x};
	        } forEach (units _grp);

		    // _landPos = [_atkPos, 1, 150, 15, 0, 10, 0, [], _atkPos] call BIS_fnc_findSafePos;
		    _sadWp = _heliGroup addWaypoint [_atkPos, 50];
	    	_sadWp setWaypointType "TR UNLOAD";

	    	_heliGroup setBehaviour "CARELESS";


	    	[_heli, _heliGroup, _spawnPos, _atkPos] spawn {
	    		params ["_heli", "_heliGroup", "_spawnPos", "_atkPos"];


	    		waitUntil {sleep 0.5; (_heli distance2D _atkPos ) <= 400 or !alive _heli};

	    		if !(alive _heli) exitWith {};

	    		_grp = [_atkPos, 0] call dyn2_spawn_squad;

			   	(leader _grp) moveInAny _heli;
				{
			        _x moveInAny _heli;
			    } forEach (units _grp);
			    _grp addVehicle _heli;

	    		waitUntil {sleep 1; (isTouchingGround _heli) or !alive _heli};

	    		if (alive _heli) then {
	    			_grp leaveVehicle _heli;
	    		};

	    		_time = time + 60;
	        	waitUntil {sleep 0.5; ({_x in _heli} count (units _grp)) <= 0 or time >= _time or !alive _heli};

	        	if (alive _heli) then {
	        		_heli flyInHeight 100;
			        _heli forceSpeed 300;
			        _evacWp = _heliGroup addWaypoint [_spawnPos, 0];

			        waitUntil {sleep 0.5; (_heli distance2D _spawnPos ) <= 500 or !alive _heli};

			        if ((_heli distance2D _spawnPos ) <= 500) then {
			        	{
				            _heli deleteVehicleCrew _x;
				        } forEach (crew _heli);
				        deleteVehicle _heli;
				        deleteGroup _heliGroup;
			        };
	        	};
	    	};

	    	sleep 4;

		};
	};

	true
	
};

dyn2_OPF_fire_mission = {
	params ["_shells", ["_staticPos", []], ["_smoke", false]];

    if (dyn2_opfor_arty isEqualTo []) exitWith {false};

    [_shells, _staticPos, _smoke] spawn {
    	params ["_shells", "_staticPos", "_smoke"];
    	private ["_eh", "_cords", "_ammoType", "_gunArray"];

	    _gunArray = dyn2_opfor_arty;

	    if (_staticPos isEqualTo []) then {
	        _target = selectRandom (allUnits select {side _x == playerSide});
	        _cords = getPos _target;
	    }
	    else
	    {
	        _cords = _staticPos;
	    };
	    for "_i" from 1 to _shells do {
	        {
	            if (isNull _x) exitWith {};
	            _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
	            if (_smoke) then {
	                _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines") select {["smoke", _x] call BIS_fnc_inString})#0;
	            };
	            if (isNil "_ammoType") exitWith {};
	            _firePos = [[[_cords, 350]], [[position player, 100]]] call BIS_fnc_randomPos;
	            // player sidechat str (_firePos inRangeOfArtillery [[_x], _ammoType]);
	            _x commandArtilleryFire [_firePos, _ammoType, 1];
	            _x setVariable ["dyn_waiting_for_fired", true];
	            _eh = _x addEventHandler ["Fired", {
	                params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	                _unit setVariable ["dyn_waiting_for_fired", false];
	            }];
	            // sleep 1;
	        } forEach _gunArray;
	        sleep 1;
	        _time = time + 10;
	        waitUntil {({_x getVariable ["dyn2_waiting_for_fired", true]} count _gunArray) == 0 or time >= _time};
	        sleep 1;
	    };

	    sleep 20;

	    {
	        _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
	        _x addMagazineTurret [_ammoType, [-1]];
	        if !(isNil "_eh") then {
	            _x removeEventHandler ["Fired", _eh];
	        };
	        _x setVehicleAmmo 1;
	    } forEach _gunArray;
	};
	true
};

dyn2_OPF_supply_convoy = {
	params ["_rearRoad", "_targetRoad", ["_vicTypes", dyn2_standart_trasnport_vehicles], ["_trg", objNull], ["_size", 3]];
	private ["_dir", "_vic", "_grp"];

    private _targetPos = getPos _targetRoad;

    private _supplyGrps = [];
    private _infGrps = [];
    private _road = _rearRoad;
    private _allVics = [];
    private _roadPos = [];
    private _roadBlackList = [];
    private _connected = [];
    for "_i" from 1 to _size do {

        _connected = (roadsConnectedTo [_road, true]);
        {
            if (_x in _roadBlackList) then {_connected deleteAt (_connected find _x)};
        } forEach _connected;

        if ((count _connected) > 0) then {
            _road = ([_connected, [], {(getpos _x) distance2D _targetPos}, "DESCEND"] call BIS_fnc_sortBy)#0;
            _roadBlackList pushBack _road;
        } else {
            _road = _rearRoad;
        };

        _roadPos = getPos _road;

        _info = getRoadInfo _road;    
        _endings = [_info#6, _info#7];
        _endings = [_endings, [], {_x distance2D _targetPos}, "ASCEND"] call BIS_fnc_sortBy;

        _dir = (_endings#1) getDir (_endings#0);
        _vic = createVehicle [selectRandom _vicTypes, _roadPos, [], 0, "CAN_COLLIDE"];
        _grp = createVehicleCrew _vic;
        _vic setDir _dir;
        _allVics pushBack _vic;
        _supplyGrps pushBack _grp;
        _transportCap = getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier");
        if (_transportCap >= 4) then {
            _infGrp = [[0,0,0], east, dyn2_standart_fire_team] call BIS_fnc_spawnGroup;
            _infGrp addVehicle _vic,
            _infGrps pushBack _infGrp;
            {
                _x moveInCargo _vic;
            } forEach (units _infGrp);
            sleep 0.1;
            {
                if (vehicle _x == _x) then {
                    deleteVehicle _x;
                };
            } forEach (units _infGrp);
        };
    };

    [_trg, _supplyGrps, _targetRoad] spawn {
    	params ["_trg", "_supplyGrps", "_targetRoad"];

	    if !(isNull _trg) then {
	    	waitUntil {sleep 1, triggerActivated _trg};
	    };

	    sleep 5;

	    [_supplyGrps, _targetRoad] spawn dyn2_convoy;
	};

	_allVics
};




// [10, getpos player] spawn dyn2_OPF_fire_mission;


// [[400, 400], [2000, 2000]] call dyn2_OPF_heli_insertion;