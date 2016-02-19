class film:

  def stream s-in.
  def stream s-prot.
  
  /* Tabulka na ulozenie filmov */
  def private temp-table films no-undo
    field Id as int 
    field Nazov as char
    field DatVyd as date format "99.99.9999"   /* Datum vydania */
    field Dlzka as int
    field Popis as char
    field PosPoz as date format "99.99.9999"   /* Datum -posledne pozicanie */
    field PosVrat as date format "99.99.9999"  /* Datum -posledne vratenie */
    field Pozicany as log                      /* Film je pozicany */
    index Id Id
  .

  /* Nacita udaje vo formate JSon zo vstupneho suboru (p-file) 
     do tabulky filmov a otvori vystupny subor pre protokol (p-prot).
  */
  constructor public film(
    p-file as char,
    p-prot as char)
  :
    output stream s-prot to value(p-prot).
    nacitajJson(p-file).
  end constructor.
  
  /* Zatvori vystupny subor pre protokol. */
  destructor public film():
    output stream s-prot close.
  end destructor.

  /* Pomocna metoda. Kontroluje ci existuju nejake filmy, 
     ci nacitanie zo suboru bolo uspesne
  */    
  method public log existFilm ():
    return can-find(first films).
  end.
  
  /* Pomocna metoda pre zapis do protokolu. Vrati nazov metody, 
     z ktorej je zapis do protokolu volany. 
  */
  method private char getMethodName ():
    return entry(1,program-name(3)," ").
  end method.
    
  /* Metoda pre zapis do protokolu. Metody, ktore ju volaju pouzivaju p-typ:
     START pri starte metody,
     END pri ukonceni metody,
     ERROR pri chybe v metode.
     Pre lepsiu citatelnost protokolu je "ERROR" posunuty o dva znaky.
  */   
  method private void putProtokol (
    p-str as char,
    p-typ as char)
  :  
    def var l-str as char no-undo.
    l-str = if p-typ = "ERROR" then "  " else "".
    l-str = l-str + p-typ + " " + 
      getMethodName() + ": " +
      p-str + "\n".
    put stream s-prot unformatted l-str.
  end method.

  /* Pomocna metoda. Datum s hodnotou NULL transformuje na "?".
     Je potrebna pre spravny zapis do protokolu.
  */   
  method private char getUnk (p-date as date):
    if p-date = ? then return "?".
    else return string(p-date,"99.99.9999").
  end method.
 
  /* Pomocna metoda. Retazec s hodnotou NULL transformuje na "?".
     Je potrebna pre spravny zapis do protokolu.
  */   
  method private char getUnk (p-char as char):
    if p-char = ? then return "?".
    else return p-char.
  end method.
   
  /* Nacita udaje zo vstupneho suboru vo formate JSon,
     ak subor neexistuje, alebo neobsahuje spravne data, zapise chybu
     do protokolu. 
  */   
  method public log nacitajJson(
    p-file as char)
  :
    def var l-return as log init false no-undo.
    def var l-handle as handle no-undo.
    def var l-data as char no-undo.
    def var l-jsonData as longchar no-undo.

    putProtokol(substitute("p-file=&1",p-file),"START").  
    if search(p-file) = ? then do:
      putProtokol("vstupny subor neexistuje","ERROR").  
      return false.  
    end.
    input stream s-in from value(search(p-file)).
    import stream s-in unformatted l-data.
    input stream s-in close.
    l-jsonData = l-data.

    l-handle = temp-table films:handle.
    if trim(l-jsonData) = "" then
      putProtokol("vstupny subor je prazdny","ERROR").
    else if not valid-handle(l-handle) then 
      putProtokol("neplatna tabulka","ERROR").
    /* ak sa podarilo subor uspesne nacitat je l-return=True, inac je False */  
    else l-return = l-handle:read-json("longchar", l-jsonData, "empty")
      no-error.
    putProtokol(string(l-return,"OK/ERROR"),"END").
    return l-return.
  end method.

  /* Metoda vrati hodnotu pozadovane policka (p-field) daneho filmu (p-id).
     Zapise ju tiez do protokolu.
  */   
  method public char citajFilmHodnotu(
    p-id as int,
    p-field as char)
  :
    /* def buffer films for films. */
    def var l-return as char no-undo.

    putProtokol(substitute("p-id=&1 p-field=&2",p-id,p-field),"START").  
    do on error undo, retry:
      if retry then do:
        putProtokol("chyba pri spracovani","ERROR").  
        return "ERROR".
      end.  
      find first films no-lock where films.Id = p-id no-error.
      if not avail films then do:
        putProtokol("tabulka nacitanych udajov je prazdna","ERROR").  
        undo, retry.
      end.
      case p-field:
        when "Id" then l-return = string(films.Id).
        when "Nazov" then l-return = films.Nazov.
        when "DatVyd" then l-return = string(films.DatVyd,"99.99.9999").
        when "Dlzka" then l-return = string(films.Dlzka).
        when "Popis" then l-return = films.Popis.
        when "PosPoz" then l-return = string(films.PosPoz,"99.99.9999").
        when "PosVrat" then l-return = string(films.PosVrat,"99.99.9999").
        when "Pozicany" then l-return = string(films.Pozicany,"Ano/Nie").
      end case. /* p-field */
      putProtokol(getUnk(l-return),"END").  
      return l-return.
    end.
  end method.

  /* Pomocna metoda. Vracia integer hodnotu vstupneho retazca.
     Pripadnu chybu zapise do protokolu.
  */
  method private int getInt (p-char as char):
    def var l-int as int no-undo.

    putProtokol("p-char=" + p-char,"START").
    do on error undo, retry:
      if retry then do:
        putProtokol(substitute("p-char=&1 nie je integer",p-char),"ERROR").   
        return error.
      end.
      l-int = int(p-char) no-error.
      if error-status:error then undo, retry.
    end.    
    putProtokol("OK","END").  
    return l-int.
  end method.
  
  /* Pomocna metoda. Vracia hodnotu Datum zo vstupneho retazca.
     Vstupny retazec ocakava vo ISO-format RRRR-MM-DD.
     Pripadnu chybu zapise do protokolu.
  */
  method private date getDate (p-char as char).
    def var l-date as date no-undo.
    def var l-jahr as int no-undo.
    def var l-monat as int no-undo.
    def var l-tag as int no-undo.

    putProtokol("p-char=" + p-char,"START").  
    do on error undo, retry:
      if retry then do:
        putProtokol(substitute("p-char=&1 nie je platny datum",p-char),"ERROR").        return error.
      end.
      /* ma byt format RRRR-MM-DD */
      if length(p-char) <> 10 then undo, retry.
      else do:
        l-jahr = getInt(substring(p-char,1,4)).
        l-monat = getInt(substring(p-char,6,2)).
        l-tag = getInt(substring(p-char,9,2)).
        if l-jahr = ? or l-monat = ? or l-tag = ? then undo, retry. 
        l-date = date(l-monat,l-tag,l-jahr) no-error.
        if error-status:error then undo, retry.
      end.  
    end.    
    putProtokol("OK","END").  
    return l-date.
  end method.                        
  
  /* Pomocna metoda. Vracia logicku hodnotu vstupneho retazca.
     Pripadnu chybu zapise do protokolu. Ocakavane hodnoty su iba 
     "True" a "False"
  */
  method private log getLog (p-char as char).
    def var l-return as log no-undo.

    putProtokol("p-char=" + p-char,"START").  
    do on error undo, retry:
      if retry then do:
        putProtokol(
          substitute("p-char=&1 nie je platny logical",p-char),"ERROR").   
        return error.
      end.
      /* nur True oder False sind akceptiert */
      if p-char = "True" then l-return = true.
      else if p-char = "False" then l-return = false.
      else do:
        l-return = ?.
        undo, retry.
      end.
    end.
    putProtokol("OK","END").
    return l-return.    
  end method.
   
  /* Metoda sa pokusi zapisat do zvoleneho policka (p-field)
     uvedeneho filmu (p-id) zadanu hodnotu (p-wert). Nevracia ziadnu hodnotu.
     Pre vsetky policka ocakava hodnotu v tvare retazca. Povolene policka su:
     Id,Nazov,DatVyd,Dlzka,Popos,PosVrat a Pozicany.
  */   
  method public void zapisFilmHodnotu (
    p-id as int,
    p-field as char,
    p-wert as char)
  :
    def buffer films for films.
    def var l-date as date no-undo.
    def var l-int as int no-undo.
    def var l-log as logical no-undo.

    putProtokol(
      substitute("p-id=&1 p-field=&2 p-wert=&3",p-id,p-field,p-wert),"START").
    do on error undo, retry:
      if retry then do:
        putProtokol(
          substitute("p-field &1 Wert:&2 nie je platna hodnota",
          p-field,p-wert),"ERROR").   
        return.
      end.  
      find first films no-lock where films.Id = p-id no-error.
      if not avail films then do:
        putProtokol(substitute("p-id &1 film neexistuje",p-id),"ERROR").  
        return.
      end.
      case p-field:
        when "Id" then do:
          l-int = getInt(p-wert).
          films.Id = l-int.
        end.  
        when "Nazov" then films.Nazov = p-wert.
        when "DatVyd" then do:
          l-date = getDate(p-wert).
          films.DatVyd = l-date.
        end.  
        when "Dlzka" then do:
          l-int = getInt(p-wert).
          films.Dlzka = l-int.
        end.  
        when "Popis" then films.Popis = p-wert.
        when "PosVrat" then do:
          l-date = getDate(p-wert).
          films.PosVrat = l-date.
        end.  
        when "Pozicany" then do:
          l-log = getLog(p-wert).
          films.Pozicany = l-log.
        end.  
        otherwise do:
          putProtokol(substitute("&1 nie je mozne menit hodnotu",
            p-field),"ERROR"). 
          return.    
        end.
      end case. /* p-field */
    end.
    putProtokol("OK","END").  
  end method.  
  
  /* Metoda pre dany film (p-id) nastavy datum pozicania (p-date) 
     a zmeni policko "pozicany" na True. Metoda kontroluje ci film uz
     pozicany nie je. Ak je film pozicany ("pozicany"=True), nic nezmeni 
     a vrati hodnotu false. Ak p-date = NULL, nastavi datum pozicania 
     na dnesny datum.
  */
  method public log pozicajFilm (
    p-id as int,
    p-date as date)
  :
    def buffer films for films.
    def var l-date as date no-undo.
    def var l as char.

    putProtokol(substitute("p-id=&1 p-date=&2",p-id,getUnk(p-date)),"START").
    if p-date = ? then l-date = today.
    else l-date = p-date.
    do on error undo, retry:
      if retry then do:
        putProtokol("chyba pri spracovani","ERROR").
        return error.
      end.  
      find first films no-lock where films.Id = p-id no-error.
      if not avail films then do:
        putProtokol(substitute("&1 film neexistuje",p-id),"ERROR").  
        return error.
      end.
      else if films.pozicany then do:
        putProtokol(substitute("&1 film je pozicany",p-id),"ERROR").
        return false.
      end.
      else do transaction:
        films.PosPoz = l-date.
        films.pozicany = true.
        putProtokol("OK","END").
        return true.
      end.
    end.
  end method.  
 
 /* Metoda pre dany film (p-id) nastavi datum vratenia (p-date). Ak film
    nie je pozicany ("pozicany"=False), metoda nic nemeni a vrati hodnotu -1.
    Ak vratenie prebehlo uspesne, metoda vrati hodnotu ako dlho bol
    film pozicany (vrateny - pozicany, mozno by to malo byt 
    vrateny - pozicany + 1?). Ak p-date = NULL, nastavi datum vratenia 
    na dnesny datum. Ak nastala chyba vrati tiez -1.
  */  
  method public int vratFilm (
    p-id as int,
    p-date as date)
  :
    def buffer films for films.
    def var l-date as date no-undo.
    def var l-pocetDni as int no-undo.

    putProtokol(substitute("p-id=&1 p-date=&2",p-id,getUnk(p-date)),"START").
    if p-date = ? then l-date = today.
    else l-date = p-date.
    do on error undo, retry:
      if retry then do:
        putProtokol("chyba pri spracovani","ERROR").  
        return -1.
      end.  
      find first films no-lock where
        films.Id = p-id no-error.
      if not avail films then do:
        putProtokol(substitute("&1 film neexistuje",p-id),"ERROR").
        return -1.
      end.
      else if not films.pozicany then do:
        putProtokol(substitute("&1 film nie je pozicany",p-id),"ERROR").
        return -1.
      end.
      else do transaction:
        films.PosVrat = l-date.
        films.pozicany = false.
        l-pocetDni = films.PosVrat - films.PosPoz.
        putProtokol(substitute("pocet dni pozicania=&1",l-pocetDni),"END").  
        return l-pocetDni.
      end.
    end.
  end method.

  /* Pomocna metoda na vypis vsetkych filmov do protokolu */
  method public void listAllFilms ():
    def var l-handle as handle no-undo.
    def var l-ok as log no-undo.

    l-handle = temp-table films:handle.
    put stream s-prot unformatted "Vsetky filmy:\n".
    l-ok = l-handle:write-json("stream", "s-prot", true).
  end method.  

end class.    

