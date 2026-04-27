// ------------------------------------------------------------
// Former Human (with backpack)
// ------------------------------------------------------------

class ZombieLooter:ZombieStormtrooper{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman Looter"
		//$Sprite "POSSA1"

		+floorclip
		+quicktoretaliate
		seesound "grunt/sight";
		painsound "grunt/pain";
		deathsound "grunt/death";
		activesound "grunt/active";
		tag "Zoombie Looter";

		translation 1;
		speed 7;
		health 110;
		mass 160;
		dropitem "";attacksound "";decal "BulletScratch";
		painchance 240;
		obituary "$OB_ZOMBRIFLE";
		hitobituary "$OB_ZOMBRIFLE_HIT";
		accuracy 0;
	}
	bool hasderp;
	bool hasstim;
	int grenades;
	override void beginplay(){
		super.beginplay();
		hasderp=true;
		grenades=random(1,3);
		hasstim=true;
	}
	override void postbeginplay(){
		super.postbeginplay();
		givearmour(1.,0.06,-0.4);
	}
	override void deathdrop(){
		if(bhasdropped&&bfriendly)return;
		if(!bhasdropped){
			if(HDCore.CheckClassExists("UaS_AmmoPouch"))
			{
				if(random(0,2)) DropNewItem("WildBackpack");
				else DropNewItem("UaS_WildAmmoPouch");
			} else {
				DropNewItem("WildBackpack");
			}
		}
		super.deathdrop();
	}
	void A_UpdateSprite(){
		sprite=getspriteindex("CDT5");
	}
	void A_ZomDERP(){
		if(!hasderp)return;
		hasderp=false;
		A_StartSound("weapons/pismagclick",CHAN_WEAPON);
		bool garbage;actor gg;
		double cpp=cos(pitch);double spp=sin(pitch);
		double gforce=frandom(5,15);
		[garbage,gg]=A_SpawnItemEx("EnemyDERP",
			0,0,height-6,
			cpp*gforce,0,-spp*gforce,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|
			SXF_SETMASTER|SXF_TRANSFERTRANSLATION|SXF_SETTARGET
		);
		gg.vel+=self.vel;
		DERPBot derp=DERPBot(gg);
		derp.movestamina=0;
	}
	void A_ZomStim(){
		if(!hasstim)return;
		hasstim=false;
		A_StartSound("misc/injection",CHAN_WEAPON,CHANF_OVERLAP);
		GiveBody(-100);
		actor aa=spawn("SpentStim",pos,ALLOW_REPLACE);
		if(!!aa){
			aa.target=target;aa.angle=angle;aa.pitch=pitch;aa.vel=vel;
			aa.A_StartSound("misc/stimdrop",CHAN_VOICE);
		}
	}
	states{
		spawn:
			CDT5 Z 0;
			CDT5 Z 0 A_UpdateSprite();
		idle:
			#### Z 0;
		spawn2:
			#### Z 0{
				A_HDLook();
				A_Recoil(frandom(-0.1,0.1));
			}
			#### Z 1{
				A_SetTics(random(5,17));
				A_HDLook();
			}
			#### Z 1{
				A_Recoil(frandom(-0.1,0.1));
				A_SetTics(random(10,40));
			}
			#### B 0 A_Jump(28,"spawngrunt");
			#### B 0 A_Jump(132,"spawnswitch");
			#### Z 8 A_Recoil(frandom(-0.2,0.2));
			loop;
		pain:
			#### G 2;
			#### G 3 A_Vocalize(painsound);
			#### G 0{
				A_ShoutAlert(0.1,SAF_SILENT);
				if(hasstim&&health<75&&random(0,6))setstatelabel("stim");
				else if(target&&distance3d(target)<100)setstatelabel("see");
			}
			#### ABCD 2 A_HDChase(flags:CHF_FLEE);
			---- A 0 setstatelabel("see");
		stim:
			#### G 5;
			#### B 6 A_StartSound("misc/injection",CHAN_WEAPON,CHANF_OVERLAP);
			#### G 3 A_Vocalize(painsound);
			#### G 0{
				A_ShoutAlert(0.1,SAF_SILENT);
				A_ZomStim();
			}
			---- A 0 setstatelabel("see");
		aiming:
			#### E 3{
				//A_HDChase(null,null,CHF_NODIRECTIONTURN,0.6);
				A_FaceLastTargetPos(30);
			}
			#### E 1 A_StartAim(maxspread:20,maxtics:random(0,35));
			#### E 0 A_JumpIf(
				random(0,2)
				||hdmobai.TryShoot(self,32,512,0,0,flags:HDMobAI.TS_GEOMETRYOK)
			,"shoot");
			goto see;
		postshot:
			#### E 5{
				if(!random(0,127))A_Vocalize(activesound);
				if(mag<1){
					setstatelabel("reload");
					return;
				}
				spread=max(0,spread-1);
				A_SetTics(random(3,6));
				A_HDChase(null,null,CHF_WANDER|CHF_NODIRECTIONTURN,3.0);
				threat=target;
			}
			#### E 3 A_HDChase(null,null,CHF_WANDER|CHF_NODIRECTIONTURN,3.0);
			#### E 0{
				if(!hdmobai.tryshoot(self))
				{
					if(random(0,2))setstatelabel("see");
					else setstatelabel("missile");
				}
			}
			#### E 0 A_JumpIfTargetInLOS(1);
			goto coverfire;  //even if not in los,occasionally keep shooting anyway
			#### E 3 A_FaceTarget(10,10);
			#### E 0 A_Jump(30,"see");  //even if in los,occasionally stop shooting anyway
			goto coverfire;
		missile:
			#### A 0{
				if(!target){
					setstatelabel("spawn2");
					return;
				}
				// Higher chance for a grenade throw, these guys are looters after all!
				double dt=distance3d(target);
				if(
					grenades>0
					&&!random(0,7)
					&&dt>200
					&&dt<1000
				)
				{
					// Throw DERP at random if we haven't already
					if(random(0,3)&&hasderp) setstatelabel("derp");
					else if(grenades) setstatelabel("frag");
				}
			}
			#### ABCD 3 A_TurnToAim(40,shootstate:"aiming");
			loop;
		frag:
			#### A 10 A_Vocalize(seesound);
			#### Z 20{
				A_StartSound("weapons/pocket",CHAN_WEAPON);
				A_FaceTarget(0,0);
				pitch-=frandom(20,40);
			}
			#### A 10{
				A_ZomFrag();
				grenades--;
			}
			---- A 0 A_JumpIf(mag<1,"reload");
			---- A 0 setstatelabel("see");
		derp:
			#### A 10 A_Vocalize(seesound);
			#### Z 20{
				A_StartSound("weapons/pocket",CHAN_WEAPON);
				A_FaceTarget(0,0);
				pitch-=frandom(20,40);
			}
			#### A 4{
				A_Vocalize(seesound);
				A_StartSound("weapons/pismagclick",CHAN_WEAPON);
			}
			---- A 6{
				A_StartSound("derp/crawl",CHAN_WEAPON,CHANF_OVERLAP);
			}
			---- A 10{
				A_ZomDERP();
			}
			---- A 0 A_JumpIf(mag<1,"reload");
			---- A 0 setstatelabel("see");
	}
}


class ZombieAutoLooter:ZombieLooter{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (ZM66)"
		//$Sprite "POSSA1"
		accuracy 1;
}}
class ZombieSemiLooter:ZombieLooter{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (ZM66 Semi)"
		//$Sprite "POSSA1"
		accuracy 2;
}}

class ZombieHideousLooter:RandomSpawner{
	default{
		dropitem "ZombieAutoLooter",256,100;
		dropitem "ZombieSemiLooter",256,20;
	}
}


