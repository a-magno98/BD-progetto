SET search_path TO "progetto";

-------------------------------------------------------------PUNTO 1 - INTERROGAZIONI SEMPLICI ---------------------------------------------------------------------
 --PARTE COMUNE--

--Gli studenti che hanno superato i corsi a cui erano iscritti
SELECT Iscritto.Utente
FROM Iscritto
WHERE Superato;

--I corsi in modalità self-study
SELECT Id
FROM Corso
WHERE Modalità = 'S';

--I corsi per cui non è ancora stata definita la data di inizio
SELECT Edizione.Corso
FROM Edizione
WHERE Edizione.DataIn IS NULL;

--Il numero di edizioni dei corsi
SELECT Edizione.Corso, COUNT(*)
FROM Edizione
GROUP BY Edizione.Corso;

--Le categorie con e senza corsi
SELECT Categoria.Nome, Corso.Id
FROM Categoria LEFT JOIN Appartiene ON Appartiene.Categoria = Categoria.Nome LEFT JOIN Corso ON Corso.Id = Appartiene.Corso
GROUP BY Categoria.Nome, Corso.Id;


--Elenco dei corsi che iniziano da qui ai prossimi 30 giorni
SELECT Categoria
FROM Appartiene JOIN Corso ON Corso.Id = Appartiene.Corso
				JOIN Edizione ON Edizione.Corso = Corso.Id
WHERE DataIn IS NOT NULL AND EXTRACT(MONTH FROM DataIn) = EXTRACT(MONTH FROM CURRENT_DATE)+1 AND EXTRACT(DAY FROM DataIn) = EXTRACT(DAY FROM CURRENT_DATE);

--Elenco dei corsi che non hanno la data di inizio definita (Differenza)
SELECT Edizione.Corso
FROM Edizione
EXCEPT
SELECT Edizione.Corso
FROM Edizione
WHERE DataIn IS NOT NULL;

--PARTE A SCELTA--

--Elenco degli assignment di tipo esercizio che non sono stati superati (Differenza)
SELECT Assignment.Id
FROM Assignment
WHERE Tipo='E'
EXCEPT
SELECT Esercizio
FROM HaSuperato
ORDER BY Id;

--Elenco degli assignment di tipo esercizio consegnati e non 
--Per avere quelli consegnati basta una select sulla tabella consegnati, al contrario per avere quelli non ancora consegnati, si possono ottenere tramite una differenza
--Outer join
SELECT Assignment.Id, Consegna.DataC
FROM Assignment LEFT JOIN Consegna ON Assignment.Id = Consegna.Assignment
WHERE Tipo = 'E';


--------------------------------------------PUNTO 2 - INSERT, DELETE, UPDATE - MANIPOLAZIONE DEI DATI ------------------------------------------------------------------------

--PARTE COMUNE--

--UPDATE--

--Aggiornamento della data di inizio di un corso per cui era stata prevista una nuova edizione
UPDATE Edizione
SET DataIn = '08/09/2019' WHERE Corso = 'info04';
--Aggiornamento che viola il vincolo di chiave univoca
UPDATE Categoria
SET Nome = 'Informatica';

--INSERT--

INSERT INTO Categoria VALUES('Letteratura');
--Inserimento di un'attivita 
INSERT INTO Attivita VALUES('IN301', '08/09/2019', '14/09/2019', 01, 'info04');
--Inserimento che viola il vincolo di chiave univoca
INSERT INTO Categoria VALUES('Informatica');
--Inserimento che viola il vincolo di chiave esterna
INSERT INTO Appartiene VALUES('info05', 'Informatica');

--DELETE--

--Delete che viola vincolo di chiave esterna, è referenziata da altre tabelle
DELETE FROM Corso
WHERE Id = 'info02';


--PARTE A SCELTA--

--UPDATE--

--Aggiornamento che viola il vincolo di chiave univoca
UPDATE Assignment
SET Id = 'IE204' WHERE Id = 'IE203';

--INSERT--

