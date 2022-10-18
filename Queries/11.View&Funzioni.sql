SET search_path TO "progetto";

-------VIEW------------------
CREATE VIEW VotiEsercizi AS
SELECT utente, Consegna.Voto, assignment, Peer.Voto AS PeerVote, Assignment.Soglia, Peer.Peso
FROM consegna JOIN assignment ON Assignment.id = Consegna.Assignment JOIN Peer ON Peer.Elaborato = Consegna.Assignment and Peer.Esecutore = Consegna.Utente
WHERE peer;

CREATE VIEW Consegnati AS
SELECT assignment, dataC, voto, utente, penalizzato, HDL
FROM consegna join assignment on assignment.id = Consegna.assignment
WHERE HDL IS NOT NULL AND Tipo = 'E'
ORDER BY assignment, utente;

CREATE VIEW NotPeer AS
SELECT Utente, Assignment, Voto, Soglia
FROM Consegna JOIN Assignment ON Assignment.Id = Consegna.Assignment
WHERE NOT Assignment.Peer;

CREATE VIEW PeerEvaluation AS
SELECT DataV, Utente, HDL
FROM Peer JOIN Consegna ON Consegna.Assignment = Peer.Elaborato JOIN Assignment ON Consegna.Assignment = Assignment.Id;

CREATE VIEW Quiz AS
SELECT Utente,Quiz,SUM(Punti) AS Voto, Soglia
FROM Scelta JOIN Risposte ON Scelta.Risposta = Risposte.IdRisposta AND Scelta.Domanda = Risposte.Domanda AND Risposte.Assignment = Scelta.Quiz JOIN Assignment ON Risposte.Assignment = Assignment.Id
GROUP BY Utente, Quiz, Soglia;


CREATE VIEW AssignmentSuperati AS
SELECT Utente, E.Corso AS Corso,E.NumeroEd AS Edizione, AVG(Voto) AS Media, Corso.Soglia AS Soglia
FROM HaSuperato	JOIN Assignment ON Assignment.Id = HaSuperato.Esercizio 
	        JOIN Edizione E ON Assignment.Corso = E.Corso AND Assignment.Edizione = E.NumeroEd 
	        JOIN Corso ON E.Corso = Corso.Id
GROUP BY Utente, E.Corso, Corso.Soglia, E.NumeroEd
HAVING COUNT(*) = (
		   SELECT COUNT(*) AS NumeroAssignment
		   FROM Assignment JOIN Edizione ON Edizione.Corso = Assignment.Corso AND Edizione.NumeroEd = Assignment.Edizione
		   WHERE Edizione.Corso = E.Corso)
ORDER BY E.Corso, Utente;

CREATE VIEW VideoVisionati AS
SELECT COUNT(*) AS NumeroVideo, Visionato.Utente As Utente
FROM Visionato JOIN Materiale ON Materiale.Id = Visionato.Video JOIN Corso C ON Materiale.Corso = C.Id
GROUP BY Visionato.Utente, C.Id
HAVING COUNT(*) = (SELECT COUNT(*) FROM Materiale JOIN Corso ON Materiale.Corso = Corso.Id WHERE Tipo = 'V' AND Corso.Id = C.Id);

-----------------FUNZIONI-----------------
--Funzione per calcolare la media tra il voto preso con la consegna "normale" e la peer evaluation. Solo i due voti risultano essere più alti della soglia prefissata per il singolo assignment,
--la tupla viene inserita all'interno della relazione HaSuperato
CREATE FUNCTION CalcolaMedia() 
RETURNS void
AS $$
declare
UtenteU	VARCHAR;
Eserc	VARCHAR;
VotoA	NUMERIC(2,0);
VotoB	NUMERIC(2,0);
SogliaS  NUMERIC(2,0);
PesoP	NUMERIC(3,2);
Media	NUMERIC(4,2);
valCr CURSOR FOR SELECT Utente, Voto, Assignment, PeerVote, Soglia, Peso FROM VotiEsercizi;
BEGIN
open valCr;
FETCH valCr INTO UtenteU, VotoA, Eserc, VotoB, SogliaS, PesoP;
WHILE FOUND LOOP
	BEGIN
		IF(VotoA>=SogliaS AND VotoB>=SogliaS) THEN
			Media = (VotoA+(VotoB*PesoP))/(1+PesoP);
			RAISE NOTICE 'Media %', Media;
			IF((UtenteU, Eserc) NOT IN (SELECT Utente,Esercizio FROM HaSuperato)) THEN
				INSERT INTO HaSuperato VALUES(UtenteU, Eserc, Media);
			END IF;
		END IF;
		FETCH valCr INTO UtenteU, VotoA, Eserc, VotoB, SogliaS, PesoP;
	END;
END LOOP;
CLOSE valCr;
END;
$$
language 'plpgsql';

