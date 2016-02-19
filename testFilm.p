function testFilms returns log (
  p-file as char,
  p-prot as char)
:  
  def var l-film as film.
  def var l-ok as log no-undo.
  def var l-pocetDni as int no-undo.
  def var l-hodnota as char no-undo.

  /* Nacitanie filmov zo suboru (p-file). Protokol je v subore (p-prot). */
  l-film = new film(p-file,p-prot).
  /* Kontrola uspesneho nacitania */
  if not l-film:existFilm() then return false.

  /* Vypis vsetkych filmov do protokolu. */
  l-film:listAllFilms().

  /* Citanie hodnoty policka "Popis" filmu s Id=1. */
  l-hodnota = l-film:citajFilmHodnotu(1,"Popis").
  /* Citanie hodnoty policka "PosPoz" filmu s Id=2. */
  l-hodnota = l-film:citajFilmHodnotu(2,"PosPoz").

  /* Zapis hodnoty "Novy popis" do policka "Popis" filmu s Id=1. */
  l-film:zapisFilmHodnotu(1,"Popis","Novy popis").
  /* Zapis hodnoty "2015-12-23" do policka "PosPoz" filmu s Id=1. 
     Skonci s chybou, do policka "PosPoz" nie je mozne zapisovat.
  */
  l-film:zapisFilmHodnotu(1,"PosPoz","2015-12-23").
  /* Zapis hodnoty "2015-12-a3" do policka "PosVrat" filmu s Id=1.
     Skonci s chybou "2015-12-a3" nie je platny datum.
  */
  l-film:zapisFilmHodnotu(1,"PosVrat","2015-12-a3").

  /* Pozicanie filmu s Id=1. Skonci s chybou, film je pozicany */
  l-ok = l-film:pozicajFilm(1,today).
  /* Pozicanie filmu s Id=2. */
  l-ok = l-film:pozicajFilm(2,today).

  /* Vratenie filmu s Id=1. */
  l-pocetDni = l-film:vratFilm(1,today).
  /* Vratenie filmu s Id=3. Skonci s chybou, film nie je pozicany */
  l-pocetDni = l-film:vratFilm(3,today).

  /* Novy vypis vsetkych filmou do protokolu. */
  l-film:listAllFilms().
  return true.
end function.  

/* Nacitanie filmov zo suboru "film.json" (format JSon). */
testFilms ("film.json","protTest1.txt").

/* Nacitanie filmov zo suboru "film.nojson" (nie je format JSon). */
testFilms ("film.nojson","protTest2.txt").
testFilms("film.nojson","protTest2.txt").

/* Nacitanie filmov zo suboru "nofilm.txt" (neexistuje). */
testFilms("nofile.txt","protTest3.txt").
