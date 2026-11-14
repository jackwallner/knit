# Ravel localized App Store listings (49 locales), 2026-11-14

Version 1.0.0, not yet released, so there are no ranks to compare against. Everything below is a hypothesis from Apple autocomplete and the live search results (SERP) on 2026-11-14. Read the search-term data in App Store Connect two weeks after launch (ledger A-19) and replace any keyword that earns nothing.

Files: `fastlane/metadata/<locale>/` for all 49 locales besides en-US. Check them with `python3 scripts/validate-metadata.py` (exit 1 on any failure). Raw query output: `raw/2026-11-14-autocomplete-and-serp.txt`.

## Method

- Autocomplete (`MZSearchHints`) on 5 to 20 seed terms per market, about 510 queries, 3 threads, no HTTP 429. SERP (`itunes.apple.com/search`) for the head terms, about 100 queries. A bare term with no app name attached is a query Apple surfaces; a list of app names means apps target it.
- Rules kept from the audit (`project-docs/audit/ledger.md`): no Ravelry, competitor or trademark in any keyword field (A-17); the keyword field names no Apple hardware; "crochet" appears only in keywords and in the description's crochet bullet, never in a name or subtitle; counter and stash are the free hooks, the library is the paid product.
- Deliberate departure from ledger A-16 ("do not ship translated listings over an English UI"): the brief for this run asks for them. The risk it names (a reviewer or knitter expecting a translated app) is handled by one plain sentence in every non-English description, in a section headed language and units, placed before the subscription paragraph: the app and all patterns are English only, and lengths print in centimeters and meters outside the United States. Product screenshots stay English, so a listing in another language over them is an accuracy question under App Review 2.3.1. Jack should decide whether to ship the non-English locales before the app UI is translated, or hold them back and ship only the English variants.
- Voice: informal "you" (du, je, tu, ty and the Nordic du) where hobby apps in that market use it; formal (vous, вы, Czech/Slovak/Slovenian/Croatian/Greek plural-polite, Turkish) elsewhere.
- Designs are named in English in the description (Garter Scarf, Diagonal Dishcloth) because that is what the app shows; a native gloss follows in parentheses.

## Deep tier

Counts are characters. Competitor rating counts are from the SERP, 2026-11-14.

### en-GB

- Name: `Ravel: Knitting Patterns` (24). Subtitle: `Row Counter & Wool Stash` (24).
- Keywords (98): `yarn,jumper,tension,stitch,tracker,crochet,beginner,pdf,needle,project,hat,beanie,scarf,cowl,shawl`
- Evidence: autocomplete for "knitting" gives "knitting row counter", "knitting counter", "knitting chart", "free knitting patterns"; "row counter" gives "row counter free" and a run of "<app>: row counter" apps. "jumper pattern", "bobble hat", "tension" (knitting sense) return nothing, so UK vocabulary (jumper, tension, wool) is a bet on matching rather than on typed demand: the SERP for "jumper knitting pattern" does return knitting apps (LoopCraft 1,307, KnitsThatFit Sweaters 45). Winnable: "row counter" top 10 is My Row Counter 526, then 36, 17, 49, 27; "knitting patterns" is led by Loopsy 815 and a 30-rating app. "wool" in the subtitle because UK knitters say wool for yarn; "yarn" stays in keywords. "gauge" is dropped for "tension".

### en-AU

- Name and subtitle: `Ravel: Knitting Patterns`, `Row Counter & Yarn Stash`.
- Keywords (98): `wool,jumper,tension,stitch,tracker,crochet,beginner,pdf,needle,project,hat,beanie,scarf,cowl,shawl`
- Evidence: autocomplete mirrors GB ("knitting rows counter", "knitting counter", "knitting chart"). "beanie" is the Australian word for the hat; description says beanie, jumper, colour, centimetres. SERP "row counter": My Row Counter 260, then 16, 8, 20. "knitting patterns": YarnPal 3,497 leads, then 0 to 27 rating apps.

