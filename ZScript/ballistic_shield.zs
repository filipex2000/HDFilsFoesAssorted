// ------------------------------------------------------------
// Jorkinit
// ------------------------------------------------------------
const BALSHIELD_ABSORBTION=20.;
const BALSHIELD_PENETRATRION_THRESHOLD=20.;
class HDBallisticShield:HDDamageHandler{
	default{
		+nointeraction +noblockmap
		+inventory.keepdepleted

		inventory.amount 1;
		inventory.maxamount 1;
		inventory.icon "BON2A0";

		stamina 0;  //repeated hits counter (within small time frame)

		HDDamageHandler.priority 9999;
		+hdpickup.fullcoverage
		Tag "$TAG_HDMAGICSHIELD";
	}

	override double getbulk(){return bulk;}
	override void AttachToOwner(actor other){
		super.AttachToOwner(other);
// 		if(hdmobbase(other)){
// 			int mmm=hdmobbase(other).maxshields;
// 			if(mmm>0){
// 				maxamount=mmm;
// 				amount=mmm;
// 				buntossable=true;
// 			}
// 		}
	}
	override inventory CreateTossable(int amt){
		if(bulk>0)return super.createtossable(amt);
		return null;
	}
	override void OnDrop(actor dropper){
		super.OnDrop(dropper);
		if(self)destroy();
	}
	override void DoEffect(){
		if(
			HDMath.IsDead(owner)
			||owner.isfrozen()
		)return;
		
		if(stamina>0)stamina--;
	}
	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,double,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound,
		int toburn,
		int tostun,
		int tobreak
	){
		actor victim=owner;
		if(
			!victim
			||(flags&(DMG_NO_FACTOR|DMG_FORCED))
			||!inflictor
			||(inflictor==victim)
//			||(inflictor is "HDBulletActor")
			||mod=="bleedout"
			||mod=="hot"
			||mod=="cold"
			||mod=="maxhpdrain"
			||mod=="internal"
			||mod=="holy"
			||mod=="jointlock"
			||mod=="staples"
		)return damage,mod,flags,towound,toburn,tostun,tobreak;
		
		if(
			HDMath.IsDead(owner)
			||owner.isfrozen()
		)return damage,mod,flags,towound,toburn,tostun,tobreak;
		
		//which is just a shield not a bubble...
		if(
			inflictor
			&&inflictor.default.bmissile
		){
			double impactheight=inflictor.pos.z+inflictor.height*0.5;
			double shoulderheight=victim.pos.z+victim.height-16;
			double waistheight=victim.pos.z+victim.height*0.4;
			double impactangle=absangle(victim.angle,victim.angleto(inflictor));
			//if(impactangle>90)impactangle=180-impactangle;
			bool shouldhitflesh=(
				impactheight>shoulderheight
				||impactheight<waistheight
				||impactangle>80
			)?!random(0,5):!random(0,31);
			if(shouldhitflesh||impactangle>80)return damage,mod,flags,towound,toburn,tostun,tobreak;
		}
		
		//if incap'd, bypass armour
		let hdp=HDPlayerPawn(victim);
		let hdmb=HDMobBase(victim);
		if(
			(
				(hdp&&hdp.incapacitated)
				||(
					hdmb
					&&hdmb.frame>=hdmb.downedframe
					&&hdmb.instatesequence(hdmb.curstate,hdmb.resolvestate("falldown"))
				)
			)
			&&!!inflictor.target
		)return damage,mod,flags,towound,toburn,tostun,tobreak;
		
		//if(!stamina)stamina=maxamount;

		int blocked=min(damage,BALSHIELD_ABSORBTION);
		damage-=blocked;

		//HDMagicShield.Deplete(victim,max(supereffective?(blocked<<2):blocked,1),self);

		
		console.printf("BLOCKED (not bullet)  "..blocked.."    OF  "..damage+blocked);


		//spawn shield debris
		vector3 sparkpos;
		if(
			inflictor
			&&inflictor!=source
		)sparkpos=inflictor.pos;
		else if(
			source
		)sparkpos=(
			victim.pos.xy+victim.radius*(source.pos.xy-victim.pos.xy).unit()
			,victim.pos.z+min(victim.height,source.height*0.6)
		);
		else sparkpos=(victim.pos.xy,victim.pos.z+victim.height*0.6);

		int shrd=max(1,blocked>>6);
		for(int i=0;i<shrd;i++){
			actor aaa=victim.spawn("WallChunk",sparkpos,ALLOW_REPLACE);
			aaa.vel=(frandom(-3,3),frandom(-3,3),frandom(-3,3));
		}
		victim.spawn("HDPuff",sparkpos,ALLOW_REPLACE);
		victim.spawn("HugeWallChunk",sparkpos,ALLOW_REPLACE);

		//chance to flinch
		if(damage<1){
			if(
				!(flags&DMG_NO_PAIN)
				&&blocked>(victim.spawnhealth()>>3)
				&&random(0,510)<victim.painchance
			)hdmobbase.forcepain(victim);
		}

		return damage,mod,flags,towound,toburn,tostun,tobreak;
	}

	//called from HDBulletActor's OnHitActor
	override double,double OnBulletImpact(
		HDBulletActor bullet,
		double pen,
		double penshell,
		double hitangle,
		double deemedwidth,
		vector3 hitpos,
		vector3 vu,
		bool hitactoristall
	){
		actor victim=owner;
		if(
			!victim
			||!bullet
			||amount<1
		)return pen,penshell;
		
		if(
			HDMath.IsDead(owner)
			||owner.isfrozen()
		)return pen,penshell;
		
		if(!owner)return 0,0;
		let hdp=HDPlayerPawn(victim);
		let hdmb=HDMobBase(victim);

		//if incap'd, bypass armour
		if(
			(
				(hdp&&hdp.incapacitated)
				||(
					hdmb
					&&hdmb.frame>=hdmb.downedframe
					&&hdmb.instatesequence(hdmb.curstate,hdmb.resolvestate("falldown"))
				)
			)
			&&!!bullet.target
		)return pen,penshell;
		
		//which is just a shield not a bubble...
		if(!!bullet.target){
			double impactangle=absangle(victim.angle,victim.angleto(bullet.target));
			if(impactangle>80)return pen,penshell;
		}
		
		if(victim is "HDActor"){
			double hitheight=hitactoristall?((hitpos.z-victim.pos.z)/victim.height):0.5;
			if(hitheight>0.8){
				return pen,penshell;
			}
		}
		
		double bulletpower=pen*bullet.mass*0.1;
		if(bulletpower<1){
			if(frandom(0,1)<bulletpower)bulletpower=1;
			else bulletpower=0;
		}
		vector3 hitposfx = hitpos - (bullet.vel.unit() * 0.1);
		spawn("HDPuff",hitposfx,ALLOW_REPLACE);
		spawn("HugeWallChunk",hitposfx,ALLOW_REPLACE);
		if(pen>BALSHIELD_PENETRATRION_THRESHOLD){
			// Shield has been penetrated
			A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.6);
			victim.A_StartSound("balshield/hit",CHAN_BODY,CHANF_OVERLAP,0.25);
		} else {
			victim.A_StartSound("balshield/hit",CHAN_BODY,CHANF_OVERLAP,1.5,ATTN_NORM,frandom(0.9,1.1),stamina*0.01);
			// Shield has reflected the bullet
			pen-=min(BALSHIELD_PENETRATRION_THRESHOLD,pen);
			penshell+=BALSHIELD_PENETRATRION_THRESHOLD;
			HDBulletActor.FireBullet(victim,"HDB_scrap",zofs:(hitpos.z-victim.pos.z),spread:60.,aimoffx:hitangle,aimoffy:hitangle,speedfactor:frandom(0.1,0.3));
			victim.vel+=(
				((victim.pos.xy,victim.pos.z+victim.height*0.5)-bullet.pos).unit()
				*bulletpower
				/victim.mass
			);
			victim.angle+=deltaangle(victim.angle,victim.angleto(bullet))*frandom(-0.005,0.03)+frandom(-0.1,0.1);
			victim.pitch+=frandom(-1.,1.);
		}
		stamina+=2;
		return pen,penshell;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	use:
		TNT1 A 0{
			if(invoker.accuracy>70){
				A_DropInventory(invoker.getclassname());
			}else{
				if(!invoker.accuracy){
					if(
						invoker.amount<invoker.maxamount
						&&invoker.mass>0
					)A_Log(
						"WARNING: shield is not done charging! Aborting now will permanently degrade performance. Double-tap Use to proceed anyway."
					,true);
				}
				invoker.accuracy=80;
			}
		}fail;
	}
}