--Inserimento Assignment per l'attività  sopra inserita
INSERT INTO Assignment VALUES('IE400', 'IN301', '14/09/2019', '20/09/2019', 'E', 01, 'info04', 18, false);

--Inserimento che viola il vincolo di chiave primaria e di chiave esterna
INSERT INTO Assignment VALUES('IE400', 'IN400', '15/09/2019', '21/09/2019', 'E', 01, 'info05', 19, false);

--DELETE--
--Delete che viola vincolo di chiave esterna, è referenziata da altre tabelle
DELETE FROM Assignment
WHERE Id = 'FE300';


--------------------------------------------------------------PARTE 3 - INTERROGAZIONI DI ANALISI (GROUP BY, OPERAZIONI INSIEMISTICHE, DIVISIONE....) ---------------------------

 --PARTE COMUNE--
 
--GROUP BY--

--Per ogni corso, il numero di video proposti
SELECT Corso.Id, COUNT(*)
FROM Corso JOIN Materiale ON Materiale.Corso = Corso.Id
WHERE Tipo = 'V'
GROUP BY Corso.Id
ORDER BY Corso.Id;

--Per ogni categoria, il numero di corsi a disposizione
SELECT Appartiene.Categoria, COUNT(*)
FROM Appartiene
GROUP BY Appartiene.Categoria;

--L'elenco dei docenti che insegnano almeno un corso
SELECT Insegna.Docente, Insegna.Corso
FROM Insegna JOIN Docente ON Insegna.Docente = Docente.Email
GROUP BY Insegna.Docente, Insegna.Corso
HAVING COUNT(*)>=1
ORDER BY Insegna.Docente, Insegna.Corso;

--DIVISIONE--
--Gli utenti iscritti a tutti i corsi disponibili
SELECT Iscritto.Utente 
FROM Iscritto
GROUP BY Iscritto.Utente
HAVING COUNT(Iscritto.Corso) >=(SELECT COUNT(*) FROM Corso);

--SOTTO QUERY--
--I corsi la cui categoria/e iniziano con la lettera I
SELECT Appartiene.Corso
FROM Appartiene
WHERE Appartiene.Categoria IN (SELECT Appartiene.Categoria FROM Appartiene WHERE Appartiene.Categoria LIKE 'I%');


--PARTE A SCELTA--

--GROUP BY--

--Elenco degli assignment superati, comprensivi della media e del numero (Group by)
SELECT Iscritto.Corso, Utente.Email, AVG(HaSuperato.Voto), COUNT(HaSuperato.Voto)
FROM Iscritto JOIN Utente ON Utente.Email = Iscritto.Utente JOIN HaSuperato ON HaSuperato.Utente = Utente.Email
WHERE Utente.Ruolo = 'Studente'
GROUP BY Iscritto.Corso, Utente.Email
ORDER BY Iscritto.Corso;

--Lo studente/i che ha superato l'assignment IE204 con la valutazione maggiore
SELECT HaSuperato.Utente, HaSuperato.Voto
FROM HaSuperato
WHERE HaSuperato.Esercizio = 'IE204'
GROUP BY HaSuperato.Utente, HaSuperato.Voto
HAVING HaSuperato.Voto >=ALL(SELECT HaSuperato.Voto FROM HaSuperato WHERE HaSuperato.Esercizio = 'IE204');

--Per ogni assignment di tipo esercizio, il voto più alto registrato e il voto più basso
SELECT HaSuperato.Esercizio, MAX(Voto) AS MassimoVotoRegistrato, MIN(Voto) AS MinimoVotoRegistrato
FROM HaSuperato
GROUP BY HaSuperato.Esercizio;

--Lo/i studente/i con la media più alta e quello con la media più bassa
SELECT Utente, AVG(Voto)
FROM HaSuperato
GROUP BY Utente
HAVING AVG(Voto) >= ALL(SELECT AVG(Voto) FROM HaSuperato GROUP BY HaSuperato.Utente)
UNION
SELECT Utente, AVG(Voto)
FROM HaSuperato
GROUP BY Utente
HAVING AVG(Voto) <= ALL(SELECT AVG(Voto) FROM HaSuperato GROUP BY HaSuperato.Utente);