### en-CA

- Name and subtitle as en-AU.
- Keywords (98): `toque,sweater,gauge,stitch,tracker,crochet,beginner,pdf,needle,project,hat,beanie,scarf,cowl,shawl`
- Evidence: autocomplete "knitting row counter", "pocket knitting", "knitting counter". "toque" returns nothing in autocomplete (it is ranked as a spelling risk, but it is the Canadian word and costs 6 characters). Canadian spelling in the description (colour, centimetres), US knitting words (gauge, sweater, yarn). SERP "row counter": My Row Counter 779, then 20, 31, 50, 21.

### de-DE

- Name: `Ravel: Strickanleitungen` (24). Subtitle: `Reihenzähler & Wollvorrat` (25).
- Keywords (99): `stricken,strickmuster,häkeln,maschenprobe,stricknadel,pullover,mütze,schal,decke,wolle,pdf,anfänger`
- Evidence: autocomplete "stricken" gives "stricken reihen zählen", "stricken zähler", "stricken lernen", "stricken kostenlos"; "reihenzähler" gives "reihenzähler stricken", "reihenzähler fürs stricken"; "strickanleitung" and "strickanleitungen" are bare surfaced queries; "strickmuster" too. SERP "strickanleitung": top 10 are 51, 44, 1, 0, 0, 2, 0, 3, 0 ratings, so exact words win. "stricken" top: LooseLoop 116, Reihenzähler Stricken 65, Zähl Mich 376, addi2go 1,129. "stricken" sits in keywords because German does not split compounds, so the name word Strickanleitungen does not carry it.
- Du form. "Wollvorrat" for stash; "garn", "loop", "stirnband" fell off the 100-character cap.

### nl-NL

- Name: `Ravel: Breipatronen op maat` (27). Subtitle: `Rijenteller & garenvoorraad` (27).
- Keywords (99): `breien,haken,stekenproef,breinaalden,toerenteller,trui,muts,sjaal,wol,pdf,beginners,deken,col,garen`
- Evidence: autocomplete "breien" gives "toerenteller breien app" and a list of "<app>: haken & breien"; "rijenteller" gives "rijenteller voor haakwerk"; "breipatronen" gives "knitpad: breipatronen". "toerenteller" (literally rev counter) is how some Dutch apps and users name a row counter, so it is a keyword. SERP "breien": YarnPal 455, Yarnal 86, then 0 to 4. "rijenteller": top 9 are all 0 to 18 ratings. "op maat" (made to measure) fills the name honestly.

### sv

- Name: `Ravel: Sticka & Stickmönster` (28). Subtitle: `Varvräknare & garnförråd` (24).
- Keywords (98): `stickning,virka,stickor,maskprov,mössa,tröja,halsduk,ull,pdf,nybörjare,filt,sjal,garn,projekt,baby`
- Evidence: "varvräknare" gives "varvräknare - sticka & virka", "varvräknare sticka virka"; "stickning" gives "stickning: guider & mönster", "stickningsapp"; "stickmönster" gives "knitpad: stickmönster". SERP "varvräknare": 64, 0, 9, 1, 0; "sticka": Varvräknare 64, YarnPal 548, Hobbii 1,657. "stickrecept" and "stickapp" return nothing.

### da

- Name: `Ravel: Strikkeopskrifter` (24). Subtitle: `Strikketæller & garnlager` (25).
- Keywords (100): `strikke,rækketæller,pindetæller,hækle,strikkepinde,strikkefasthed,hue,sweater,halstørklæde,pdf,tæppe`
- Evidence: "strikke" gives "strikketæller", "strikkejournal", "strikkeberegner"; "pindetæller" gives two surfaced app names; "rækketæller" is a SERP-confirmed term (nine apps at 0 ratings). SERP "strikkeopskrifter" top: 10, 13, then 0 to 5. "strikke": Min strikkejournal 128, Hobbii 3,535.

### no

