// ------------------------------------------------------------
// Wither Skelly Boy
// ------------------------------------------------------------

class Wither:HDMobBase{
	default
	{
		health 250;
		mass 60;
		radius 20;
		height 56;
		speed 10;
		painchance 120;
		monster;
		species "DoomImp";
		+floorclip
		+hdmobbase.smallhead
		+hdmobbase.biped
		+hdmobbase.climber
		+hdmobbase.noincap
		+noblood
		+noblooddecals
		maxdropoffheight 128;
		tag "Wither";
		obituary "%o was outlived by a Wither.";
		seesound "wither/see";
		painsound "wither/pain";
		activesound "wither/act";
		damagefactor "hot",1.1;
		damagefactor "cold",1.1;
		damagefactor "slashing",0.8;
		damagefactor "piercing",0.8;
	}
	override void postbeginplay(){
		super.postbeginplay();
		bonlyscreamondeath=true;
		bnoextremedeath=true;
		scale=(0.85,0.85);
	}
	override void CheckFootStepSound(){
		if((frame==0||frame==3)&&frame!=curstate.nextstate.frame){
			A_StartSound("revenant/step",22,CHANF_OVERLAP,0.5,ATTN_NORM,1.5);
		}
	}
	bool strafeleft;
	void A_Strafe(){
		A_FaceLastTargetPos(10);
		strafeleft=(random(0,2))?blefthanded:!blefthanded;
		vector2 newdir=angletovector((strafeleft?angle+90:angle-90)+frandom(-20,20),frandom(0.5,2.5));
		vel.xy+=newdir;
		if(floorz==pos.z)vel.z+=randompick(-2.,1.);
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		HDMath.ProcessSynonyms(mod);
		if(mod=="hot"||mod=="cold")flags|=DMG_NO_PAIN;
		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	States
	{
	spawn:
		WITH AB 6;
	spawn2:
		#### A 0{angle+=DecideOnHandedness(-frandom(30,50));}
		#### AABB 6 A_HDLook();
		#### A 0{angle+=DecideOnHandedness(-frandom(30,50));}
		#### AABB 6 A_HDLook();
		loop;
	see:
		#### ABCDABCD 4 A_HDChase();
		---- A 0{
			bfrightened=targetinsight||firefatigue>HDCONST_MAXFIREFATIGUE;
		}
		loop;
	melee:
		#### F 3 A_FaceTarget();
		#### F 1 A_SkelWhoosh();
		#### G 2;
		#### G 4 A_FireballerScratch(null,random(10,30),ballchance:0,damagetype:"bashing");
		#### F 4;
		---- A 0 setstatelabel("see");
	missile:
		#### EF 6 A_FaceLastTargetPos();
		---- A 0 {
			if(!random(0,3))setstatelabel("fireball.tri");
			else if(!random(0,3))setstatelabel("fireball.rapid");
			else setstatelabel("fireball");
		}
	fireball.tri:
		#### G 2 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch);
		}
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 2 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch);
		}
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 5 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch+5);
		}
		#### G 6;
		---- A 0 setstatelabel("see");
	fireball.rapid:
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 6 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch+15);
			A_Strafe();
		}
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 6 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch+12);
			A_Strafe();
		}
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 6 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch+2);
			A_Strafe();
		}
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 6 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch);
			A_Strafe();
		}
		#### G 12;
		---- A 0 setstatelabel("see");
	fireball:
		#### F 0 A_LeadTarget(lasttargetdist*(1./12.),delay:2);
		#### G 2 {
			A_SpawnProjectile("HDWitherBall",32,0,0,CMF_AIMDIRECTION,pitch+2);
		}
		#### G 2;
		---- A 0 setstatelabel("see");
	pain:
		#### H 2 A_Pain;
		#### H 2
		{
			bool garbage;actor gg;
			if(!random(0,12)){
				[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
				gg.frame=random(9,11);
			}
			if(!random(0,12)){
				[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
				gg.frame=random(9,11);
			}
			if(!random(0,8)){
				[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
				gg.frame=random(13,14);
			}
			if(!random(0,8)){
				[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
				gg.frame=random(13,14);
			}
			BonesParticle("WITHK0",1,10,random(20,40));
			BonesParticle("WITHL0",random(0,1),10,random(20,40));
		}
		#### A 2 A_FaceTarget();
		---- A 0 A_Strafe();
		#### BCD 2 A_FastChase();
		---- A 0 A_Startsound("wither/bones");
		---- A 0 A_JumpIf(firefatigue>(HDCONST_MAXFIREFATIGUE*1.6),"see");
		goto missile;
//		---- A 0 setstatelabel("see");
	xdeath:
	death:
		TNT1 A 10
		{
			A_Startsound("wither/death",23112,CHANF_OVERLAP);
			bool garbage;actor gg;
			//BonesParticle("WITHI0",1,18,48);
			[garbage,gg]=A_SpawnItemEx("BoneySkull",random(-5,5),random(-5,5),28,random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
			gg.bfriendly=bfriendly;
			for(int i=0; i < random(2,3); i++)
			{
				[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
				gg.frame=random(9,11);
				[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
				gg.frame=random(13,14);
			}
			[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),28,random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
			gg.frame=12;
			BonesParticle("WITHJ0",2,15,28);
			BonesParticle("WITHK0",3,10,random(20,40));
			BonesParticle("WITHL0",2,10,random(20,40));
			//BonesParticle("WITHM0",1,18,28);
		}
		TNT1 A 0 A_Startsound("wither/bones");
		stop;
	}
	void BonesParticle(string pbone, int pamount, int psize, int pz)
	{
		FSpawnParticleParams bp;
		bp.texture = TexMan.CheckForTexture(pbone);
		bp.flags = SPF_ROLL;
		bp.color1 = "FFFFFF";
		for (int i = 0; i < pamount; i++)
		{
			bp.lifetime = 35;
			bp.size = psize*1.5;
			bp.startalpha = 1.0;
			bp.pos.x = pos.x+random(-5,5);
			bp.pos.y = pos.y+random(-5,5);
			bp.pos.z = pos.z+pz;
			bp.vel.xy = (random(-4,4),random(-4,4));
			bp.vel.z = random(5,10);
			bp.accel.xy = -(bp.vel.xy*0.05);
			bp.accel.z = -1;
			bp.startRoll = random(0,359);
			bp.rollvel = randompick(-25,-15,15,25);
			level.SpawnParticle(bp);
		}
	}	
}

class BoneyBone:HDDebris{
	default{
		scale 0.8;height 8;radius 6;
		gravity 1.0;
		bouncesound "none";
		-missile
		+MBFBOUNCER
	}
	states{
	spawn:
		WITH I 0 nodelay {
			changetid(-13767);
		} //{frame=random(9,11)};//9
	spawn2:
		---- A 1{
			A_SetRoll(roll+frandom(-15,15),SPF_INTERPOLATE);
		}wait;
	death:
		---- A -1{
			A_SetRoll(randompick(1,1,2,2,0.5,0.75)*90,SPF_INTERPOLATE);
		}
		wait;
	}
}
class BoneySkull:HDMobBase{
	default{
		+noblood
		+forcexybillboard
		+lookallaround
		-countkill
		+nobouncesound
		+nowallbouncesnd
		+noforwardfall
		+noextremedeath
		-canusewalls
		-activatemcross
		+activatepcross
		+rollsprite
		+rollcenter
		+hdmobbase.noshootablecorpse
		+hdmobbase.novitalshots
		+hdmobbase.nodeathdrop
		-activatemcross
		+activatepcross
		+noblockmonst
		+bounceonactors
		+allowbounceonactors
		+canbouncewater
		+lookallaround
		-SOLID
		+CANPASS
		bouncefactor 0.2;
		bouncetype "doom";
		gravity 1.0;
		painchance 200;
		+usebouncestate
		+MBFBOUNCER
		health 120;mass 20;
//		renderstyle "translucent";
		radius 12;
		height 12;
		scale 0.8;
		seesound "";
		speed 1;
		meleerange 64;
		spriteangle 0;
	}
	override void postbeginplay(){
		super.postbeginplay();
		stamina=0;
	}
	
	states{
	spawn:
		WITH I 0 nodelay; //{frame=random(9,11)};//9
	spawn2:
		---- A 1{
			A_SetRoll(roll+frandom(-25,25),SPF_INTERPOLATE);
		}wait;
	revive:
		---- A 1{
			busebouncestate=false;
			bMBFBOUNCER=false;
			A_SetTics(max(random(1,4)-1,1));
			double vitality=min(double(stamina)/180.0,1.0)+frandom(-0.1,0.1);
			// Rotate menacingly
			A_SetRoll(roll+frandom(2,15)*vitality,SPF_INTERPOLATE);
			// Jump around
			A_ChangeVelocity(frandom(-2,2)*vitality,frandom(-2,2)*vitality,1*frandom(0.75,1.0)*vitality,CVF_RELATIVE);
			// Hover over the ground, also menacingly
			double hoverforce = (floorz-pos.z+48)*0.2 + vel.z*-0.5;
			A_ChangeVelocity(vel.x*-0.03*vitality,vel.y*-0.03*vitality,hoverforce*vitality);
			if(!random(0,10))A_StartSound("weapons/bfgcharge",CHAN_BODY,CHANF_OVERLAP,vitality*frandom(0.25,1.5),ATTN_NORM,2.0);
			// Summon ol-boneys
			actoriterator it=level.createactoriterator(-13767,"BoneyBone");
			actor actr;
			bool summon=false;
			int counter=0;
			while(actr=it.next()){
				if(BoneyBone(actr)){
					BoneyBone boney=BoneyBone(actr);
					if(boney){
						//boney.pos =(pos+boney.pos)*0.5;
						//boney.TryMove((pos.xy+boney.pos.xy)*0.5,24);
						double dist=distance3d(boney);
						if(dist<312)
						{
							if(vitality>=0.99){
								if(!summon){
									summon=true;
									counter=0;
								}
								boney.A_SpawnItemEx("HDSmoke",frandom(-2,2),frandom(-2,2),frandom(-2,2),frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
								boney.destroy();
							} else {
								boney.A_ChangeVelocity(frandom(-2,2)*vitality,frandom(-2,2)*vitality,frandom(-2,2)*vitality,CVF_RELATIVE);
								vector3 pull=((pos-boney.pos)*0.175-(vel+boney.vel)*0.1)/(1.0+dist*0.015);
								if(!random(0,4)){
									pull=(pull.y,pull.x,pull.z);
								}
								vector3 selfpull=pull*-0.05*(1.0-sin(vitality*3.14))*(0.25+vitality*0.75);
								pull*=(0.05+vitality);
								boney.A_ChangeVelocity((pull.x-boney.vel.x*0.1),(pull.y-boney.vel.y*0.1),(pull.z-boney.vel.z*0.1));
								A_ChangeVelocity(selfpull.x,selfpull.y,selfpull.z);
								boney.A_ChangeVelocity(0,0,random(1.0,2.2)*vitality);
								boney.brelativetofloor=false;
								boney.bmovewithsector=false;
								boney.bnointeraction=false;
								boney.stopped=false;
								if((vitality>0.6)&&!random(0,20)){
									boney.A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,0.5,ATTN_NORM,3.0);
									boney.A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
									boney.A_ChangeVelocity(frandom(-3,3)*vitality,frandom(-3,3)*vitality,frandom(-2,1)*vitality,CVF_RELATIVE);
								}
							}
							counter+=1;
						}
					}
				}
				if(counter>8)break;
			}
			
			if(!summon&&((counter<3&&random(0,7))||counter<2)){
				stamina/=2;
				if(stamina>0)stamina--;
			} else {
				stamina++;
				GiveBody(1);
				if(summon){
					bool garbage;actor skelly;
					[garbage,skelly]=A_SpawnItemEx("Wither",0,0,floorz-pos.z,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					skelly.bcountkill=false;
					skelly.bfriendly=bfriendly;
					A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.5,ATTN_NORM,1.0);
					A_StartSound("vile/raise",CHAN_BODY,CHANF_OVERLAP,1.0,ATTN_NORM,1.0);
					A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					setstatelabel("death");
				} else if((vitality>0.6)&&!random(0,20)){
					A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.0,ATTN_NORM,2.0);
					A_SpawnItemEx("BFGShard",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					A_ChangeVelocity(frandom(-3,3)*vitality,frandom(-3,3)*vitality,frandom(-7,2)*vitality,CVF_RELATIVE);
					stamina+=4;
					GiveBody(-25);
				} else {
					if(vitality<0.5&&!random(0,20)){
						if(CheckTargetInSight())
						{
							setstatelabel("revive.wait");
						//console.printf("too shy!");
						} else {
							stamina+=7;
							GiveBody(-25);
						}
					}
				}
			}
		}
		loop;
	revive.wait:
		---- A 4 {
			if(!CheckTargetInSight()){
				setstatelabel("revive");
			} else if(stamina<100) stamina++;
		}
		---- A 4;
		loop;
	pain:
		---- A 2 {
			if(stamina>20){
				A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,0.5,ATTN_NORM,2.0);
				stamina-=20;
				if(stamina>100&&random(0,3))
				{
					A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
					stamina-=30;
				}
			}
			if(!random(0,4)){
				busebouncestate=true;
				bMBFBOUNCER=true;
				stamina=0;
			}
		}
		---- A 0 setstatelabel("revive.wait");
	bounce.floor:
		---- A 6{
			if(busebouncestate){
				busebouncestate=false;
				bMBFBOUNCER=false;
				A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.0,ATTN_NORM,2.0);
				A_SpawnItemEx("BFGShard",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
				A_SpawnItemEx("BFGSpark",0,0,0,frandom(-2,2),frandom(-2,2),frandom(-2,2),0,SXF_NOCHECKPOSITION);
				A_ChangeVelocity(frandom(-3,3),frandom(-3,3),frandom(-7,2),CVF_RELATIVE);
			}
			
			//if(target)console.printf("tryna start revive..."..target.GetClassName());
			if(!random(0,200)||stamina>3||CheckTargetInSight())setstatelabel("revive.wait");
			//else A_JumpIfInTargetLOS("revive.wait",90);
		}
		wait;
	death:
		---- A 1 A_ChangeVelocity(random(-2,2),random(-2,2),6,CVF_RELATIVE);
		TNT1 A 1
		{
			A_Startsound("wither/bones");
			A_StartSound("weapons/bigcrack",CHAN_BODY,CHANF_OVERLAP,1.6);
			A_SpawnItemEx("HugeWallChunk",0,0,0,vel.x,vel.y,vel.z+frandom(1,2),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		}
		stop;
	}
}

class HDWitherBallTail:HDFireballTail{
	default{
		renderstyle "add";
		deathheight 0.5;
		gravity 0;
		scale 0.3;
	}
	states{
	spawn:
		WITB ABCDE 3{
			scale.x*=randompick(-1,1);
		}loop;
	}
}
class HDWitherBall : HDImpBall
{
	default{
		radius 5;
		height 6;
		speed 10;
		fastspeed 16;
		damagefunction random(3,20);
		missiletype "HDWitherBallTail";
		decal "BrontoScorch";
		scale 1.0;
		gravity 0.5;
		alpha 0.8;
	}
	States
	{
	spawn:
		WITB A 1 BRIGHT;
		WITB B 1 BRIGHT
		{
			A_ChangeVelocity(random(-2,2),random(-2,2),3*frandom(0.75,1.0),CVF_RELATIVE);
		}
	spawn2:
		WITB AB 2 BRIGHT 
		{
			A_FBTail();
			A_FBSeek();
			if(!random(0,4))Spawn("HDSmoke",pos,ALLOW_REPLACE);
			double hover=0.5 + 10.0/(pos.z-floorz+1.0);
			A_ChangeVelocity(random(-1,1),random(-1,1),(hover)*frandom(0.75,1.25),CVF_RELATIVE);
		}
		loop;
	death:
		WITB C 1 BRIGHT
		{
			//spawn("HDExplosion",pos);
			A_StartSound("skeleton/tracex",CHAN_BODY,CHANF_OVERLAP,0.5);
			A_SpawnChunks("HugeWallChunk",4,2,16);
			A_SpawnChunks("HDSmokeChunk",random(0,3),2,16);
			A_HDBlast(
				pushradius:HDCONST_ONEMETRE,pushamount:64,
				fragradius:HDCONST_ONEMETRE*5,fragtype:"HDB_scrap",
				fragments:0,
				immolateradius:64,immolateamount:random(4,20),
				immolatechance:20,
				source:target
			);
		}
		WITB CDE 5 BRIGHT light("BONEX1");
		stop;
	}
}
class DeadWither:Wither {
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
		bool garbage;actor gg;
		for(int i=0; i < random(0,3); i++)
		{
			[garbage,gg]=A_SpawnItemEx("BoneyBone",random(-5,5),random(-5,5),random(20,40),random(-4,4),random(-4,4),random(-1,7),frandom(-360,360),SXF_NOCHECKPOSITION);
			gg.frame=random(13,14);
		}
	}
// 	states{
// 	death.spawndead:
// 		WITH AB 0;
// 		goto dead;
// 	}
}

class WitherSpawner:RandomSpawner{
	default{
		dropitem "Wither",256,100;
		dropitem "DeadWither",256,20;
	}
}