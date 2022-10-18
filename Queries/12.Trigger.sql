set search_path to "progetto";

--Trigger che controlla che gli assignment inseriti nella relazione peer, siano stati effettivamente prediposti per la peer evaluation
CREATE FUNCTION Checkpeer()
RETURNS trigger
AS $checkPeer$
BEGIN
	IF(EXISTS(SELECT * FROM Assignment JOIN Peer ON Peer.Elaborato = Assignment.Id WHERE NOT Peer)) THEN
		RAISE EXCEPTION 'Tale assignment non può essere assegnato nella peer evaluation';
	ELSE
		return new;
	END IF;
END;
$checkPeer$ language 'plpgsql';

CREATE TRIGGER CheckPeer
AFTER INSERT ON Peer
FOR EACH STATEMENT
EXECUTE PROCEDURE Checkpeer();

--Trigger che controlla che la data in cui viene assegnato un assignment per la valutazione tra studenti, sia successiva alla data di consegna prevista per quell'assignment
CREATE FUNCTION Checkconsegna()
RETURNS trigger
AS $checkconsegna$
BEGIN
	IF(EXISTS(SELECT * FROM Assignment JOIN Peer ON Peer.Elaborato = Assignment.Id WHERE Peer.DataAss<Assignment.Consegna)) THEN
		RAISE EXCEPTION 'La data di assegnazione di un elaborato è antecedente la data di consegna prevista';
	ELSE
		return new;
	END IF;
END;
$checkconsegna$ language 'plpgsql';

CREATE TRIGGER CheckConsegna
AFTER INSERT ON Peer
FOR EACH STATEMENT
EXECUTE PROCEDURE Checkconsegna();

--Trigger che controlla che la HDL, se definita, sia successiva alla data di consegna
CREATE FUNCTION CheckHDL()
RETURNS trigger
AS $checkhdl$
BEGIN
	IF(EXISTS(SELECT * FROM Assignment WHERE HDL IS NOT NULL AND HDL<Consegna)) THEN
		RAISE EXCEPTION 'La Hard Dead Line deve essere posteriore alla data di consegna';
	ELSE
		return new;
	END IF;
END;
$checkhdl$ language 'plpgsql';

CREATE TRIGGER checkHdl
AFTER INSERT ON Assignment
FOR EACH STATEMENT
EXECUTE PROCEDURE checkhdl();

--Trigger per il controllo delle iscrizioni ai corsi. L'iscrizione è permessa solo se la data di inizio dell'edizione è stata definita, e se non supera i 7 giorni dalla suddetta data
CREATE FUNCTION CheckIscrizione()
RETURNS trigger
AS $checkIscrizione$
BEGIN 
	IF(EXISTS(SELECT * FROM Iscritto JOIN Edizione ON Edizione.NumeroEd = Iscritto.Edizione AND Edizione.Corso = Iscritto.Corso WHERE Edizione.DataIn IS NULL OR DataIscr>DataIn+7)) THEN 
		RAISE EXCEPTION 'Impossibile accettare tale iscrizione';
	ELSE
		return new;
	END IF;
END;
$checkIscrizione$ language 'plpgsql';
			
CREATE TRIGGER checkIscri
AFTER INSERT ON Iscritto
FOR EACH ROW
EXECUTE PROCEDURE checkIscrizione();
			
--Trigger che controlla che l'utente consegni solo assignment del corso a cui è iscritto	
CREATE FUNCTION CheckUtenteConsegna()
RETURNS trigger
AS $checkUtCon$
DECLARE 
CorsoC	VARCHAR;
BEGIN
	SELECT INTO CorsoC Corso FROM Assignment WHERE Assignment.Id = NEW.Assignment;
	IF( CorsoC NOT IN (SELECT Corso FROM Iscritto WHERE Utente = NEW.Utente)) THEN
		RAISE EXCEPTION 'Non può essere effettuata la consegna';
	ELSE
		return new;
	END IF;
