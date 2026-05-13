// ------------------------------------------------------------
// Former Human Spotter Sniper
// ------------------------------------------------------------

class ZombieSniper:HDHumanoid{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Sniper Guy"
		//$Sprite "SPOSA1"

		seesound "shotguy/sight";
		painsound "shotguy/pain";
		deathsound "shotguy/death";
		activesound "shotguy/active";
		tag "Zombie Sniper";

		speed 11;
		decal "BulletScratch";
		meleesound "weapons/smack";
		meleedamage 4;
		maxtargetrange 9000;
		painchance 200;
		accuracy 0;
		translation "TanLBB";

		obituary "%o was shot up by the Tyrant's eagle-eyed sniper.";
		hitobituary "%o was shamefully smacked down by the Tyrant's eagle-eyed sniper.";
	}
	int ammo;
	int chamber;
	override void beginplay(){
		super.beginplay();
		bhasdropped=0;
	}
	override void postbeginplay(){
		super.postbeginplay();
		chamber=randompick(0,0,2);
		ammo=random(0,10);
	}
	override void deathdrop(){
		A_NoBlocking();
		if(bhasdropped){
			if(!bfriendly){
				DropNewItem("HD7mClip",96);
			}
		}else{
			DropNewItem("HDHandgunRandomDrop");
			DropNewItem("HD7mClip",200);
			bhasdropped=true;
			hdweapon wp=null;
			
			wp=DropNewWeapon("BossRifle");
			if(wp){
			wp.weaponstatus[BOSSS_MAG]=ammo;
			wp.weaponstatus[BOSSS_CHAMBER]=chamber;
			wp.weaponstatus[BOSSS_GRIME]=random(15,40);
			}
		}
	}
	void A_EjectRifleCasing(){
		HDWeapon.EjectCasing(self,"HDSpent7mm",
			-frandom(89,92),
			(frandom(4,5.5),0,frandom(0,1)),
			(10,0,0)
		);
	}
	void A_LaserDot() {
		//shoot a line out
		flinetracedata hlt;
		linetrace(
			angle,4096,pitch,
			flags:TRF_NOSKY,
			offsetz:38,
			data:hlt
		);

		if(
			hlt.hittype!=Trace_HitNone
			&&hlt.distance>0
		){
			let sc=GetScanDot();
			if(!!sc){
				bool interp=true;
				if(sc.binvisible){
					interp=false;
					sc.binvisible=false;
				}
				sc.SetOrigin(hlt.hitlocation,interp);
				sc.stamina=1;
			}
		}

		//if the line hits a valid target, go into shooting state
		actor hitactor=hlt.hitactor;
		if(
			hitactor
			&&isHostile(hitactor)
			&&hitactor.bshootable
			&&!hitactor.bnotarget
			&&!hitactor.bnevertarget
			&&(hitactor.bismonster||hitactor.player)
			&&(!hitactor.player||!(hitactor.player.cheats&CF_NOTARGET))
			&&hitactor.health>random((hitactor.vel==(0,0,0))?0:-10,5)
			&&hitactor.checksight(self)
		){
			target=hitactor;
			if(curstate == ResolveState("holding"))setstatelabel("shoot");
			if(hd_debug)A_Log(string.format("Sniper targeted %s",hitactor.getclassname()));
			return;
		}
	}
	actor scandot;
	actor GetScanDot(){
		if(!scandot){
			let scdt=spawn("HERPScanDot",pos);
			scdt.master=self;
			scandot=scdt;
		}
		return scandot;
	}
	override void Tick(){
		super.Tick();
		if(HDMath.IsDead(self)) return;
		if(frame==4||frame==5||(target&&chamber==2)){
			HDCore.emitLaserParticles(self, bfriendly?0x00FF00:0xFF0000, (0, 0, 38), 1.0, 1.0);
			A_LaserDot();
		}
	}
	states{
	spawn:
		CRR5 A 0 nodelay;
	idle:
		#### A 0 A_JumpIf(bambush,"spawnstill");
		#### ABCD 6 A_HDWander(CHF_LOOK);
	scan:
		#### A 0 A_Jump(80,"idle");
		#### EEEE 6{A_SetAngle(angle+DecideOnHandedness(-frandom(30,50)),SPF_INTERPOLATE);}
		#### EEEE 3 A_HDLook();
		#### EEEE 6{A_SetAngle(angle+DecideOnHandedness(-frandom(30,50)),SPF_INTERPOLATE);}
		#### EEEE 3 A_HDLook();
		loop;
	spawnstill:
		#### E 10 A_HDLook();
		loop;
	see:
		#### E 4
		{
			// Spooked!
			//if(target&&distance3d(target)<256)setstatelabel("backoff");
			A_FaceLastTargetPos(maxturn:6.);
		}
	see2:
		---- A 0 A_FaceLastTargetPos(maxturn:24.);
		#### ABCD 4 A_HDChase("melee",null,flags:CHF_FLEE|CHF_NODIRECTIONTURN,speedmult:0.5);
		---- A 0 A_FaceLastTargetPos(maxturn:24.);
		#### ABCD 4 A_HDChase(flags:CHF_FLEE|CHF_NODIRECTIONTURN,speedmult:0.5);
		#### A 0 A_JumpIf(!random(0,4)&&(!target||!targetinsight),"scan");
		loop;
	roam:
		#### EEEE 3 A_Watch();
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_JumpIf(targetinsight||!random(0,31),"see");
		#### ABCD 6 A_HDChase(speedmult:0.6);
		#### A 0 A_Jump(80,"roam");
		loop;
	missile:
		#### ABCD 3 A_TurnToAim(40,shootstate:"aiming",musthaveactualsight:true);
		loop;
	holding:
//		#### E 5 A_FaceLastTargetPos(maxturn:5.);
		#### EEE 5 A_HDChase(flags:CHF_DONTMOVE);
		#### EEE 5 A_Watch(12);
		#### EEE 7 A_Watch(12);
		#### E 2 A_Jump(80,"scan");
		loop;
	aiming:
		#### E 0 A_JumpIf(!CheckTargetInSight(),"holding");
		#### E 1 A_StartAim(maxspread:3,rate:0.9,mintics:8,maxtics:random(15,40));
	shoot:
		#### E 2 {
			if(target)target.A_StartSound("weapons/bossclick2",8,CHANF_OVERLAP,1.0,pitch:1.2);
			A_LeadTarget(lasttargetdist*0.01,randompick(0,0,0,1),delay:2);
		}
		#### F 1{
			if(chamber<2){
				setstatelabel("ohforfuckssake");
				return;
			}
			chamber--;
			angle+=frandom(0,spread)-frandom(0,spread);
			pitch+=frandom(0,spread)-frandom(0,spread);
			A_StartSound("weapons/bigrifle2",CHAN_WEAPON,CHANF_OVERLAP);
			HDBulletActor.FireBullet(self,"HDB_776r",spread:1.0,speedfactor:0.8);
			A_Recoil(0.4);
		}
		#### F 1{
			angle+=frandom(0,spread)-frandom(0,spread);
			pitch+=frandom(0,spread)-frandom(0,spread);
		}
		#### E random(7,15);
	chamber:
		#### E 2 A_StartSound("weapons/boltback",8);
		#### E random(8,16) {
			angle+=(frandom(0,spread)-frandom(0,spread))*2.0;
			pitch+=(frandom(0,spread)-frandom(0,spread))*2.0;
			if(ammo){
				chamber=2;
				ammo--;
				A_EjectRifleCasing();
			}
		}
