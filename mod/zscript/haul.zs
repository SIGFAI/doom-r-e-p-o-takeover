// The haul counter, the quota and the loot drops: the R.E.P.O. rules.

class RepoHaul : EventHandler
{
	int haul, quota, bank, extractions, lost;
	int flashUntil;
	bool packing;
	Array<String> popTxt;
	Array<int> popTic;
	Array<int> popGood;

	clearscope static RepoHaul Get()
	{
		return RepoHaul(EventHandler.Find("RepoHaul"));
	}

	override void OnRegister()
	{
		quota = 8000;
	}

	override void WorldLoaded(WorldEvent e)
	{
		if (e.IsSaveGame) return;
		// Guarded loot: some of the monsters placed in the level sit on a valuable.
		let it = ThinkerIterator.Create("Actor");
		Actor a;
		while (a = Actor(it.Next()))
		{
			if (a.bIsMonster && a.health > 0 && random(0, 99) < 6)
			{
				Actor l = Actor.Spawn(random(0, 1) ? "RepoGoldBars" : "RepoVase", a.pos + (frandom(-24, 24), frandom(-24, 24), 0), ALLOW_REPLACE);
				if (l && !l.TestMobjLocation()) l.Destroy();
			}
		}
	}

	override void WorldThingDied(WorldEvent e)
	{
		Actor t = e.Thing;
		if (!t || !t.bIsMonster || t is "RepoLoot") return;
		RepoLoot.DropLoot(t);
		if (t is "RepoDuckKing" || random(0, 3) == 0) RepoLoot.DropLoot(t);
	}

	void Pop(String txt, bool good)
	{
		popTxt.Push(txt);
		popTic.Push(level.maptime);
		popGood.Push(good ? 1 : 0);
		if (popTxt.Size() > 5)
		{
			popTxt.Delete(0);
			popTic.Delete(0);
			popGood.Delete(0);
		}
	}

	void Add(int v, String what, bool good)
	{
		haul += v;
		Pop(String.Format("+$%s  %s", Money(v), what), true);
		if (haul >= quota) Extract();
	}

	void Lose(int v, String what)
	{
		haul = max(0, haul - v);
		lost += v;
		Pop(String.Format("-$%s  %s smashed!", Money(v), what), false);
	}

	void Extract()
	{
		bank += haul;
		extractions++;
		haul = 0;
		quota += 5000;
		flashUntil = level.maptime + 105;
		PlayerPawn p = players[consoleplayer].mo;
		if (p)
		{
			p.A_SetBlend("FFD040", 0.5, 30);
			p.health = min(200, p.health + 50);
		}
		S_StartSound("repo/cash", CHAN_AUTO, 0, 1.0);
		Console.MidPrint(BigFont, "QUOTA MET!\nEXTRACTION COMPLETE");
	}

	clearscope static String Money(int v)
	{
		String s = String.Format("%d", v);
		if (v >= 1000) s = String.Format("%d,%03d", v / 1000, v % 1000);
		return s;
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (gamestate != GS_LEVEL) return;
		int sc = max(1, Screen.GetHeight() / 240);
		int vw = Screen.GetWidth() / sc;
		int vh = Screen.GetHeight() / sc;

		// Panel, top left.
		Screen.Dim(0x101010, 0.6, 6 * sc, 6 * sc, 170 * sc, 64 * sc);
		Screen.DrawText(SmallFont, Font.CR_GREEN, 12, 10, "R.E.P.O. HAUL", DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);
		Screen.DrawText(SmallFont, Font.CR_GOLD, 6, 10, String.Format("$%s", Money(haul)), DTA_VirtualWidth, vw / 2, DTA_VirtualHeight, vh / 2);
		Screen.DrawText(SmallFont, Font.CR_WHITE, 12, 38, String.Format("Quota $%s", Money(quota)), DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);
		int bw = 138 * sc;
		int fill = min(bw, bw * haul / max(1, quota));
		Screen.Clear(12 * sc, 50 * sc, 12 * sc + bw, 54 * sc, 0x303030);
		Screen.Clear(12 * sc, 50 * sc, 12 * sc + fill, 54 * sc, flashUntil > level.maptime ? 0xFFFFFF : 0x40D040);
		if (extractions > 0 || lost > 0)
		{
			Screen.DrawText(SmallFont, Font.CR_CYAN, 12, 58, String.Format("Banked $%s   Lost $%s", Money(bank), Money(lost)), DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);
		}

		// Floating +$ / -$ lines.
		for (int i = 0; i < popTxt.Size(); i++)
		{
			int age = level.maptime - popTic[i];
			if (age > 100) continue;
			double al = age > 70 ? (100 - age) / 30.0 : 1.0;
			Screen.DrawText(SmallFont, popGood[i] ? Font.CR_GOLD : Font.CR_RED, 12, 74 + i * 10 - age / 12,
				popTxt[i], DTA_VirtualWidth, vw, DTA_VirtualHeight, vh, DTA_Alpha, al);
		}
	}
}
