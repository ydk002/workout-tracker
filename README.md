# FitLog - Edzésnapló Flutter PWA

Egy 100% offline-first, súlyzós edzéskövető Progressive Web App (PWA) Flutter és Riverpod alapokon.

---

## 🚀 Főbb Képességek és Funkciók

1. **Élő Edzéskövető (Active Workout Tracker):**
   - Gyors sorozat naplózás: súly (kg) és ismétlésszám (reps).
   - Előző edzés teljesítményének automatikus megjelenítése az adott szettnél (pl. `80 kg × 8`).
   - Egy koppintásos befejezés (zöldre váltás).
   - Beépített pihenőidőzítő (60s, 90s, 120s, 180s, +30s gomb, hangjelzéssel).
   - Dinamikus gyakorlat hozzáadása edzés közben is.

2. **Gyakorlattár (Exercise Library):**
   - Több tucat beépített alapgyakorlat izomcsoportok szerint (Mell, Hát, Láb, Váll, Bicepsz, Tricepsz, Has/Törzs).
   - Új egyéni gyakorlatok létrehozása és törlése.
   - Valós idejű kereső és szűrők.

3. **Edzéstervek és Sablonok (Templates):**
   - Beépített és egyéni tervek (Push, Pull, Legs, stb.).
   - Egyetlen gombnyomással indítható teljes edzés egy sablon alapján.

4. **Előzmények és Napló:**
   - Időrendi áttekintés a korábbi edzésekről.
   - Részletes sorozat- és súlybontás lenyitható kártyákon.
   - Korábbi bejegyzések törlésének lehetősége.

5. **Fejlődés és Statisztikák (Grafikonok):**
   - Interaktív edzésvolumen grafikon (`fl_chart` BarChart az utolsó edzések volumenének alakulásáról).
   - Személyes Rekordok (PR Dicsőségtábla) automatikus nyilvántartása gyakorlatonként.
   - Összesített edzésszám, megmozgatott összvolumen és átlagos időtartam.

6. **100% Offline Adatbázis & Biztonsági Mentés:**
   - Lokális IndexedDB / Hive perzisztencia (nem igényel internetkapcsolatot vagy szervert).
   - **JSON Export:** teljes adatbázis letöltése `.json` fájlként.
   - **JSON Import:** korábbi mentés visszaállítása fájl feltöltésével vagy beillesztéssel.

---

## 💻 Fejlesztői futtatás

### Webes tesztelés helyben (Chrome):
```bash
cd workout_tracker
flutter run -d chrome
```

### PWA telepítés okostelefonra:
1. Nyisd meg az alkalmazást a mobilod böngészőjében (Safari vagy Chrome).
2. Válaszd a **Megosztás** vagy a menüben a **"Hozzáadás a kezdőképernyőhöz"** (*Add to Home Screen*) lehetőséget.
3. Az alkalmazás ikonként megjelenik a telefonodon és teljes képernyős natív élményt nyújt.
