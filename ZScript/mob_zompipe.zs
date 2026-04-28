// ------------------------------------------------------------
// TNT Throwing Tyrant (TTT) (Pipebomb Man)
// ------------------------------------------------------------

class ZombiePipoBoom:HDHumanoid{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieboomman"
		//$Sprite "CDU5A1"

		+floorclip
		//+nofear
		damagefactor "hot",0.9;
		damagefactor "cheappipeblast",0.01;
		damagefactor "bashing",0.9;
		seesound "grunt/sight";
		painsound "grunt/pain";
		deathsound "grunt/death";
		activesound "grunt/active";
		tag "Pipebomb Zombie";

		translation "58:66=128:136","214:223=141:148","176:191=24:47","16:34=68:79";
		speed 10;
		health 200;
		dropitem "";attacksound "";decal "BulletScratch";
		painchance 200;
		obituary "$OB_ZOMBRIFLE";
		hitobituary "$OB_ZOMBRIFLE_HIT";
		accuracy 0;
	}
	int mag;
	double turnamount;
	override void postbeginplay(){
		super.postbeginplay();
		mag=random(1,15);
		givearmour(1.,0.06,-0.4);
	}
	//returns true if area around target is clear of friendlies
	bool A_CheckBlast(actor tgt=null,double checkradius=256){
		if(!tgt)tgt=target;
		if(!tgt)return true;
		blockthingsiterator itt=blockthingsiterator.create(tgt,checkradius);
		while(itt.next()){
			actor it=itt.thing;
			if(
				it.health>0&&
				(isfriend(it)||isteammate(it))
			)return false;
		}
		return true;
	}
	void A_ZomPipebomb(){
		double dt=distance3d(target);
		double dtfactor=dt/512.0;
		bool garbage;actor gg;
		double cpp=cos(pitch);double spp=sin(pitch);
		double gforce=frandom(15,35)*dtfactor;
		[garbage,gg]=A_SpawnItemEx("HDPipebomb",
			0,0,height-6,
			cpp*gforce,0,-spp*gforce/(0.5+dtfactor),
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		gg.vel+=self.vel;
	}
	override void deathdrop(){
		if(bhasdropped&&bfriendly)return;
		hdweapon wp=null;
		if(!bhasdropped){
			if(wp=DropNewWeapon("HDPistol")){
				wp.weaponstatus[PISS_MAG]=mag;
				wp.weaponstatus[PISS_CHAMBER]=2;
			}
			DropNewItem("HDHandgunRandomDrop");
			DropNewItem("PipebombPickup",100);
			DropNewItem("HDPipebombAmmo",100);
			DropNewItem("HDPipebombAmmo",100);
			DropNewItem("HDPipebombAmmo",100);
			
			// Chance to drop live bomb!
			if(random(0,2)){
				bool garbage;actor gg;
				[garbage,gg]=A_SpawnItemEx("HDPipebomb",
					0,0,height-6,
					frandom(-1,1),frandom(-1,1),2,
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				gg.vel+=self.vel;
			}
			
			bhasdropped=true;
		}
	}
	void A_UpdateSprite(bool roll=false){
		if(roll) sprite=getspriteindex("DDU5");
		else sprite=getspriteindex("CDU5");
	}
	states{
	spawn:
		DDU5 A 0;
		CDU5 A 0 A_UpdateSprite();
	idle:
	spawn2:
		#### A 0{
			A_HDLook();
			A_Recoil(frandom(-0.1,0.1));
		}
		#### EEE 1{
			A_SetTics(random(5,17));
			A_HDLook();
		}
		#### E 1{
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
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
		#### A 0 A_Jump(256,"spawn2");
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
		#### A 0 A_Jump(256,"spawn2");
	spawnwander:
		#### CDAB 5 A_HDWander();
		#### A 0{
			if(!random(0,127))A_Vocalize(activesound);
			A_HDLook();
		}
		#### A 0 A_Jump(64,"spawn2");
		loop;
	missile:
		#### A 0{
			if(!target){
				setstatelabel("spawn2");
				return;
			}
		}
		#### ABCD 1 A_TurnToAim(40,shootstate:"aiming");
		loop;
	aiming:
		#### # 0  A_UpdateSprite(false);
		#### E 1 A_FaceLastTargetPos(30);
		#### E 1 A_StartAim(maxspread:30,maxtics:random(0,10));
		#### E 0 A_JumpIf(
			(!random(0,3)&&hdmobai.TryShoot(self,32,512,0,0,flags:HDMobAI.TS_GEOMETRYOK))
		,"roll.start");
		#### E 0 A_JumpIf(random(0,3)&&distance3d(target)>128&&A_CheckBlast()
		,"frag");
		#### F 6 A_UpdateSprite(true);
		goto shoot;
	shoot:
		#### F 0 A_UpdateSprite(true);
		#### F 2 A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1),10,2);
		#### F 0{
			pitch+=frandom(-spread,spread);
			angle+=frandom(-spread,spread);
		}
	fire:
		#### F 0 A_UpdateSprite(true);
		#### F 2 bright light("SHOT"){
			if(mag<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			A_StartSound("weapons/pistol",CHAN_WEAPON,1.2);
			HDBulletActor.FireBullet(self,"HDB_9",28,speedfactor:1.0);
			A_EjectSMGCasing();
			pitch+=frandom(-0.1,0.05)*spread;
			angle+=frandom(-0.1,0.05)*spread;
			mag--;
		}
		#### F 2{
			if(mag<1||!hdmobai.tryshoot(self)){
				setstatelabel("postshot");
			} else spread++;
		}
		#### F 0 A_Jump(120,"shoot");
		//fallthrough to postshot
	postshot:
		#### F 5{
			if(!random(0,127))A_Vocalize(activesound);
			if(mag<1){
				setstatelabel("reload");
				return;
			}
			spread=max(0,spread-1);
			A_SetTics(random(2,6));
		}
		#### F 3 A_Jump(56,"roll.forward");
		#### F 0 A_JumpIf(!hdmobai.tryshoot(self),"see");
		#### F 0 A_JumpIfTargetInLOS(1);
		goto coverfire;  //even if not in los,occasionally keep shooting anyway
		#### F 3 A_FaceTarget(10,10);
		#### F 0 A_Jump(30,"see");  //even if in los,occasionally stop shooting anyway
		goto coverfire;
	coverfire:
		#### F 0 A_UpdateSprite(true);
		#### F 1{
			spread=2;
			A_Coverfire();
			A_SetTics(random(2,6));
		}
		wait;
	frag:
		#### # 0 A_UpdateSprite(false);
		#### F 4 A_Vocalize(seesound);
		#### E 4{
			A_StartSound("weapons/pocket",CHAN_WEAPON);
			A_FaceTarget(0,0);
			pitch-=frandom(15,35);
		}
		#### F 2{
			A_StartSound("weapons/pocket",CHAN_WEAPON);
		}
		#### G 1 A_StartSound("misc/fwoosh",CHAN_WEAPON,CHANF_OVERLAP,1.1);
		#### G 4{
			A_ZomPipebomb();
		}
		#### G 5 A_Jump(200,"roll.start");
		#### G 0 A_JumpIf(hdmobai.TryShoot(self,32,512,0,0,flags:HDMobAI.TS_GEOMETRYOK), "shoot");
		---- A 0 setstatelabel("see");
	ohforfuckssake:
		#### E 8 A_UpdateSprite();
	reload:
		#### A 0 A_UpdateSprite();
		---- A 0 A_JumpIf(mag<0,"unloadedreload");
		---- A 4 A_StartSound("weapons/pismagclick2");
		#### AA 1 A_HDChase("melee",null,flags:CHF_FLEE);
		#### A 0{
			HDMagAmmo.SpawnMag(self,"HD9mMag15",mag);
			A_StartSound("weapons/pismagclick2",8);
			mag=-1;
		}
	unloadedreload:
		#### # 0 A_UpdateSprite();
		#### BCD 2 A_HDChase("melee",null,flags:CHF_FLEE);
		#### E 12 A_StartSound("weapons/pocket",8);
		#### E 8 A_StartSound("weapons/pismagclick2",9);
		#### E 2{
			A_StartSound("weapons/pismagclick",8);
			mag=15;
		}
		#### CCBB 2 A_HDWander();
	see:
		#### # 0 A_UpdateSprite(false);
		#### A 0 A_Jump(13,"roll.start");
	see2:
		#### ABCD 4 A_HDChase();
		#### A 0{
			spread=2;
		}
		#### A 0 A_JumpIfTargetInLOS("see");
		#### A 0 A_Jump(24,"roam");
		loop;
	roam:
		#### AABBCCDD 3 A_HDChase(flags:CHF_LOOK,speedmult:0.3);
		#### E 0 A_Jump(128,"roam");
		---- A 0 setstatelabel("roam2");
	roam2:
		#### A 0 A_JumpIf(threat,"see");
		#### A 0{
			angle+=DecideOnHandedness(-frandom(30,50));
			A_HDLook();
		}
		#### EEEE 3 A_Watch();
		#### A 0 A_JumpIf(threat,"see");
		#### A 0{
			angle+=DecideOnHandedness(-frandom(30,50));
			A_HDLook();
		}
		#### EEEE 3 A_Watch();
		#### A 0 A_Jump(90,"roam2");
		#### E 0 A_JumpIf(targetinsight,"see");
		#### E 0 setstatelabel("roam");
	roll.start:
		#### F 1 A_UpdateSprite(true);
		#### F 1 A_Vocalize(seesound);
		#### F 1
		{
			if(target){
				double dt=distance3d(target);
				if(dt<128){
					setstatelabel("roll.back");
				} else {
					if(!random(0,2))setstatelabel("roll.back");
					if(!random(0,7))setstatelabel("roll.forward");
					else if(random(0,1))setstatelabel("roll.left");
					else setstatelabel("roll.right");
				}
			} else {
				if(!random(0,2))setstatelabel("roll.back");
				if(!random(0,7))setstatelabel("roll.forward");
				else if(random(0,1))setstatelabel("roll.left");
				else setstatelabel("roll.right");
			}
			A_StartSound("misc/fwoosh",CHAN_WEAPON,CHANF_OVERLAP,0.5);
		}
	roll.left:
		#### # 0 A_UpdateSprite(true);
		#### B 4 A_ChangeVelocity(-1,5,0,CVF_RELATIVE);
		#### C 4 A_ChangeVelocity(-2,7,0,CVF_RELATIVE);
		#### D 4 A_ChangeVelocity(-4,10,0,CVF_RELATIVE);
		#### E 2 A_ChangeVelocity(-3,7,0,CVF_RELATIVE);
		#### E 2 A_ChangeVelocity(-3,6,0,CVF_RELATIVE);
		#### F 2 A_ChangeVelocity(-2,5,0,CVF_RELATIVE);
		#### F 3 A_ChangeVelocity(-2,3,0,CVF_RELATIVE);
		#### F 4 A_ChangeVelocity(-1,2,0,CVF_RELATIVE);
		#### F 4 A_ChangeVelocity(-1,2,0,CVF_RELATIVE);
		#### E 0 A_Jump(56,"roll.start");
		#### J 0 A_Jump(120,"shoot");
		#### F 3 A_Vocalize(seesound);
		#### A 0 A_UpdateSprite(false);
		goto see;
	roll.right:
		#### # 0 A_UpdateSprite(true);
		#### G 4 A_ChangeVelocity(-1,-5,0,CVF_RELATIVE);
		#### H 4 A_ChangeVelocity(-2,-7,0,CVF_RELATIVE);
		#### I 4 A_ChangeVelocity(-4,-10,0,CVF_RELATIVE);
		#### J 2 A_ChangeVelocity(-3,-7,0,CVF_RELATIVE);
		#### J 2 A_ChangeVelocity(-3,-6,0,CVF_RELATIVE);
		#### K 2 A_ChangeVelocity(-2,-5,0,CVF_RELATIVE);
		#### K 3 A_ChangeVelocity(-2,-3,0,CVF_RELATIVE);
		#### K 4 A_ChangeVelocity(-1,-2,0,CVF_RELATIVE);
		#### K 4 A_ChangeVelocity(-1,-2,0,CVF_RELATIVE);
		#### J 0 A_Jump(56,"roll.start");
		#### J 0 A_Jump(120,"shoot");
		#### L 3 A_Vocalize(seesound);
		#### A 0 A_UpdateSprite(false);
		goto see;
	roll.forward:
		#### # 0 A_UpdateSprite(true);
		#### F 4 A_ChangeVelocity(5,random(-1,1),0,CVF_RELATIVE);
		#### L 4 A_ChangeVelocity(7,random(-2,2),0,CVF_RELATIVE);
		#### D 4 A_ChangeVelocity(10,random(-4,4),0,CVF_RELATIVE);
		#### D 2 A_ChangeVelocity(7,random(-3,3),0,CVF_RELATIVE);
		#### J 2 A_ChangeVelocity(6,random(-3,3),0,CVF_RELATIVE);
		#### J 2 A_ChangeVelocity(5,random(-3,3),0,CVF_RELATIVE);
		#### D 3 A_ChangeVelocity(3,random(-2,2),0,CVF_RELATIVE);
		#### J 4 A_ChangeVelocity(2,random(-1,1),0,CVF_RELATIVE);
		#### J 4 A_ChangeVelocity(2,random(-1,1),0,CVF_RELATIVE);
		#### D 0 A_Jump(56,"roll.start");
		#### J 0 A_Jump(200,"shoot");
		#### F 3 A_Vocalize(seesound);
		#### A 0 A_UpdateSprite(false);
		goto see;
	roll.back:
		#### # 0 A_UpdateSprite(true);
		#### F 4 A_ChangeVelocity(-5,random(-1,1),0,CVF_RELATIVE);
		#### L 4 A_ChangeVelocity(-7,random(-2,2),0,CVF_RELATIVE);
		#### D 4 A_ChangeVelocity(-10,random(-4,4),0,CVF_RELATIVE);
		#### D 2 A_ChangeVelocity(-7,random(-3,3),0,CVF_RELATIVE);
		#### J 2 A_ChangeVelocity(-6,random(-3,3),0,CVF_RELATIVE);
		#### J 2 A_ChangeVelocity(-5,random(-3,3),0,CVF_RELATIVE);
		#### D 3 A_ChangeVelocity(-3,random(-2,2),0,CVF_RELATIVE);
		#### J 4 A_ChangeVelocity(-2,random(-1,1),0,CVF_RELATIVE);
		#### J 4 A_ChangeVelocity(-2,random(-1,1),0,CVF_RELATIVE);
		#### D 0 A_Jump(56,"roll.start");
		#### J 0 A_Jump(120,"shoot");
		#### F 3 A_Vocalize(seesound);
		#### A 0 A_UpdateSprite(false);
		goto see;
	pain:
		#### G 3 A_UpdateSprite();
		#### G 3 A_Vocalize(painsound);
		#### G 0 A_Jump(100,"roll.start");
		#### AB 2 A_FaceTarget(50,50);
		#### CD 3 A_ChangeVelocity(
			frandom(-1,1),
			frandom(1,max(0,5))*randompick(-1,1),
			0,CVF_RELATIVE
		);
		#### G 0 A_CPosRefire();
		#### E 0 A_Jump(256,"missile");
	death:
		#### H 5 A_UpdateSprite();
		#### I 5 A_Vocalize(deathsound);
		#### JK 5;
	dead:
		---- A 0 A_UpdateSprite();
		#### K 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### L 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	raise:
		#### L 4 A_UpdateSprite();
		#### LK 6;
		#### JIH 4;
		#### A 0 A_Jump(256,"see");
	gib:
		#### M 5 A_UpdateSprite();
		#### N 5{
			A_GibSplatter();
			A_XScream();
		}
		#### OP 5 A_GibSplatter();
		#### QRST 5;
	gibbed:
		#### T 0 A_UpdateSprite();
		#### T 3 canraise A_JumpIf(abs(vel.z)<2.,1);
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2.,"gibbed");
		wait;
	ungib:
		#### U 12 A_UpdateSprite();
		#### T 8;
		#### SRQ 6;
		#### PONM 4;
		#### A 0 A_Jump(256,"pain");
	falldown:
		#### H 5 A_UpdateSprite();
		#### I 5 A_Vocalize(deathsound);
		#### JJKKK 2 A_SetSize(-1,max(deathheight,height-10));
		#### L 0 A_SetSize(-1,deathheight);
		#### L 10 A_KnockedDown();
		wait;
	standup:
		#### K 6 A_UpdateSprite();
		#### J 0 A_Jump(160,2);
		#### J 0 A_Vocalize(seesound);
		#### JI 4 A_Recoil(-0.3);
		#### HE 6;
		#### A 0 setstatelabel("see");
	}
}