--Funzione per calcolare il voto finale applicata un'eventuale penalizzazione. Viene applicata ai voti presi con consegna "normale"
CREATE FUNCTION CalcolaVoto()
RETURNS void
AS $$
declare
Esercizio		VARCHAR;
DataConsegna		TIMESTAMP;
DataUltima		TIMESTAMP;
UtenteU			VARCHAR;
Pen			BOOLEAN;
valCr CURSOR FOR SELECT Consegnati.Assignment, DataC,Utente,Penalizzato, HDL  FROM Consegnati;
BEGIN
open valCr;
FETCH valCr INTO Esercizio, DataConsegna, UtenteU, Pen, DataUltima;
WHILE FOUND LOOP
	BEGIN
		if(DataConsegna>DataUltima AND NOT Pen) then
			update Consegna
			set Voto = Voto - (Voto*0.40), Penalizzato=TRUE WHERE Consegna.Assignment = Esercizio AND Consegna.Utente = UtenteU  ;
		end if;
		FETCH valCr INTO Esercizio, DataConsegna, UtenteU, Pen, DataUltima;
	END; 
END LOOP;
close valCr;
END;
$$
language 'plpgsql';

--Funzione per inserire gli assignment superati che non prevedono una valutazione tra studenti. Vengono inseriti nella relazione HaSuperato solo nel caso in cui i voti siano superiori alla soglia imposta
CREATE FUNCTION InsertNotPeer() 
RETURNS void
AS $$
DECLARE
UtenteU		VARCHAR;
Esercizio	VARCHAR;
VotoV		NUMERIC(2);
SogliaS		NUMERIC(2);
valCr CURSOR FOR SELECT Utente, Assignment, Voto, Soglia FROM NotPeer;
BEGIN
open valCr;
FETCH valCr INTO UtenteU, Esercizio, VotoV, SogliaS;
WHILE FOUND LOOP
BEGIN
	IF((UtenteU, Esercizio) NOT IN (SELECT Utente, HaSuperato.Esercizio FROM HaSuperato)) THEN
		IF(VotoV>=SogliaS) THEN
			INSERT INTO HaSuperato VALUES(UtenteU, Esercizio, VotoV);
			END IF;
	END IF;
	FETCH valCr INTO UtenteU, Esercizio, VotoV, SogliaS;
END;
END LOOP;
close valCr;
END;
$$ language 'plpgsql';

--Funzione per il calcolo della penalizzazione dovuta ad una consegna ritardataria nella peer evaluation. La penalizzazione è pari al 20% del voto conseguito con la consegna "normale"
CREATE FUNCTION PenalizzazionePeer()
RETURNS void
AS $$
DECLARE
DataUltima		TIMESTAMP;
DataValutaz		TIMESTAMP;
Stud			VARCHAR;
valCr CURSOR FOR SELECT DataV, Utente, HDL FROM peerevaluation;
BEGIN
	open valCr;
	FETCH valCr INTO DataValutaz, Stud, DataUltima;
	WHILE FOUND LOOP
	BEGIN
		IF(DataValutaz>DataUltima) THEN
			UPDATE Consegna
			SET Voto = Voto - (Voto*0.20), Penalizzato = TRUE WHERE Utente = Stud AND NOT Penalizzato;
		END IF;
		FETCH valCr INTO DataValutaz, Stud, DataUltima;
	END;
	END LOOP;
close valCr;
END;
$$language 'plpgsql';

--Funzione per l'inserimento dei quiz superati nella relazione HaSuperato
CREATE FUNCTION SuperamentoQuiz()
RETURNS void
AS $$
DECLARE
UtenteU		VARCHAR;
QuizQ	VARCHAR;
VotoV		NUMERIC(2);
SogliaS		NUMERIC(2);
valCr CURSOR FOR SELECT Utente, Quiz, Voto, Soglia FROM Quiz;
BEGIN
open valCr;
FETCH valCr INTO UtenteU, QuizQ, VotoV, SogliaS;
WHILE FOUND LOOP
BEGIN
	IF((UtenteU, QuizQ) NOT IN (SELECT Utente, HaSuperato.Esercizio FROM HaSuperato)) THEN
		IF(VotoV>=SogliaS) THEN
			INSERT INTO HaSuperato VALUES(UtenteU, QuizQ, VotoV);
			END IF;
	END IF;
	FETCH valCr INTO UtenteU, QuizQ, VotoV, SogliaS;
END;
END LOOP;
close valCr;
END;
$$ language 'plpgsql';

--Funzione per definire gli studenti che hanno superato i corsi a cui si sono iscritti
CREATE FUNCTION CorsiSuperati()
RETURNS void
AS $$ 
DECLARE
UtenteU		VARCHAR;
CorsoC		VARCHAR;
EdizioneE	NUMERIC(2);
MediaM		NUMERIC(2);
SogliaS		NUMERIC(2);
valCr CURSOR FOR SELECT Utente, Corso,Edizione, Media, Soglia FROM AssignmentSuperati;
BEGIN
open valCr;
FETCH valCr INTO UtenteU, CorsoC, EdizioneE, MediaM, SogliaS;
WHILE FOUND LOOP
BEGIN
	IF(MediaM>=SogliaS AND UtenteU IN(SELECT Utente FROM VideoVisionati)) THEN
		UPDATE Iscritto
		SET Superato = TRUE WHERE Utente = UtenteU AND Corso = CorsoC AND Edizione = EdizioneE;
	END IF;
	FETCH valCr INTO UtenteU, CorsoC, EdizioneE, MediaM, SogliaS;
END;
END LOOP;
close valCr;
END;
$$ language 'plpgsql';


--Chiamate di funzioni--
SELECT CalcolaVoto();
SELECT PenalizzazionePeer();
SELECT CalcolaMedia();
SELECT InsertNotPeer();
SELECT SuperamentoQuiz();
SELECT CorsiSuperati();


