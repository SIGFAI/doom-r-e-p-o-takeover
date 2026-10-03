// R.E.P.O. monsters: the rubber Duck, the pack-hunting Gnome and the sack-faced Hunter.

class RepoMon : Actor
{
	// A burst of coloured bits: feathers, sparks, smoke.
	void Burst(color c, int n, double spd = 4, double up = 3)
	{
		for (int i = 0; i < n; i++)
		{
			A_SpawnParticle(c, SPF_FULLBRIGHT, 30 + random(0, 14), frandom(1.2, 2.6), 0,
				frandom(-8, 8), frandom(-8, 8), height * frandom(0.2, 0.9),
				frandom(-spd, spd), frandom(-spd, spd), frandom(0.5, up),
				0, 0, -0.18, 1.0, -0.03);
		}
	}
}

class RepoDuck : RepoMon replaces DoomImp
{
	Default
	{
		Health 45;
		Radius 18;
		Height 40;
		Speed 8;
		Scale 0.8;
		PainChance 140;
		MeleeRange 56;
		Monster;
		+FLOORCLIP
		SeeSound "repo/quack";
		ActiveSound "repo/quack";
		Obituary "%o was honked to death by a duck.";
		HitObituary "%o got pecked by an angry duck.";
	}

	// The honk: a white shock ring that shatters any fragile valuable close by.
	void Honk()
	{
		A_StartSound("repo/quack", CHAN_VOICE, 0, 1.0, ATTN_NORM, 1.25);
		for (int i = 0; i < 24; i++)
		{
			A_SpawnParticle(0xFFFFFFFF, SPF_FULLBRIGHT, 16, 3, 0, 0, 0, 12, cos(i * 15) * 7, sin(i * 15) * 7, 0.2, 0, 0, 0, 0.9, -0.05);
		}
		let it = BlockThingsIterator.Create(self, 130);
		while (it.Next())
		{
			let l = RepoLoot(it.Thing);
			if (l && l.fragile && l.health > 0 && Distance3D(l) < 130) l.DamageMobj(self, self, 50, 'None', DMG_FORCED);
		}
	}

	States
	{
	Spawn:
		DUCK A 10 A_Look;
		Loop;
	See:
		DUCK A 5 A_Chase;
		DUCK B 5 A_Chase;
		Loop;
	Melee:
		DUCK C 6 A_FaceTarget;
		DUCK C 6 A_CustomMeleeAttack(random(3, 6) * 3, "repo/quack", "");
		Goto See;
	Missile:
		DUCK C 10 { A_FaceTarget(); Honk(); }
		DUCK C 5 { A_Recoil(-16); Burst(0xFFFFFF, 6, 2, 1); }
		DUCK C 5 A_Recoil(-6);
		DUCK B 6;
		Goto See;
	Pain:
		DUCK D 4 Burst(0xFFFFFF, 14, 4, 4);
		DUCK D 4 A_StartSound("repo/quack", CHAN_VOICE, 0, 1.0, ATTN_NORM, 1.5);
		Goto See;
	Death:
		DUCK D 3 { Burst(0xFFFFFF, 30, 5, 5); A_StartSound("repo/quack", CHAN_VOICE, 0, 1.0, ATTN_NORM, 0.65); }
		DUCK E 6 A_NoBlocking;
		DUCK E -1;
		Stop;
	}
}

// Bigger, tougher, same attitude: replaces the Demon.
class RepoDuckKing : RepoDuck replaces Demon
{
	Default
	{
		Health 180;
		Radius 28;
		Height 66;
		Speed 10;
		Scale 1.45;
		PainChance 80;
		MeleeRange 70;
		Obituary "%o was stomped by the Big Duck.";
		HitObituary "%o was stomped by the Big Duck.";
	}