// ------------------------------------------------------------
// Pipebomb weak explosive
// ------------------------------------------------------------
class HDPipebombs:HDFragGrenades{
	default{
		weapon.selectionorder 1021;
		weapon.slotnumber 0;
		tag "Pipebombs";
		hdgrenadethrower.ammotype "HDPipebombAmmo";
		hdgrenadethrower.throwtype "HDPipebomb";
		hdgrenadethrower.spoontype "HDSmoke";
		hdgrenadethrower.wiretype "Tripwire";
		inventory.icon "PBMBA1";
	}
	
	override string,double getpickupsprite(){return "PBMBA1",0.7;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage(
				(weaponstatus[0]&FRAGF_PINOUT)?"PBMBA1":"PBMBA1",
				(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.7,0.7)
			);
			sb.drawnum(hpl.countinv("HDPipebombAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.drawwepnum(
			hpl.countinv("HDPipebombAmmo"),
			(HDCONST_MAXPOCKETSPACE/ENC_FRAG)
		);
		sb.drawwepnum(hdw.weaponstatus[FRAGS_FORCE],50,posy:-10,alwaysprecise:true);
		if(!(hdw.weaponstatus[0]&FRAGF_SPOONOFF)){
			sb.drawrect(-21,-19,5,4);
			if(!(hdw.weaponstatus[0]&FRAGF_PINOUT))sb.drawrect(-25,-18,3,2);
		}else{
			int timer=hdw.weaponstatus[FRAGS_TIMER];
			if(timer%3)sb.drawwepnum(140-timer,140,posy:-15,alwaysprecise:true);
		}
	}
	
	override void ForceBasicAmmo(){
		owner.A_SetInventory("HDPipebombAmmo",1);
	}
	
	states
	{
		deselectinstant:
			TNT1 A -1 A_TakeInventory("HDPipebombs", 1);
			stop;
	}
}
class HDPipebombTripwireFrag:Tripwire{
	default{
		weapon.selectionorder 1021;
		tripwire.ammotype "HDPipebombAmmo";
		tripwire.throwtype "HDPipebomb";
		tripwire.spoontype "HDSmoke";
		tripwire.weptype "HDPipebombs";
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("WPG0Z0",(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.7,0.7));
			sb.drawnum(hpl.countinv("HDPipebombAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.drawwepnum(
			hpl.countinv("HDPipebombAmmo"),
			(ENC_FRAG/HDCONST_MAXPOCKETSPACE)
		);
		sb.drawwepnum(hdw.weaponstatus[FRAGS_FORCE],50,posy:-10,alwaysprecise:true);
		if(!(hdw.weaponstatus[0]&FRAGF_SPOONOFF)){
			sb.drawrect(-21,-19,5,4);
			if(!(hdw.weaponstatus[0]&FRAGF_PINOUT))sb.drawrect(-25,-18,3,2);
		}else{
			int timer=hdw.weaponstatus[FRAGS_TIMER];
			if(timer%3)sb.drawwepnum(140-timer,140,posy:-15,alwaysprecise:true);
		}
	}
}
class HDPipebombRoller:HDFragGrenadeRoller{
	default{
		-noextremedeath -floorclip +shootable +noblood +forcexybillboard
		+activatemcross -noteleport +noblockmonst +explodeonwater
		+missile +bounceonactors +usebouncestate
			bouncetype "doom";bouncesound "misc/fragknock";
		radius 2;height 2;damagetype "none";
		scale 0.6;
		obituary "%o was fragged by %k.";
		radiusdamagefactor 0.04;pushfactor 1.4;maxstepheight 2;mass 30;
	}
	override void tick(){
		super.tick();
		HDPipebomb.Beep(self,fuze);
	}
	//returns true if area around us is clear of friendlies
	bool A_CheckBlast(actor tgt=null,double checkradius=256){
		//console.printf("\cgtarget: "..target.GetClassName());
		//console.printf("\cgmaster: "..master.GetClassName());
		if(!target)return true;
		blockthingsiterator itt=blockthingsiterator.create(self,checkradius);
		while(itt.next()){
			actor it=itt.thing;
			if(
				it.health>0&&
				(target.isfriend(it)||target.isteammate(it))
			)return false;
		}
		return true;
	}
	states{
	spawn:
		PBMB A 0 nodelay{
			HDMobAI.Frighten(self,128);
		}
	spawn2:
		#### AA 2{
			if(abs(vel.z-keeprolling.z)>10)A_StartSound("misc/fragknock",CHAN_BODY,CHANF_OVERLAP,0.9,ATTN_NORM,1.3);
			else if(floorz>=pos.z)A_StartSound("misc/fragroll",CHAN_BODY,CHANF_OVERLAP,0.9,ATTN_NORM,1.2);
			keeprolling=vel;
			if(abs(vel.x)<0.4 && abs(vel.y)<0.4) setstatelabel("death");
		}loop;
	bounce:
		---- A 0{
			bmissile=false;
			vel*=0.3;
		}goto spawn2;
	death:
		---- A 2{
			if(abs(vel.z-keeprolling.z)>3){
				A_StartSound("misc/fragknock",CHAN_BODY,CHANF_OVERLAP,1.0,ATTN_NORM,1.3);
				keeprolling=vel;
			}
			if(abs(vel.x)>0.4 || abs(vel.y)>0.4) setstatelabel("spawn");
		}wait;
	destroy:
		TNT1 A 1{
			bsolid=false;bpushable=false;bmissile=false;bnointeraction=true;bshootable=false;
			if(!random(0,8)||!A_CheckBlast(master))
			{
				A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.6);
				A_SpawnItemEx("HDSmoke",frandom(-2,2),frandom(-2,2),frandom(-2,2), vel.x+frandom(-2,2),vel.y+frandom(-2,2),vel.z+frandom(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
				A_SpawnItemEx("HugeWallChunk",frandom(-6,6),frandom(-6,6),frandom(0,6), vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+frandom(1,8),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
			} else {
				HDPipebomb.FragBlast(self);
				actor xpl=spawn("WallChunker",self.pos-(0,0,1),ALLOW_REPLACE);
					xpl.target=target;xpl.master=master;xpl.stamina=stamina;
				xpl=spawn("HDExplosion",self.pos-(0,0,1),ALLOW_REPLACE);
					xpl.target=target;xpl.master=master;xpl.stamina=stamina;
					xpl.deathsound="";
				A_SpawnChunks("BigWallChunk",14,4,12);
			}
		}
		stop;
	}
}
class HDPipebombBeepLight:PointLight{
	default{+dynamiclight.additive}
	int lifetime;
	override void postbeginplay(){
		super.postbeginplay();
		lifetime=4;
		args[0]=200;
		args[1]=30;
		args[2]=10;
		args[3]=64;
		args[4]=0;
	}
	override void tick(){
		if(!target||args[3]<1||lifetime<=0){destroy();return;}
		args[3]=int(frandom(0.8,1.09)*args[3]);
		setorigin(target.pos,true);
		lifetime--;
	}

}
class HDPipebomb:HDFragGrenade{
	default{
		-noextremedeath -floorclip +bloodlessimpact
		+shootable -noblockmap +noblood
		+activatemcross -noteleport
		radius 5;height 5;damagetype "none";
		scale 0.6;
		obituary "%o was pipobombed by %k.";
		mass 400;
		hdfraggrenade.rollertype "HDPipebombRoller";
	}
	static void Beep(HDActor caller, int tick){
		double intensity=double(tick)/240.0;
		//intensity*=intensity;
		int frequency=15-Floor(intensity*10.0);
		if((tick%frequency)==0){
			caller.A_StartSound("ied/beep",CHAN_BODY,CHANF_OVERLAP,0.1+intensity*0.8,ATTN_NORM,0.9+0.3*intensity);
			Actor light=spawn("HDPipebombBeepLight",caller.pos-(0,0,1),ALLOW_REPLACE);
			light.target=caller;
		}
	}
	static void FragBlast(HDActor caller){
		distantnoise.make(caller,"world/shotgunfar");
		DistantQuaker.Quake(caller,4,35,256,8);
		caller.A_StartSound("world/explode",CHAN_BODY,CHANF_OVERLAP,0.9,ATTN_NORM,1.4);
		caller.A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.2);
		caller.A_AlertMonsters();
		//caller.A_SpawnChunksFrags();
		caller.A_HDBlast(
			blastdamagetype:"cheappipeblast",pushradius:128,pushamount:96,fullpushradius:64,
			fragradius:HDCONST_ONEMETRE*8,fragments:HDEXPL_FRAGS/2
		);
	}
	override void tick(){
		super.tick();
		Beep(self,fuze);
	}
	override void postbeginplay(){
		super.postbeginplay();
		fuze+=random(10,60);
	}
	override void GunSmoke(){}
	states{
	spawn:
		PBMB A 2;
		loop;
	death:
		TNT1 A 10{
			bmissile=false;
			let gr=HDFragGrenadeRoller(spawn(rollertype,self.pos,ALLOW_REPLACE));
			if(!gr)return;
			gr.target=self.target;gr.master=self.master;
			gr.fuze=self.fuze;
			gr.vel=self.keeprolling;
			gr.keeprolling=self.keeprolling;
			gr.A_StartSound("misc/fragknock",CHAN_BODY,CHANF_OVERLAP,1.0,ATTN_NORM,1.3);
			//HDMobAI.Frighten(gr,128);
		}stop;
	}
}
class HDPipebombAmmo:HDAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Frag Grenade"
		//$Sprite "PBMBA1"