- Name: `Ravel: Strikkeoppskrifter` (25). Subtitle: `Strikketeller & garnlager` (25).
- Keywords (97): `omgangsteller,radteller,hekle,strikkepinner,strikkefasthet,lue,genser,skjerf,pdf,nybegynner,pledd`
- Evidence: "strikke" gives "strikketeller", "strikkekalkulator", "strikkebasen"; "omgangsteller" is a bare surfaced query; "strikkeapp" surfaces. SERP "strikke": Knitandnote 717, KNIT 532, Strikketeller 125, then single digits to 18; "radteller" top is all 0 to 78. Bokmål (`no`).

### fi

- Name: `Ravel: Neulonta & neuleohjeet` (29). Subtitle: `Kerroslaskuri & lankavarasto` (28).
- Keywords (98): `neulominen,virkkaus,puikot,silmukkatiheys,pipo,huivi,villapaita,lanka,pdf,aloittelija,peitto,neule`
- Evidence: "neulominen" and "neulonta" surface as queries; "kerroslaskuri" gives "kerroslaskuri" plus three "<app>: kerroslaskuri" names; "neuleohjeet" gives one SERP hit. SERP "neulominen": 17 results, top ratings 1, 0, 8, 0; "kerroslaskuri": 1, 5, 0, 0, 0. Thin market, so the name carries both the activity word and the pattern word.

### fr-FR

- Name: `Ravel : Patrons de tricot` (25, French spacing before the colon). Subtitle: `Compteur de rangs & pelotes` (27).
- Keywords (96): `laine,modèle,tricoter,crochet,échantillon,aiguilles,bonnet,pull,écharpe,snood,plaid,débutant,pdf`
- Evidence: "tricot" gives "tricot compte rang", "tricot gratuit", "apprendre a tricoter"; "compteur de rangs" gives "compteur de rangs tricot", "compteur de rangs au tricot". SERP "compteur de rangs": Compte Rangs 490, Muuch 2, then 0 to 12; "patron tricot": top ratings 1, 3,074, 5, 40, 12. Vous form (French hobby apps use it). Also indexed by the US storefront.

### ja

- Name: `Ravel: 編み物パターンと編み方` (18). Subtitle: `編み物の段数カウンターと毛糸管理` (16).
- Keywords (95): `編み図,棒針,かぎ針,ニット,セーター,帽子,マフラー,ゲージ,手編み,初心者,PDF,ブランケット,ショール,ネックウォーマー,プロジェクト,在庫,レシピ,スヌード,ニット帽,ヘッドバンド`
- Evidence: "編み物" gives "編み物カウンター", "編み物アプリ", "編み物 編み図"; "段数カウンター" gives eight surfaced app names; "毛糸 管理" gives "毛糸管理". SERP "編み物": 編み物カウンター２ 907, 編みものカウンター 238, あみも 172, YarnPal 1,446; "毛糸 管理": あみかん 60, けいと管理 49, then single digits. The patterns are written rows, not charts, so the name says 編み方 (how to knit) rather than 編み図; 編み図 stays a keyword because people open their own 編み図 PDFs in the counter. Polite です・ます.

### es-ES

- Name: `Ravel: Patrones de Punto` (24). Subtitle: `Contador de vueltas y lana` (26).
- Keywords (96): `tejer,ganchillo,crochet,muestra,tensión,agujas,jersey,gorro,bufanda,chal,manta,principiantes,pdf`
- Evidence: "tejer" gives "contador de vueltas: tejer", "tejer: tutoriales y patrones"; "contador de vueltas" gives "contador de vueltas para punto", "contador de vueltas tejer"; "patrones de tejido" surfaces. SERP "patrones de punto": Yarnpal 2,103, then 0 to 17; "contador de vueltas": 39 then 0 to 1. Tú form. "punto de cruz" (cross stitch) pollutes "punto", so "tejer" carries the intent.

### it

