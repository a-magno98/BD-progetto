set search_path to "progetto";

INSERT INTO Categoria VALUES('Informatica');
INSERT INTO Categoria VALUES('Matematica');
INSERT INTO Categoria VALUES('Fisica');
INSERT INTO Categoria VALUES('Chimica');

INSERT INTO Corso VALUES('info01', 'Sistemi Operativi', 'Introduzione ai sistemi operativi',17,'Kernel;FileSystem;Storage','Italiano', 'Conoscenza linguaggio C', DEFAULT, 'T', 'unige');
INSERT INTO Corso VALUES('info02', 'Database', 'Introduzione ai database',15,'Modello ER; Modello Relazionale; SQL', 'Italiano', 'Programmazione', DEFAULT, 'T', 'univda');
INSERT INTO Corso VALUES('info03', 'Programmazione Web', 'Introduzione alla programmazione web',16, 'HTML; JavaScript; PHP', 'Italiano', 'Reti', DEFAULT, 'S', 'unibo');
INSERT INTO Corso VALUES('info04', 'Programmazione', 'Introduzione alla programmazione', 17, 'Pseudocodice; Linguaggio C; Accenno Linguaggio C++', 'Italiano', 'C', DEFAULT, 'S', 'unibo');
INSERT INTO Corso VALUES('mate01', 'Analisi 1', 'Introduzione al calcolo matematico', 16,'Funzioni ad una variabile', 'Italiano', 'Matematica di base', DEFAULT, 'T', 'unito');
INSERT INTO Corso VALUES('mate02', 'Analisi 2',  'Calcolo matematico avanzato',18,'Funzioni a più variabili', 'Italiano', 'Analisi 1', DEFAULT, 'T', 'unimi');
INSERT INTO Corso VALUES('mate03', 'Fisica matematica',  'Principi della fisica applicati alla matematica', 15,'Teoremi e applicazioni', 'Italiano', 'Analisi 1', DEFAULT, 'T', 'unifi');
INSERT INTO Corso VALUES('fis01', 'Meccanica',  'Introduzione ai principi della fisica meccanica',15,'Forze', 'Italiano', 'Geometria, Concetto di forza', DEFAULT, 'S', 'unige');
INSERT INTO Corso VALUES('fis02', 'Elettrologia',  'Introduzione elettrodinamica',16,'Resistori; Condensatori; Induttanza', 'Italiano', 'Principi della fisica meccanica', DEFAULT, 'T', 'unito');
INSERT INTO Corso VALUES('fis03', 'Termodinamica','Introduzione alla termodinamica',18, 'Calore; Teoremi', 'Italiano', 'Principi della fisica meccanica', DEFAULT, 'T', 'unifi');
INSERT INTO Corso VALUES('chim01', 'Chimica 1',  'Introduzione alla chimica',17,'Elementi tavola periodica; Bilanciamento formule', 'Italiano','Matematica di base', DEFAULT, 'T', 'unimi');
INSERT INTO Corso VALUES('chim02', 'Chimica 2', 'Chimica avanzata',18,'Analisi formule complesse', 'Italiano', 'Chimica 1', DEFAULT, 'T', 'unige');

INSERT INTO Appartiene VALUES('info01', 'Informatica');
INSERT INTO Appartiene VALUES('info02', 'Informatica');
INSERT INTO Appartiene VALUES('info03', 'Informatica');
INSERT INTO Appartiene VALUES('info04', 'Informatica');
INSERT INTO Appartiene VALUES('mate01', 'Matematica');
INSERT INTO Appartiene VALUES('mate02', 'Matematica');
INSERT INTO Appartiene VALUES('mate03', 'Matematica');
INSERT INTO Appartiene VALUES('mate03', 'Fisica');
INSERT INTO Appartiene VALUES('fis01', 'Fisica');
INSERT INTO Appartiene VALUES('fis02', 'Fisica');
INSERT INTO Appartiene VALUES('fis03', 'Fisica');
INSERT INTO Appartiene VALUES('chim01', 'Chimica');
INSERT INTO Appartiene VALUES('chim02', 'Chimica');