// ------------------------------------------------------------
// Pistol guy (with shield)
// ------------------------------------------------------------
class ZombieShield:HDHumanoid{
	//tracking ammo
	int chamber;
	int thismag;
	int firemode; //based on the old pistol method: -1=semi only, 0=semi selected, 1=full auto, 2=revolver

	//specific to shield zombie(formerly undead homeboy)
	int user_weapon; //0 random, 1 semi, 2 auto, 3 revolver

	override void postbeginplay(){
		super.postbeginplay();
		bhasdropped=false;
		A_GiveInventory("HDBallisticShield");
		
		//specific to undead homeboy
		if(user_weapon==0)user_weapon=randompick(1,1,1,2,3,3,3);
		chamber=2;
		switch (user_weapon)
		{
		case 1:
			thismag=random(1,15);
			firemode=-1;
			break;
		case 2:
			thismag=random(1,15);
			firemode=randompick(0,0,0,1);
			break;
		case 3:
			thismag=6;
			firemode=2;
			break;
		}
	}
	virtual bool noammo(){
		return (chamber<1||firemode==2)&&thismag<1;
	}


	/*
	These functions were originally meant to be a prototype for a lot of generalized
	monster attack functions. As of this last review (2021-07) I am abandoning
	that idea since each monster has such specialized attacks that it's better
	to customize each one separately, with a few common specific complex calculations
	like HDMobAI.DropAdjust that are too tedious to repeat.
	*/


	//post-shot checks
	void A_HDMonsterRefire(statelabel jumpto,int chancetocontinue=0){
		if(
			random(1,100)>chancetocontinue
			&&(
				!target
				||!checksight(target)
				||target.health<1
				||absangle(angle,angleto(target))>3
				||!hdmobai.tryshoot(self,flags:hdmobai.TS_GEOMETRYOK)
			)
		)setstatelabel(jumpto);
	}
	
	void A_EjectRevolverCasings(){
		HDWeapon.EjectCasing(self,"HDSpent9mm",
			-frandom(89,92),
			(frandom(-1.0,1.0),frandom(0.5,1.0),frandom(-1,0.5)),
			(10,0,0)
		);
	}