- Name: `Ravel: Schemi per la Maglia` (27). Subtitle: `Contagiri e gomitoli di lana` (28).
- Keywords (94): `uncinetto,lavoro,campione,ferri,cappello,maglione,sciarpa,scaldacollo,coperta,principianti,pdf`
- Evidence: "maglia" gives "lavoro a maglia", "maglia: tutorial e schemi"; "contagiri" gives "contagiri maglia", "contagiri maglia e uncinetto", "contagiri uncinetto". SERP "maglia": Lavoro a Maglia 37, LoopCraft 747, Conta Righe 45; "schemi maglia": top is Yarnpal 2,346 then 22, 1, 0. The app counts rows, the market says contagiri; the description says righe.

### pl

- Name: `Ravel: Wzory na drutach` (23). Subtitle: `Licznik rzędów, zapas włóczki` (29).
- Keywords (99): `druty,szydełko,dziergać,próbka,czapka,szalik,sweter,komin,szal,koc,pdf,początkujący,włóczka,projekt`
- Evidence: "licznik rzędów" surfaces with two app names; "szydełko", "druty", "włóczka" surface as queries. SERP "druty": YarnPal 499, then 0, 45, 0; "wzory na drutach": six results, ratings 0 to 45; "licznik rzędów": 0, 45, 0, 0. Name is 23, one short of the 24 target, because a natural phrase did not fill it.

## Other locales

Autocomplete on 5 to 10 seed terms, plus one or two SERP checks where the storefront returns results. Most of these markets return no autocomplete for the pattern terms (nobody is typing them or no app has claimed them), so vocabulary comes from app names that rank.

