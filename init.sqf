pl_debug = false;

execVM "Plmod\pl_settings.sqf";
execVM "Plmod\pl_ai_fnc.sqf";
execVM "Plmod\pl_sitrep_fnc.sqf";
execVM "Plmod\pl_attack_fnc.sqf";
execVM "Plmod\pl_rearm_fnc.sqf";
execVM "Plmod\pl_map_icons.sqf";
execVM "Plmod\pl_vehicle_fnc.sqf";
execVM "Plmod\pl_defence_fnc.sqf";
execVM "Plmod\pl_group_fnc.sqf";
execVM "Plmod\pl_heal_fnc.sqf";
execVM "Plmod\pl_misc_fnc.sqf";
execVM "Plmod\pl_support_fnc.sqf";
execVM "Plmod\pl_repair_fnc.sqf";
execVM "Plmod\pl_static_fnc.sqf";
execVM "Plmod\pl_menus_fnc.sqf";
execVM "Plmod\pl_3d_icon_fnc.sqf";
execVM "Plmod\pl_disable_hc_elements.sqf";
execVM "Plmod\pl_mine_fnc.sqf";
execVM "Plmod\pl_util.sqf";
execVM "Plmod\pl_opfor_ai_fnc.sqf";
execVM "Plmod\pl_recon_fnc.sqf";
execVM "Plmod\pl_planning_fnc.sqf";
execVm "Plmod\pl_movement_fnc.sqf";

// execVM "Plmod\pl_marta_overwrite.sqf";

// setGroupIconsVisible [true,true]; 


switch (side player) do { 
    case west : {pl_side_color = "colorBlufor"; pl_side_color_rgb = [0,0.3,0.6,0.8]; pl_side_prefix = "b"; pl_opfor_prefix = "o"}; 
    case east : {pl_side_color = "colorOpfor"; pl_side_color_rgb = [0.5,0,0,0.8]; pl_side_prefix = "o"; pl_opfor_prefix = "b"};
    case resistance : {pl_side_color = "colorIndependent"; pl_side_color_rgb = [0,0.5,0,0.8]; pl_side_prefix = "n"; pl_opfor_prefix = "o"};
    default {pl_side_color = "colorBlufor"; pl_side_color_rgb = [0,0.3,0.6,0.8]; pl_side_prefix = "b"; pl_opfor_prefix = "o"}; 
};


pl_vehicle_group_check = {
    private ["_vicArray"];
    {       
        _vicArray = [];
        {
            if (vehicle _x != _x) then {
                0 = _vicArray pushBackUnique (vehicle _x);
            };
        } forEach (units _x);

        if ((count _vicArray) > 1) exitWith {hint "There are Groups with more then ONE vehicle! Grouped up Vehicles are not recommended to use with High Command as it will lead to uncontrollable and unintended AI behaviour."};

    } forEach (allGroups select {side _x isEqualto playerSide});  
};

// [] call pl_vehicle_group_check;