		+forcexybillboard
		inventory.icon "PBMBA1";
		inventory.amount 1;
		scale 0.45;
		inventory.maxamount 50;
		inventory.pickupmessage "Woah, pipebomb!";
		inventory.pickupsound "weapons/pocket";
		tag "Crude Pipebomb";
		hdpickup.refid "pipe";
		hdpickup.bulk ENC_FRAG*0.5;
	}
	override bool IsUsed(){return true;}
	override void AttachToOwner(Actor user)
	{
		user.GiveInventory("HDPipebombs", 1);
		super.AttachToOwner(user);
	}
	override void DetachFromOwner()
	{
		if(!(owner.player.ReadyWeapon is "HDPipebombs"))
		{
			TakeInventory("HDPipebombs", 1);
		}
		super.DetachFromOwner();
	}
	states{
	spawn:
		PBMB A -1;stop;
	}
}
class PipebombP:HDUPK{
	default{
		+forcexybillboard
		scale 0.3;height 3;radius 3;
		hdupk.amount 1;
		hdupk.pickuptype "HDPipebombAmmo";
		hdupk.pickupmessage "$PICKUP_GRENADE";
		hdupk.pickupsound "weapons/fragpickup";
		stamina 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		pickupmessage=getdefaultbytype(pickuptype).pickupmessage();
	}
	states{
	spawn:
		PBMB A -1;
	}
}
class PipebombPickup:PipebombP{
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("PipebombP",-2,2,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("PipebombP",0,4,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("PipebombP",2,2,flags:SXF_NOCHECKPOSITION);
	}
}