- es-MX: "estambre" is the Mexican word for yarn and surfaces; "contador de vueltas tejido" surfaces. Name `Patrones para Tejer`, subtitle names estambre, keywords use suéter, cobija, gancho.
- fr-CA: same French pattern name; Québec words tuque, chandail, foulard, cache-cou in keywords and copy. Autocomplete for "tricot" matches France.
- pt-BR: "contador de carreiras tricô", "tricô: tutoriais e receitas", "receita de tricô" surface; name uses "Receitas de Tricô". SERP "contador de carreiras" top is all 0 ratings.
- pt-PT: "tricot" and "malha" for knitting, "contador de carreiras" surfaces; camisola, ecrã, tu form.
- ru: "вязание спицами", "схемы вязания", "счетчик рядов вязание" surface; SERP "счетчик рядов" 83, 15, 1, 0. Uses вы.
- uk: "лічильник рядів" surfaces; SERP "в'язання" top are 0 to 9 ratings. Typographic apostrophe in в’язання.
- tr: "örgü modelleri", "örgü sayacı", "sıra sayacı" surface; SERP "sıra sayacı" top six are 0 to 1 ratings. Name is 21 characters (warning kept).
- cs: autocomplete empty except "háčkování"; SERP "pletení" and "počítadlo řádků" top results are 0 to 1 ratings.
- sk: autocomplete empty; SERP "počítadlo radov" 12 results, all 0 to 1.
- hu: "sorszámláló" surfaces (Pelote); SERP "kötés" and "sorszámláló" top results are 0 to 1. Name uses "Kötésminták méretre".
- ro: only "knitpad: scheme de tricotat" surfaces; SERP "tricotat" top results 0 to 1. Comma-below ș and ț.
- hr: only a competitor name surfaces; SERP "brojač redova" 24 results, all 0.
- sl-SI: no autocomplete and the SI storefront returns zero SERP results; copy follows Slovenian knitting vocabulary (pletenje, števec vrstic, preja).
- el: "μετρητής σειρών" surfaces (Pelote); SERP "πλέξιμο" top results all 0. Plural-polite imperative.
- ca: Catalan words (fer punt, mitja, comptador de voltes) get no autocomplete in the ES storefront; "mitja" surfaces mostly marathon queries, kept as a keyword for knitters who say "fer mitja".
- he: "סריגה" surfaces; the SERP call returned HTTP 400 for Hebrew terms and was not retried. Gender-neutral plural forms.
- ar-SA: "حياكة" surfaces with Patternrail's row counter; SERP "حياكة" top results 0 to 9 ratings. Name adds تريكو, the common loan word.
- ko: "뜨개질 단수 카운터", "뜨개질 도안", "단수 카운터" surface; SERP "뜨개질" top: Knitflow 90, 함께 떠요 116, YarnPal 214. The keyword field avoids 뜨개 because it sits inside the name.
- zh-Hans: "编织计数器", "行数计数器", "编织图解", "毛衣编织" surface; SERP "编织" top: 编织助手 66, 编织计数器 151. The subtitle is the exact phrase 编织计数器.
- zh-Hant: "編織計數器", "編織段數計數器" surface; SERP "編織" top: YarnPal 1,734, amimo 13. Garter described in words because no single Taiwan term was confirmed.
- th: "ถักไหมพรม" and "ไหมพรม" surface; SERP "ไหมพรม" is all yarn-sorting games above 299 ratings, so the name uses ถักไหมพรม (knitting with yarn) rather than the bare yarn word.
- vi: "đan len" and "móc len" surface; "len" is polluted by Lens/PDF apps, so the name carries "đan len". SERP "đan len": a puzzle game 8, Wool Escape 259, then 2.
- id: "merajut" and "benang wol" surface; SERP "merajut": Aplikasi belajar merajut 4, Merajut: Tutorial & Pola 0. "crochet" is spelled out in the stash bullet only (the Indonesian word mengait did not surface).
- ms: nothing surfaces for Malay terms; "knitting" itself surfaces with English app names, so keywords mix Malay (merajut, mengait) and common loans (sweater, beanie).
- hi: "बुनाई" surfaces only as a Knitpad chart app. The name uses the common search phrase "स्वेटर बुनाई"; keywords mix Hindi and the English words people type (knitting, sweater, crochet).
- bn-BD, gu-IN, kn-IN, ml-IN, mr-IN, or-IN, pa-IN, ta-IN, te-IN, ur-PK: autocomplete returned nothing for any native-script term on the IN, BD and PK storefronts. Each listing uses the market's word for knitting and sweater in the name, native stash and counter words in the subtitle, and a keyword field that pairs native garment words with English search words (knitting, sweater, crochet, beanie). These are the lowest-confidence translations in the set; a native reader should check them before launch, especially Odia, Malayalam, Kannada and the garter-stitch glosses.

## Validator

`python3 scripts/validate-metadata.py` checks all 50 locale folders: name and subtitle at most 30, keywords at most 100, description at most 4,000, promotional text 130 to 170 (65 to 85 for ja, ko, zh), no duplicate keyword tokens, no keyword repeated from the name or subtitle (word-level for spaced scripts, substring for ja, ko, zh, th), no blocked third-party keyword, no em dash or en dash used as a dash, no leading or trailing whitespace, a single-line field where required, URL files equal to en-US, both description links on their own line, both free design names, the 7 and 24 numbers of the subscription paragraph, an English-only sentence in every non-English description, no digit next to a currency sign or code, no superlative or rank claim, no "not one" style negation hook, no `release_notes.txt` outside en-US. It warns on short name (under 24), short subtitle, short keywords (under 94). Latest run: 50 locales, 0 failures, 3 warnings (kn-IN, pl and tr names are 23, 23 and 21 characters).

## Open items

- Decide whether the non-English locales ship with the English-only UI (see Method).
- Native-speaker pass on the Indic, Hebrew, Arabic, Thai and Vietnamese copy.
- Upload is not done; nothing here has touched App Store Connect.
- The `en-US` keyword field and the new `en-GB`, `en-AU`, `en-CA` fields do not overlap by design; the US storefront also indexes es-MX, ru, zh-Hans, zh-Hant, ar-SA, fr-FR, pt-BR, vi and ko, so those nine are extra keyword capacity for US searches as well as their own markets.