--DIVISIONE--
--Gli studenti che hanno fatto tutti gli assignment di tipo esercizio previsti per il corso a cui erano iscritti
SELECT Consegna.Utente
FROM Consegna JOIN Utente ON Utente.Email = Consegna.Utente JOIN Iscritto I ON I.Utente = Utente.Email
GROUP BY Consegna.Utente, I.Corso
HAVING COUNT(*) = (SELECT COUNT(*) FROM Assignment WHERE Assignment.Corso = I.Corso AND Assignment.Tipo = 'E');

--SOTTO-INTERROGAZIONE--
--Studenti che hanno consegnato degli assignment e che hanno partecipato alla peer evaluation (Si può fare anche tramite intersezione)
SELECT DISTINCT Consegna.Utente
FROM Consegna
WHERE Consegna.Utente IN (SELECT Peer.Studente FROM Peer)
ORDER BY Consegna.Utente;

SELECT Consegna.Utente
FROM Consegna
INTERSECT
SELECT Peer.Studente
FROM Peer
ORDER BY Utente;


--Studenti che hanno consegnato assignment, ma non hanno partecipato alla peer evaluation
SELECT DISTINCT Consegna.Utente
FROM Consegna
WHERE Consegna.Utente NOT IN (SELECT Peer.Studente FROM Peer)
ORDER BY Consegna.Utente;







--INSERT PER TRIGGER--

--Inserimento che attiva il trigger CheckUtenteConsegna
INSERT INTO Consegna VALUES(19,'13/09/2019','jacopo.cremonesi@unige.it', 'IE400', false);

--Inserimento che attiva il trigger CheckIscrizioneEdizione
INSERT INTO Edizione VALUES(02, 'fis03', '09/09/2019', 13, 2);
INSERT INTO Iscritto VALUES('christian.trentino@unibo.it', 'fis03', 02, false, '14/07/2019');

--Inserimento che attiva il trigger checkPeer
INSERT INTO Peer VALUES('IE100', 'emma.polisi@unifi.it', '01/03/2019 19:15:13', 'marco.lucchese@unige.it', 'lorenzo.mancini@unige.it', '08/03/2019', 28, 0.30,'09/03/2019 16:13:15');

--Inserimento che attiva il trigger checkConsegna
--Essendo già presente nella tabella, la query genera una violazione di chiave primaria. Togliendo momentaneamente dalla tabella tale query, si vede il funzionamento del trigger
INSERT INTO Peer VALUES('FE300', 'christian.trentino@unibo.it', '02/02/2019 09:13:54', 'tiziano.napolitani@unibo.it', 'susanna.moretti@unifi.it', '06/02/2019 09:00:00', 28,0.30, '09/02/2019 17:52:30');

--Inserimento che attiva il trigger checkHDL
INSERT INTO Assignment VALUES('IE401', 'IN301', '21/09/2019', '19/09/2019', 'E', 01, 'info04', 18, false);

--Inserimento che attiva il trigger checkIscrizione
INSERT INTO Iscritto VALUES('bacco.baresi@unito.it', 'fis02', 01, DEFAULT, '16/03/2019');

--Inserimento che attiva il trigger checkVideo
INSERT INTO Visionato VALUES('VI0028','serena.lofere@univda.it');

--Inserimento che attiva il trigger checkTipoQuiz
INSERT INTO Consegna VALUES(19,'13/05/2019','emma.polisi@unifi.it', 'IQ100', false)

--Inserimento che attiva il trigger checkTipoEsercizio
INSERT INTO Domande VALUES('IE100', 'DI100', 'Domanda1');

--Non ci sono tuple idonee all'attivazione del trigger checkPartecipazione

--CHECK AGGIUNTIVI--

ALTER TABLE Peer
ADD CHECK (DataAss>DataEs);
