#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <cwapi>

new const ABILITY_NAME[] = "ThrowKnife";
new const KNIFE_CLASSNAME[] = "ThrowKnife";
new const KNIFE_MODEL[] = "models/cwapi/a/throw-knife/knife.mdl";
new KNIFE_MODEL_INDEX;
new const HIT_SOUND[] = "weapons/knife_hit1.wav";
new const HITWALL_SOUND[] = "weapons/knife_hitwall1.wav";
#define KNIFE_STUCKED_TIME 1.5

public CWAPI_OnLoad() {
    register_plugin("[CWAPI-A] Throw Knife", "1.0.0", "ArKaNeMaN");
    
    new T_WeaponAbility:iAbility = CWAPI_Abilities_Register(ABILITY_NAME);
    CWAPI_Abilities_AddParams(iAbility,
        "Damage", "Float", false,
        "Velocity", "Float", false,
        "Gravity", "Float", false
    );
    CWAPI_Abilities_AddEventListener(iAbility, CWeapon_OnPrimaryAttackPost, "@OnPrimaryAttackPost");
}

public plugin_precache() {
    KNIFE_MODEL_INDEX = precache_model(KNIFE_MODEL);
    precache_sound(HIT_SOUND);
    precache_sound(HITWALL_SOUND);
}

@OnPrimaryAttackPost(const T_CustomWeapon:iWeapon, const ItemId, const Trie:tAbilityParams) {
    new UserId = get_member(ItemId, m_pPlayer);

    new Float:fDamage = 45.0;
    TrieGetCell(tAbilityParams, "Damage", fDamage);

    new Float:fVelocity = 1000.0;
    TrieGetCell(tAbilityParams, "Velocity", fVelocity);

    new Float:fGravity = 0.1;
    TrieGetCell(tAbilityParams, "Gravity", fGravity);

    ThrowKnife(UserId, fDamage, fVelocity, fGravity);
}

ThrowKnife(
    const FromEntId,
    const Float:fDamage = 45.0,
    const Float:fVelocity = 1000.0,
    const Float:fGravity = 0.1
) {
    new EntId = rg_create_entity("info_target");
    set_entvar(EntId, var_classname, KNIFE_CLASSNAME);
    set_entvar(EntId, var_modelindex, KNIFE_MODEL_INDEX);
    set_entvar(EntId, var_model, KNIFE_MODEL);

    new Float:Vec[3], Float:Vec2[3];

    get_entvar(FromEntId, var_v_angle, Vec);
    angle_vector(Vec, ANGLEVECTOR_FORWARD, Vec2);
    Vec[1]+= 180.0;
    set_entvar(EntId, var_angles, Vec);
    
    xs_vec_mul_scalar(Vec2, fVelocity, Vec2);
    set_entvar(EntId, var_velocity, Vec2);

    Vec[0] = GetAngleVel(13.5, fVelocity) / 1.5;
    Vec[1] = 0.0;
    Vec[2] = 0.0;
    set_entvar(EntId, var_avelocity, Vec);

    get_entvar(FromEntId, var_origin, Vec);
    get_entvar(FromEntId, var_view_ofs, Vec2);
    xs_vec_add(Vec, Vec2, Vec)
    set_entvar(EntId, var_origin, Vec);
    
    set_entvar(EntId, var_movetype, MOVETYPE_TOSS);
    set_entvar(EntId, var_solid, SOLID_TRIGGER);
    set_entvar(EntId, var_gravity, fGravity);
    set_entvar(EntId, var_sequence, 0);
    set_entvar(EntId, var_framerate, 1.0);

    set_entvar(EntId, var_owner, FromEntId);
    set_entvar(EntId, var_dmg, fDamage);
    SetEntSize(EntId, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
    set_entvar(EntId, var_nextthink, get_gametime() + 0.1);

    SetTouch(EntId, "@OnKnifeTouch");
}

@OnKnifeTouch(const EntId, const UserId) {
    new OwnerId = get_entvar(EntId, var_owner);
    if (UserId == OwnerId) {
        return;
    }

    SetTouch(EntId, "");
    SetThink(EntId, "@OnKnifeThink");

    if (!FClassnameIs(UserId, "player")) {
        set_entvar(EntId, var_solid, SOLID_NOT);
        set_entvar(EntId, var_movetype, MOVETYPE_NONE);
        set_entvar(EntId, var_nextthink, get_gametime() + KNIFE_STUCKED_TIME);
        set_entvar(EntId, var_velocity, Float:{0.0, 0.0, 0.0});
        set_entvar(EntId, var_avelocity, Float:{0.0, 0.0, 0.0});


        rh_emit_sound2(EntId, 0, CHAN_AUTO, HITWALL_SOUND, 0.3);
        return;
    }
    set_entvar(EntId, var_nextthink, get_gametime() + 0.01);

    if (!is_user_alive(UserId)) {
        return;
    }

    if (rg_is_player_can_takedamage(UserId, OwnerId)) {
        ExecuteHamB(Ham_TakeDamage, UserId, EntId, OwnerId, get_entvar(EntId, var_dmg), DMG_SLASH|DMG_NEVERGIB);
        rh_emit_sound2(UserId, 0, CHAN_VOICE, HIT_SOUND, 0.3);
    }
}

@OnKnifeThink(const EntId) {
    set_entvar(EntId, var_flags, FL_KILLME);
}

SetEntSize(const EntId, const Float:Mins[3], const Float:Maxs[3]) {
    set_entvar(EntId, var_mins, Mins);
    set_entvar(EntId, var_maxs, Maxs);

    new Float:Size[3];
    xs_vec_add(Mins, Maxs, Size);
    set_entvar(EntId, var_size, Size);
}

Float:GetAngleVel(const Float:D, const Float:V){
    return (360 * V) / (M_PI * D);
}