END;
$checkUtCon$ language 'plpgsql';
			
CREATE TRIGGER CheckUteCon
BEFORE INSERT ON Consegna
FOR EACH ROW
EXECUTE PROCEDURE checkUtenteConsegna();

--Trigger per il controllo delle iscrizioni. L'utente non può iscriversi ad un'edizione di un corso che ha già superato
CREATE FUNCTION DoppiaIscrizione()
RETURNS trigger
AS $doppiaiscrizione$
BEGIN
	IF(EXISTS(SELECT Utente FROM Iscritto WHERE Corso = NEW.Corso AND Utente = NEW.Utente AND Superato)) THEN 
		RAISE EXCEPTION 'Non è possibile iscriversi ad un corso già superato';
	ELSE
		RETURN new;
	END IF;
END;
$doppiaiscrizione$ language 'plpgsql';

CREATE TRIGGER CheckIscrizioneEdizione
BEFORE INSERT ON Iscritto
FOR EACH ROW
EXECUTE PROCEDURE DoppiaIscrizione();


CREATE FUNCTION checkVideo()
RETURNS trigger
AS $checkvideo$ 
DECLARE 
CorsoC	VARCHAR;
BEGIN
	SELECT INTO CorsoC Corso.Id FROM Visionato JOIN Materiale ON Materiale.Id = Visionato.Video JOIN Corso ON Materiale.Corso = Corso.Id WHERE Materiale.Id = NEW.Video;
	IF( CorsoC NOT IN (SELECT Corso FROM Iscritto WHERE Utente = NEW.Utente)) THEN
		RAISE EXCEPTION 'Non può visionare il video';
	ELSE
		return new;
	END IF;
END;
$checkvideo$ language 'plpgsql';

CREATE TRIGGER CheckVideo
BEFORE INSERT ON Visionato
FOR EACH ROW
EXECUTE PROCEDURE checkVideo();



--Trigger che garantisce che alla relazione consegna partecipino solo assignment di tipo esercizio
CREATE FUNCTION CheckEsercizio()
RETURNS trigger
AS $checkesercizio$
BEGIN
	IF(EXISTS(SELECT * FROM Consegna JOIN Assignment ON Assignment.Id = Consegna.Assignment WHERE Assignment.Tipo <> 'E')) THEN
		RAISE EXCEPTION 'Non è possibile consegnare un quiz';
	ELSIF(EXISTS(SELECT * FROM Domande JOIN Assignment ON Assignment.Id = Domande.Assignment WHERE Assignment.Tipo <> 'Q')) THEN
		RAISE EXCEPTION 'Non è possibile costruire domande su un esercizio';
	ELSE
		RETURN new;
	END IF;
END;
$checkesercizio$ language 'plpgsql';

CREATE TRIGGER CheckTipoEsercizio
AFTER INSERT ON Consegna
FOR EACH STATEMENT
EXECUTE PROCEDURE CheckEsercizio();

CREATE TRIGGER CheckTipoQuiz
AFTER INSERT ON Domande
FOR EACH STATEMENT
EXECUTE PROCEDURE CheckEsercizio();


--Trigger che garantisce la non partecipazione alle valutazioni tra studenti, per quelli che hanno già una penalizzazione per una consegna in ritardo nella consegna "normale"
CREATE FUNCTION checkPartecipazionePeer()
RETURNS trigger
AS $checkpartecipazione$
BEGIN
	IF(EXISTS(SELECT * FROM Consegna WHERE Penalizzato AND Consegna.Utente = NEW.Studente OR Consegna.Utente = NEW.Esecutore)) THEN
		RAISE EXCEPTION 'Lo studente è già stato penalizzato, non può partecipare alla valutazione fra pari';
	ELSE
		RETURN new;
	END IF;
END;
$checkpartecipazione$ language 'plpgsql';

CREATE TRIGGER CheckPartecipazione
AFTER INSERT ON Peer
FOR EACH ROW
EXECUTE PROCEDURE checkPartecipazionePeer();