//		#### E 0 A_FaceLastTargetPos(maxturn:5.);
		#### E 3 A_StartSound("weapons/boltfwd",8);
//		#### E 2 A_FaceLastTargetPos(maxturn:5.);
	postshot:
		#### E 4{
			if(!random(0,127))A_Vocalize(activesound);
			if(ammo<1){
				setstatelabel("reload");
				return;
			}
			spread=max(0,spread-1);
			A_SetTics(random(2,6));
		}
		#### E 1 A_JumpIf(!CheckTargetInSight(),"holding");
		---- A 0 setstatelabel("missile");
	ohforfuckssake:
		#### E 6;
	reload:
		#### A 0 A_JumpIf(ammo>0&&chamber<2,"chamber");
		#### A 2 A_HDChase("melee",null,flags:CHF_FLEE);
		#### A 2 A_StartSound("weapons/bossclick2",8,CHANF_OVERLAP,0.9,pitch:0.95);
		#### A 4 A_StartSound("weapons/bossloadm",8,CHANF_OVERLAP);
		#### BCDA 2 A_HDChase("melee",null,flags:CHF_FLEE);
	reloadloop:
		#### AB 2 {if(hdmobai.tryshoot(self))A_HDWander(flags:CHF_FLEE);}
		#### B 2 A_StartSound("weapons/pocket",9,CHANF_OVERLAP);
		#### A random(2,4) {
			ammo++;
			A_StartSound("weapons/bossclick2",8,CHANF_OVERLAP);
			A_FaceLastTargetPos(maxturn:24.);
			if(ammo>9)setstatelabel("reloadend");
		}
		#### ABC 2{if(hdmobai.tryshoot(self))A_HDWander(flags:CHF_FLEE);}
		loop;
	reloadend:
		#### A 1 A_StartSound("weapons/bossclick2",8,CHANF_OVERLAP,0.3,pitch:1.05);
		#### A 0 A_JumpIf(ammo>0&&chamber<2,"chamber");
		#### BCD 3 {if(hdmobai.tryshoot(self))A_HDWander(flags:CHF_FLEE);}
		#### E 4 A_HDChase(flags:CHF_DONTMOVE);
		---- A 0 setstatelabel("see");
	pain:
		#### G 3 A_Jump(12,1);
		#### G 3 A_Vocalize(painsound);
		#### G 0{
			A_ShoutAlert(0.2,SAF_SILENT);
			if(target&&distance3d(target)<100)setstatelabel("see");
		}
		#### ABCD 2 A_HDChase(flags:CHF_FLEE);
		#### G 0;
		---- A 0 setstatelabel("see");
	falldown:
		#### GH 2;
		#### H 5 A_Vocalize(deathsound);
		#### IIJJJ 2 A_SetSize(-1,max(deathheight,height-10));
		#### KL 0 A_SetSize(-1,deathheight);
		#### M 10 A_KnockedDown();
		wait;
	standup:
		#### K 6;
		#### J 0 A_Jump(160,2);
		#### J 0 A_Vocalize(seesound);
		#### JI 4 A_Recoil(-0.3);
		#### HE 6;
		#### A 0 setstatelabel("see");
	death:
		#### GH 2;
		#### H 5 A_Vocalize(deathsound);
		#### I 10;
		#### JK 5;
	dead:
		#### KL 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### M 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	}
}