	void A_PistolZombieAttack(){
		if(firemode==2){
			if(thismag<1){
				setstatelabel("postshot");
				return;
			}

			pitch+=frandom(0,spread*0.75)-frandom(0,spread*0.75);
			angle+=frandom(0,spread*0.75)-frandom(0,spread*0.75);
			HDBulletActor.FireBullet(self,"HDB_355",32,-6,spread:2.,speedfactor:frandom(0.99,1.01));
			
			A_StartSound("weapons/deinoclick",8,CHANF_OVERLAP);
			A_StartSound("weapons/deinoblast1",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("weapons/deinoblast1",CHAN_WEAPON,CHANF_OVERLAP,0.5);
			A_StartSound("weapons/deinoblast2",CHAN_WEAPON,CHANF_OVERLAP,0.4);
			pitch+=frandom(-0.8,0.3);
			angle+=frandom(-0.4,0.4);

			thismag--;
		} else {
			if(chamber<2){
				if(chamber>0)A_EjectPistolCasing();
				if(thismag>0){
					chamber=2;
					thismag--;
				}
				setstatelabel("postshot");
				return;
			}

			pitch+=frandom(0,spread)-frandom(0,spread);
			angle+=frandom(0,spread)-frandom(0,spread);
			HDBulletActor.FireBullet(self,"HDB_9",32,-6,spread:6.,speedfactor:frandom(0.97,1.03));

			A_StartSound("weapons/pistol",CHAN_WEAPON);
			pitch+=frandom(-0.8,0.3);
			angle+=frandom(-0.4,0.4);

			A_EjectPistolCasing();
			if(thismag>0)thismag--;
			else chamber=0;
		}
	}
	override void deathdrop(){
		//A_SpawnItemEx("HDBallisticShieldDropped",frandom(-2,2),frandom(-2,2),frandom(0,2), vel.x+frandom(-2,2),vel.y+frandom(-2,2),vel.z+frandom(2,5),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		if(bhasdropped){
			if(firemode==2){
				for (int i=0; i<24; i++)DropNewItem("HDRevolverAmmo",96);
			} else {
				DropNewItem("HD9mMag15",96);
			}
		}else{
			bhasdropped=true;
			if(firemode==2){
				let ppp=DropNewWeapon("HDRevolver");
				if(chamber<2){
					ppp.weaponstatus[BUGS_CYL1]=0;
					ppp.weaponstatus[BUGS_CYL2]=0;
					ppp.weaponstatus[BUGS_CYL3]=0;
					ppp.weaponstatus[BUGS_CYL4]=0;
					ppp.weaponstatus[BUGS_CYL5]=0;
					ppp.weaponstatus[BUGS_CYL6]=0;
				} else {
					ppp.weaponstatus[BUGS_CYL1]=thismag>5?BUGS_MASTERBALL:BUGS_MASTERBALLSPENT;
					ppp.weaponstatus[BUGS_CYL2]=thismag>4?BUGS_MASTERBALL:BUGS_MASTERBALLSPENT;
					ppp.weaponstatus[BUGS_CYL3]=thismag>3?BUGS_MASTERBALL:BUGS_MASTERBALLSPENT;
					ppp.weaponstatus[BUGS_CYL4]=thismag>2?BUGS_MASTERBALL:BUGS_MASTERBALLSPENT;
					ppp.weaponstatus[BUGS_CYL5]=thismag>1?BUGS_MASTERBALL:BUGS_MASTERBALLSPENT;
					ppp.weaponstatus[BUGS_CYL6]=thismag>0?BUGS_MASTERBALL:BUGS_MASTERBALLSPENT;
				}
			} else {
				let ppp=DropNewWeapon("HDPistol");
				ppp.weaponstatus[PISS_MAG]=thismag;
				ppp.weaponstatus[PISS_CHAMBER]=chamber;
				if(firemode>=0){
					ppp.weaponstatus[0]|=PISF_SELECTFIRE;
					if(firemode>0)ppp.weaponstatus[0]|=PISF_FIREMODE;
				}
			}
			
		}
	}
	void A_PistolZombieUnload(int which=0){
		if(firemode==2){
			A_StartSound("weapons/deinoopen",8,CHANF_OVERLAP);
			A_StartSound("weapons/deinoeject",8,CHANF_OVERLAP);
			for (int i=0; i<6; i++)A_EjectRevolverCasings();
			thismag=0;
			chamber=0;
		} else {
			if(thismag>=0){
				HDMagAmmo.SpawnMag(self,"HD9mMag15",thismag);
				A_StartSound("weapons/deinoopen",8);
			}
			thismag=-1;
		}
	}
	bool A_HDReload(int which=0){
		if(firemode==2){
			//if(thismag>=6)return false;
			thismag=6;
			chamber=2;
			A_StartSound("weapons/deinoclose",8,CHANF_OVERLAP);
			A_StartSound("weapons/deinoload",8,CHANF_OVERLAP);
			return true;
		} else {
			if(thismag>=0)return false;
			thismag=15;
			if(chamber<2){
				if(chamber>0)A_EjectPistolCasing();
				chamber=2;
				thismag--;
			}
			A_StartSound("weapons/pismagclick",8);
			return true;
		}
		return false;
	}
	
	override void Tick(){
		super.Tick();
		if(HDMath.IsDead(self)) return;
		if(frame==4||frame==5){
			HDCore.emitLaserParticles(self, bfriendly?0x00FF00:0xFF0000, (-6, 0, 32), 1.0, 1.0);
		}
	}


	//defaults and states
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shield Zombie"
		//$Sprite "CDT1A1"

		+quicktoretaliate
		seesound "grunt/pistol/sight";
		painsound "grunt/pistol/pain";
		deathsound "grunt/pistol/death";
		activesound "grunt/pistol/active";
		tag "$cc_zombie";
		+hdmobbase.noincap;

