// R.E.P.O. valuables: they glint on the floor, fly to the player when close, and some of them shatter if shot.

class RepoLoot : Actor
{
	int value;
	String label;
	bool fragile;

	Default
	{
		Radius 12;
		Height 22;
		Health 4;
		Scale 1.4;
		+NOBLOOD
		+DONTTHRUST
		+NOTRIGGER
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (fragile) bShootable = true;
	}

	override void Tick()
	{
		Super.Tick();
		if (isFrozen() || health <= 0) return;

		if (GetAge() % 9 == 0)
		{
			A_SpawnParticle(0xFFFFE070, SPF_FULLBRIGHT, 14, 3, 0, frandom(-8, 8), frandom(-8, 8), frandom(2, height),
				0, 0, 0.6, 0, 0, 0, 1.0, -0.07);
		}

		PlayerPawn p = players[consoleplayer].mo;
		if (!p || p.health <= 0) return;
		double d = Distance3D(p);
		if (d < 34 && GetAge() > 12)
		{
			let h = RepoHaul.Get();
			if (h) h.Add(value, label, true);
			A_StartSound("repo/cash", CHAN_ITEM, 0, 0.9);
			for (int i = 0; i < 10; i++)
			{
				p.A_SpawnParticle(0xFFFFD040, SPF_FULLBRIGHT, 24, 4, 0, frandom(-10, 10), frandom(-10, 10), frandom(10, 50),
					frandom(-1.5, 1.5), frandom(-1.5, 1.5), frandom(1, 3), 0, 0, -0.1, 1.0, -0.04);
			}
			Destroy();
			return;
		}
		if (d < 170 && GetAge() > 40 && CheckSight(p))
		{
			// The grabber beam: loot is pulled to the player, trailing sparks.
			bNoGravity = true;
			Vector3 dir = (p.pos + (0, 0, 24) - pos).Unit();
			vel = dir * (3 + (170 - d) / 20);
			A_SpawnParticle(0xFF60E0FF, SPF_FULLBRIGHT, 10, 3, 0, 0, 0, height / 2, 0, 0, 0, 0, 0, 0, 0.9, -0.09);
		}
		else if (bNoGravity)
		{
			bNoGravity = false;
		}
	}

	States
	{
	Spawn:
		TNT1 A 0;
		Stop;
	Death:
		TNT1 A 0 { RepoLoot.Shatter(self); }
		Stop;
	}

	// Glass and gold go everywhere, and the haul takes the loss.
	static void Shatter(RepoLoot l)
	{
		l.A_StartSound("repo/shatter", CHAN_BODY, 0, 1.0);
		for (int i = 0; i < 24; i++)
		{
			l.A_SpawnParticle(random(0, 1) ? 0xFFFFD040 : 0xFF3070E0, SPF_FULLBRIGHT, 30 + random(0, 15), frandom(1.5, 3), 0,
				frandom(-6, 6), frandom(-6, 6), frandom(2, 16), frandom(-4, 4), frandom(-4, 4), frandom(1, 5), 0, 0, -0.25, 1.0, -0.03);
		}
		let h = RepoHaul.Get();
		if (h) h.Lose(l.value / 2, l.label);
	}

	static void DropLoot(Actor from)
	{
		static const Class<RepoLoot> kinds[] = { "RepoVase", "RepoVase", "RepoTrophy", "RepoGoldBars", "RepoGoldBars", "RepoEmerald" };
		Actor a = Spawn(kinds[random(0, kinds.Size() - 1)], from.pos + (0, 0, from.height * 0.5), ALLOW_REPLACE);
		if (a)
		{
			a.vel = (frandom(-3, 3), frandom(-3, 3), frandom(5, 8));
		}
	}
}

class RepoVase : RepoLoot
{
	Default { Radius 10; Height 30; Health 6; }
	override void PostBeginPlay() { value = 600; label = "Ming Vase"; fragile = true; Super.PostBeginPlay(); }
	States { Spawn: VASE A -1; Stop; }
}

class RepoTrophy : RepoLoot
{
	Default { Radius 10; Height 30; Health 6; }
	override void PostBeginPlay() { value = 900; label = "Gold Trophy"; fragile = true; Super.PostBeginPlay(); }
	States { Spawn: TRPH A -1; Stop; }
}

class RepoGoldBars : RepoLoot
{
	Default { Radius 12; Height 22; }
	override void PostBeginPlay() { value = 1000; label = "Gold Bars"; Super.PostBeginPlay(); }
	States { Spawn: GBAR A -1; Stop; }
}

class RepoEmerald : RepoLoot
{
	Default { Radius 10; Height 22; }
	override void PostBeginPlay() { value = 1500; label = "Emerald"; Super.PostBeginPlay(); }
	States { Spawn: GEMS A -1; Stop; }
}