	States
	{
	Spawn:
		DUCK A 10 A_Look;
		Loop;
	See:
		DUCK A 6 A_Chase;
		DUCK B 6 A_Chase;
		Loop;
	Melee:
		DUCK C 8 A_FaceTarget;
		DUCK C 8 A_CustomMeleeAttack(random(4, 8) * 4, "repo/quack", "");
		Goto See;
	Missile:
		DUCK C 12 { A_FaceTarget(); Honk(); }
		DUCK C 5 { A_Recoil(-18); Burst(0xFFFFFF, 10, 3, 2); }
		DUCK C 5 A_Recoil(-8);
		DUCK B 6;
		Goto See;
	Pain:
		DUCK D 4 Burst(0xFFFFFF, 20, 5, 4);
		DUCK D 4 A_StartSound("repo/quack", CHAN_VOICE, 0, 1.0, ATTN_NORM, 0.9);
		Goto See;
	Death:
		DUCK D 3 { Burst(0xFFFFFF, 45, 6, 6); A_StartSound("repo/quack", CHAN_VOICE, 0, 1.0, ATTN_NORM, 0.45); }
		DUCK E 6 A_NoBlocking;
		DUCK E -1;
		Stop;
	}
}

class RepoGnome : RepoMon replaces ZombieMan
{
	Default
	{
		Health 20;
		Radius 14;
		Height 42;
		Speed 10;
		PainChance 200;
		MeleeRange 44;
		Monster;
		+FLOORCLIP
		SeeSound "repo/giggle";
		Obituary "%o was shanked by a gnome.";
		HitObituary "%o was shanked by a gnome.";
	}

	// Gnomes that show up mid-game come in packs of three.
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		let h = RepoHaul.Get();
		if (!h || h.packing || level.maptime < 10) return;
		h.packing = true;
		for (int i = 0; i < 2; i++)
		{
			double a = angle + 100 + i * 160;
			let g = Spawn("RepoGnome", pos + (cos(a) * 38, sin(a) * 38, 0), ALLOW_REPLACE);
			if (g && !g.TestMobjLocation()) g.Destroy();
		}
		h.packing = false;
	}

	States
	{
	Spawn:
		GNOM A 10 A_Look;
		Loop;
	See:
		GNOM A 3 A_Chase;
		GNOM B 3 A_Chase;
		Loop;
	Melee:
		GNOM C 4 A_FaceTarget;
		GNOM C 5 A_CustomMeleeAttack(random(2, 4) * 3, "", "");
		GNOM B 4;
		Goto See;
	Pain:
		GNOM D 4 Burst(0xFFB02020, 6, 3, 3);
		GNOM D 4 A_Pain;
		Goto See;
	Death:
		GNOM D 3 { Burst(0xFFD02020, 14, 4, 4); A_StartSound("repo/giggle", CHAN_VOICE, 0, 1.0, ATTN_NORM, 1.6); }
		GNOM E 6 A_NoBlocking;
		GNOM E -1;
		Stop;
	}
}

class RepoHunter : RepoMon replaces ShotgunGuy
{
	Default
	{
		Health 45;
		Radius 20;
		Height 58;
		Speed 6;
		PainChance 110;
		Monster;
		+FLOORCLIP
		SeeSound "repo/giggle";
		Obituary "%o was shot by the Hunter.";
	}

	States
	{
	Spawn:
		HUNT A 10 A_Look;
		Loop;
	See:
		HUNT A 6 A_Chase;
		HUNT B 6 A_Chase;
		Loop;
	Missile:
		HUNT A 14 A_FaceTarget;
		HUNT C 8 Bright
		{
			A_StartSound("repo/rifle", CHAN_WEAPON, 0, 1.0, ATTN_NORM);
			A_CustomBulletAttack(4.0, 0, 1, random(2, 5) * 5, "BulletPuff");
			Burst(0xFFFFC040, 8, 3, 2);
		}
		HUNT A 12;
		Goto See;
	Pain:
		HUNT D 5 Burst(0xFFA01010, 6, 3, 3);
		HUNT D 5 A_Pain;
		Goto See;
	Death:
		HUNT D 4 Burst(0xFFB01010, 16, 4, 4);
		HUNT E 6 { A_NoBlocking(); A_StartSound("repo/quack", CHAN_VOICE, 0, 1.0, ATTN_NORM, 0.5); }
		HUNT E -1;
		Stop;
	}
}