//standalone puff that replaces blood
// class ShieldSpark:IdleDummy{
// 	default{
// 		+forcexybillboard +rollsprite +rollcenter
// 		renderstyle "add";
// 	}
// 	override void postbeginplay(){
// 		super.postbeginplay();
// 		scale*=frandom(0.2,0.5);
// 		roll=frandom(0,360);
// 	}
// 	states{
// 	spawn:
// 		TFOG ABCDEFGHIJ 3 bright A_FadeOut(0.08);
// 		stop;
// 	}
// }

//dummy item when you don't want anything coming out for blood or puffs
// class NullPuff:Actor{
// 	default{+nointeraction}
// 	states{spawn:TNT1 A 0;stop;}
// }

// class SpentShield:HDDebris{
// 	default{
// 		scale 0.3;height 3;radius 3;
// 		bouncesound "misc/fragknock";
// 	}
// 	states{
// 	spawn:
// 		BON2 A 0 nodelay{
// 			if(!HDMath.PlayingId())A_SetTranslation("DesaturatedReddish");
// 		}
// 	spawn2:
// 		---- A 1{
// 			A_SetRoll(roll+60,SPF_INTERPOLATE);
// 		}wait;
// 	death:
// 		---- A -1;
// 		stop;
// 	}
// }

class HDBallisticShieldDropped:HDDebris{
	default{
		scale 0.9;height 3;radius 4;
		bouncesound "misc/fragknock";
	}
	states{
	spawn:
		SDT1 A 0 nodelay{
			//if(!HDMath.PlayingId())A_SetTranslation("DesaturatedReddish");
		}
	spawn2:
		#### ABCDEFGH 2{
			A_SetRoll(roll+60,SPF_INTERPOLATE);
		}wait;
	death:
		#### I -1{
			A_SetRoll(0);
		}
		stop;
	}
}
