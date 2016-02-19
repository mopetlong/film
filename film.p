/* Tabulka parametrov pre aplikaciu */
def temp-table t-param
  field nr as int
  field typ as char
  field wert as char
  index nr nr
.  

/* Nacitanie parametrov zadanych pri starte aplikacie.
   Format je:
   mbpro -p film.p -param "input:film.json,prot:protSh.txt,vrat:1,pozicaj:2"
    > film.sh.prot
*/
function readParam returns log (p-param as char):
  def var l-param as char no-undo.
  def var l-index as int no-undo.
  def var l-count as int no-undo.
  def var l-entry as char no-undo.
  def var l-ok as log no-undo.
  
  l-ok = true.
  /* Parametre su za retazcom "-param" */
  l-index = index(p-param,"-param").
  if l-index > 0 then l-param = trim(substring(p-param,l-index)).
  if num-entries(l-param," ") > 1 then l-param = entry(2,l-param," ").
  if l-param > "" then do:
    repeat l-count = 1 to num-entries(l-param):
      l-entry = entry(l-count,l-param).
      /* mali by byt vo formate "typ:wert,typ:wert..." */
      if num-entries(l-entry,":") = 2 then do:
        create t-param.
        t-param.nr = l-count.
        t-param.typ = entry(1,l-entry,":").
        t-param.wert = entry(2,l-entry,":").
      end.
      else l-ok = false.
    end.
  end.  
  else l-ok = false.
  return l-ok.
end function.

/* Funkcia testuje parametre na povolene hodnoty: "input,prot,vrat,pozicaj".
   Tiez kontroluje ci pre "vrat,pozicaj" je hodnota integer
*/   
function testParam returns char ():
   def var l-id as int no-undo.
   for each t-param:
     if lookup(t-param.typ,"input,prot,vrat,pozicaj") = 0 then do:
       return "nepovoleny parameter " + t-param.typ.
     end.
     if lookup(t-param.typ,"vrat,pozicaj") > 0 then do:
       l-id = int(t-param.wert) no-error.
       if error-status:error then 
         return "nepovolena hodnota parametra " + t-param.typ.
     end.
   end.
   return "".
end function.

/* Pouziva sa pre ziskanie hodnoty parametrov "input" a "prot". */
function getFile returns char (p-typ as char):
  find first t-param where t-param.typ = p-typ no-error.
  return if avail t-param then t-param.wert else ?.
end.

/* Ak nie su prametre zadane spravne, zapise chybovu spravu do error suboru */
function messageParam returns log ():
 message "nespravne parametre: Format ma byt:"
    "-param typ:wert,typ:wert.."
    "typ moze byt: input,prot,vrat alebo pozicaj".
  for each t-param:
    message t-param.nr t-param.typ t-param.wert.
  end.
end.

def var l-ok as log no-undo.
def var l-file as char no-undo.
def var l-prot as char no-undo.
def var l-film as film no-undo.
def var l-pocetDni as int no-undo.
def var l-error as char no-undo.

/* Nacitanie parametrov. */
l-ok = readParam(SESSION:STARTUP-PARAMETERS).
if not l-ok then do:
  messageParam().
  return.
end.
  
/* Kontrola parametrov */
l-error = testParam().
if l-error > "" then do:
  message l-error.
  return.
end.

/* Nacitanie hodnot pre vstupny subor a protokol. */
l-file = getFile("input").
l-prot = getFile("prot").
if l-file = ? or l-prot = ? then do:
  message messageParam().
  return.
end.  

/* Nacitanie filmov zo vstupneho suboru (format JSon). */
l-film = new film(l-file,l-prot).
/* Kontrola uspesneho nacitania */
if not l-film:existFilm() then do:
  message "Chyba pri nacitani vstupneho suboru.".
  return.
end.  

/* Vypis vsetkych filmov do protokolu. */
l-film:listAllFilms().

/* Spracovanie parametrov "vrat" a "pozicaj" */
for each t-param:
  case t-param.typ:
    when "vrat" then do:
      l-pocetDni = l-film:vratFilm(int(t-param.wert),today).
      message "Vrat film:" t-param.wert + ", navratova hodnota:" l-pocetDni.
    end.  
    when "pozicaj" then do:
      l-ok = l-film:pozicajFilm(int(t-param.wert),today).
      message "Pozicaj film:" t-param.wert + ", navratova hodnota:" l-ok.
    end.  
  end case.
end.

/* Vypis vsetkych filmov do protokolu po spracovani. */
l-film:listAllFilms().