		radius 10;
		speed 6;
		mass 100;
		mass 160;
		painchance 200;
		obituary "$OB_ZOMBPISTOL";
		hitobituary "$OB_ZOMBPISTOL_HIT";
	}
	states{
	spawn:
		CDT1 E 1{
			A_HDLook();
			A_Recoil(frandom(-0.1,0.1));
		}
		#### EEE random(5,17) A_HDLook();
		#### E 1{
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
		#### B 0 A_JumpIf(noammo(),"reload");
		#### B 0 A_Jump(28,"spawngrunt");
		#### B 0 A_Jump(132,"spawnswitch");
		#### B 8 A_Recoil(frandom(-0.2,0.2));
		loop;
	spawngrunt:
		#### G 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
			if(!random(0,7))A_Vocalize(activesound);
		}
		#### A 0 A_Jump(256,"spawn");
	spawnswitch:
		#### A 0 A_JumpIf(bambush,"spawnstill");
		goto spawnwander;
	spawnstill:
		#### A 0 A_HDLook();
		#### A 0 A_Recoil(random(-1,1)*0.4);
		#### CD 5 A_SetAngle(angle+random(-4,4));
		#### A 0{
			A_HDLook();
			if(!random(0,127))A_Vocalize(activesound);
		}
		#### AB 5 A_SetAngle(angle+random(-4,4));
		#### B 1 A_SetTics(random(10,40));
		#### A 0 A_Jump(256,"spawn");
	spawnwander:
		#### CDAB 5 A_HDWander();
		#### A 0 A_Jump(64,"spawn");
		loop;
	hold:
		#### E 1 A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1),10,0);
		#### E 0 A_JumpIf(noammo(),"reload");
		#### E 1 A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1),10,0);
		#### E 2 A_HDChase("melee","shoot",CHF_NODIRECTIONTURN);
		#### E 1 A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1),10,0);
		#### E 0 A_JumpIf(noammo(),"reload");
		#### EEEE 3 A_Watch(15,"hold","shoot");
	see:
		#### ABCD random(3,4) A_HDChase("melee","missle",CHF_DONTTURN);
		#### ABCD 3 A_TurnToAim(2);
		#### A 0 A_JumpIf(noammo(),"reload");
		#### A 0 A_Jump(116,"roam","roam","roam","roam2","roam2");
		loop;
	roam:
		#### EEEE 3 A_Watch(15);
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_JumpIf(targetinsight||!random(0,31),"see");
		#### ABCD 5 A_Watch(15);//A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(80,"roam");
		loop;

	missile:
		#### ABCD 3 A_TurnToAim(5);
		loop;
	shoot:
		#### E 1 A_SetTics(min(1,int(lasttargetdist)>>5));
		#### E 3 A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1),10,0);
	fire:
		#### F 1 bright light("SHOT") A_PistolZombieAttack();
	postshot:
		#### E 1;
		#### E 0 A_JumpIf(noammo()||!target,"nope");
		#### E 0{
			if(
				firemode>0&&firemode<2
			){
				pitch+=frandom(-2.4,2);
				angle+=frandom(-2,2);
				setstatelabel("fire");
			}else A_SetTics(random(2,7));
		}
		#### E 2;
		#### E 3 A_HDMonsterRefire("hold",25);
		goto fire;
	nope:
		#### E 10;
	reload:
		#### ABCD 4 A_HDChase("melee",null,CHF_FLEE);
		#### A 7 A_PistolZombieUnload();
		#### BC 6 A_HDChase("melee",null,CHF_FLEE);
		#### D 8 A_HDReload();
		---- A 0 setstatelabel("see");
	pain:
		#### G 2;
		#### G 3 A_Vocalize(painsound);
		#### G 0{
			A_ShoutAlert(0.1,SAF_SILENT);
			if(
				floorz==pos.z
				&&target
				&&(
					!random(0,4)
					||distance3d(target)<128
				)
			){
				double ato=angleto(target)+randompick(-90,90);
				vel+=((cos(ato),sin(ato))*speed,1.);
				setstatelabel("missile");
			}
		}
		#### G 0 A_JumpIf(target&&random(0,3),"hold");
		#### ABCD 2 A_HDChase("melee",null,CHF_FLEE|CHF_NODIRECTIONTURN);
		---- A 0 setstatelabel("see");
	falldown:
		#### G 5;
		#### H 5 A_Vocalize(deathsound);
		#### IIJJJ 2 A_SetSize(-1,max(deathheight,height-10));
		#### K 0 A_SetSize(-1,deathheight);
		#### K 10 A_KnockedDown();
		wait;
	standup:
		#### K 6;
		#### J 0 A_Jump(160,2);
		#### J 0 A_Vocalize(seesound);
		#### JI 4 A_Recoil(-0.3);
		#### HE 6;
		#### A 0 setstatelabel("see");
	death:
		#### H 5 A_SpawnItemEx("HDBallisticShieldDropped",frandom(-2,2),frandom(-2,2),frandom(0,2), vel.x+frandom(-2,2),vel.y+frandom(-2,2),vel.z+frandom(2,5),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		#### I 5 A_Vocalize(deathsound);
		#### J 5 A_NoBlocking();
		#### K 5;
	dead:
		#### J 3 {if(abs(vel.z)<2.)frame++;}
		#### K 5 {if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	gib:
		#### M 5;
		#### N 5{
			A_GibSplatter();
			A_XScream();
		}
		#### O 0 A_NoBlocking();
		#### OP 5 A_GibSplatter();
		#### QRS 5;
		#### A 0 A_Jump(256,"gibbed");
	gibbed:
		#### R 3 {if(abs(vel.z)<2.)frame++;}
		#### S 5  A_JumpIf(abs(vel.z)>=2.,"gibbed");
		wait;
	raise:
		#### K 4;
		#### K 6;
		#### JIH 4;
		#### A 0 A_Jump(256,"see");
	ungib:
		#### S 12;
		#### S 8;
		#### SRQ 6;
		#### PONM 4;
		#### A 0 A_Jump(256,"pain");
 	}
}




