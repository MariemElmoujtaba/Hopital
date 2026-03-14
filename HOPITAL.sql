-- Table SERVICE (pas de dépendances)
CREATE TABLE SERVICE (
    id_service   NUMBER PRIMARY KEY,
    nom_service  VARCHAR2(100) NOT NULL,
    capacite     NUMBER CHECK (capacite > 0)
);

-- Table PATIENT (pas de dépendances)
CREATE TABLE PATIENT (
    id_patient      NUMBER PRIMARY KEY,
    nom             VARCHAR2(100) NOT NULL,
    prenom          VARCHAR2(100) NOT NULL,
    date_naissance  DATE NOT NULL,
    telephone       VARCHAR2(20) UNIQUE,
    date_creation   DATE DEFAULT SYSDATE
);

-- Table MEDECIN (dépend de SERVICE)
CREATE TABLE MEDECIN (
    id_medecin  NUMBER PRIMARY KEY,
    nom         VARCHAR2(100) NOT NULL,
    specialite  VARCHAR2(100),
    id_service  NUMBER,
    CONSTRAINT fk_medecin_service FOREIGN KEY (id_service) REFERENCES SERVICE(id_service)
);

-- Table RENDEZ_VOUS (dépend de PATIENT et MEDECIN)
CREATE TABLE RENDEZ_VOUS (
    id_rdv      NUMBER PRIMARY KEY,
    id_patient  NUMBER NOT NULL,
    id_medecin  NUMBER NOT NULL,
    date_rdv    DATE NOT NULL,
    statut      VARCHAR2(20) DEFAULT 'Planifié'
                CHECK (statut IN ('Planifié','Annulé','Terminé')),
    CONSTRAINT fk_rdv_patient FOREIGN KEY (id_patient) REFERENCES PATIENT(id_patient),
    CONSTRAINT fk_rdv_medecin FOREIGN KEY (id_medecin) REFERENCES MEDECIN(id_medecin)
);

-- Table HOSPITALISATION (dépend de PATIENT et SERVICE)
CREATE TABLE HOSPITALISATION (
    id_hosp     NUMBER PRIMARY KEY,
    id_patient  NUMBER NOT NULL,
    id_service  NUMBER NOT NULL,
    date_entree DATE NOT NULL,
    date_sortie DATE,
    statut      VARCHAR2(20) DEFAULT 'En cours'
                CHECK (statut IN ('En cours','Terminé','Annulé')),
    CONSTRAINT fk_hosp_patient FOREIGN KEY (id_patient) REFERENCES PATIENT(id_patient),
    CONSTRAINT fk_hosp_service FOREIGN KEY (id_service) REFERENCES SERVICE(id_service)
);

-- Table FACTURE (dépend de PATIENT et HOSPITALISATION)
CREATE TABLE FACTURE (
    id_facture    NUMBER PRIMARY KEY,
    id_patient    NUMBER NOT NULL,
    id_hosp       NUMBER,
    montant_total NUMBER(10,2) DEFAULT 0 CHECK (montant_total >= 0),
    date_facture  DATE DEFAULT SYSDATE,
    CONSTRAINT fk_fact_patient FOREIGN KEY (id_patient) REFERENCES PATIENT(id_patient),
    CONSTRAINT fk_fact_hosp    FOREIGN KEY (id_hosp)    REFERENCES HOSPITALISATION(id_hosp)
);

-- Table PAIEMENT (dépend de FACTURE)
CREATE TABLE PAIEMENT (
    id_paiement   NUMBER PRIMARY KEY,
    id_facture    NUMBER NOT NULL,
    montant       NUMBER(10,2) NOT NULL CHECK (montant > 0),
    date_paiement DATE DEFAULT SYSDATE,
    mode_paiement VARCHAR2(50) CHECK (mode_paiement IN ('Espèces','Carte','Virement')),
    CONSTRAINT fk_paiement_facture FOREIGN KEY (id_facture) REFERENCES FACTURE(id_facture)
);

-- Table DOSSIER_MEDICAL (dépend de PATIENT)
CREATE TABLE DOSSIER_MEDICAL (
    id_dossier     NUMBER PRIMARY KEY,
    id_patient     NUMBER NOT NULL,
    diagnostic     CLOB,
    traitement     CLOB,
    date_creation  DATE DEFAULT SYSDATE,
    CONSTRAINT fk_dossier_patient FOREIGN KEY (id_patient) REFERENCES PATIENT(id_patient)
);

-- Table AUDIT_LOG (pour les triggers, pas de dépendances)
CREATE TABLE AUDIT_LOG (
    id_log      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name  VARCHAR2(50),
    action      VARCHAR2(20),
    utilisateur VARCHAR2(100),
    date_action DATE DEFAULT SYSDATE
);

SELECT table_name FROM user_tables ORDER BY table_name;


CREATE SEQUENCE seq_patient     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_service     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_medecin     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_rdv         START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_hosp        START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_facture     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_paiement    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dossier     START WITH 1 INCREMENT BY 1;

-- Index sur RENDEZ_VOUS
CREATE INDEX idx_rdv_patient  ON RENDEZ_VOUS(id_patient);
CREATE INDEX idx_rdv_medecin  ON RENDEZ_VOUS(id_medecin);
CREATE INDEX idx_rdv_date     ON RENDEZ_VOUS(date_rdv);

-- Index sur HOSPITALISATION
CREATE INDEX idx_hosp_patient ON HOSPITALISATION(id_patient);
CREATE INDEX idx_hosp_service ON HOSPITALISATION(id_service);

-- Index sur FACTURE
CREATE INDEX idx_fact_patient ON FACTURE(id_patient);

-- Index sur PAIEMENT
CREATE INDEX idx_paie_facture ON PAIEMENT(id_facture);

-- Vérifier les tables
SELECT table_name FROM user_tables ORDER BY table_name;

-- Vérifier les séquences
SELECT sequence_name FROM user_sequences ORDER BY sequence_name;

-- Vérifier les index
SELECT index_name, table_name FROM user_indexes ORDER BY table_name;






CREATE OR REPLACE FUNCTION fn_total_paiements(p_id_facture NUMBER)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(montant), 0)
    INTO v_total
    FROM PAIEMENT
    WHERE id_facture = p_id_facture;
    
    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/




CREATE OR REPLACE FUNCTION fn_nb_patients_service(p_id_service NUMBER)
RETURN NUMBER
IS
    v_nb NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_nb
    FROM HOSPITALISATION
    WHERE id_service = p_id_service
    AND statut = 'En cours';
    
    RETURN v_nb;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/






CREATE OR REPLACE FUNCTION fn_taux_occupation(p_id_service NUMBER)
RETURN NUMBER
IS
    v_capacite  NUMBER;
    v_occupes   NUMBER;
BEGIN
    SELECT capacite INTO v_capacite
    FROM SERVICE
    WHERE id_service = p_id_service;
    
    v_occupes := fn_nb_patients_service(p_id_service);
    
    RETURN ROUND((v_occupes / v_capacite) * 100, 2);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/







CREATE OR REPLACE PROCEDURE proc_creer_rdv(
    p_patient  NUMBER,
    p_medecin  NUMBER,
    p_date     DATE
)
IS
BEGIN
    INSERT INTO RENDEZ_VOUS VALUES (
        seq_rdv.NEXTVAL,
        p_patient,
        p_medecin,
        p_date,
        'Planifié'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Rendez-vous créé avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/





CREATE OR REPLACE PROCEDURE proc_hospitaliser(
    p_patient  NUMBER,
    p_service  NUMBER,
    p_date     DATE
)
IS
    v_capacite NUMBER;
    v_occupes  NUMBER;
BEGIN
    v_capacite := 0;
    SELECT capacite INTO v_capacite
    FROM SERVICE WHERE id_service = p_service;
    
    v_occupes := fn_nb_patients_service(p_service);
    
    IF v_occupes >= v_capacite THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : Service complet.');
        RETURN;
    END IF;
    
    INSERT INTO HOSPITALISATION VALUES (
        seq_hosp.NEXTVAL,
        p_patient,
        p_service,
        p_date,
        NULL,
        'En cours'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Patient hospitalisé avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/






CREATE OR REPLACE PROCEDURE proc_generer_facture(
    p_patient  NUMBER,
    p_hosp     NUMBER,
    p_montant  NUMBER
)
IS
BEGIN
    INSERT INTO FACTURE VALUES (
        seq_facture.NEXTVAL,
        p_patient,
        p_hosp,
        p_montant,
        SYSDATE
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Facture générée avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/



CREATE OR REPLACE PROCEDURE proc_cloturer_hosp(
    p_id_hosp  NUMBER,
    p_date_sortie DATE
)
IS
BEGIN
    UPDATE HOSPITALISATION
    SET date_sortie = p_date_sortie,
        statut = 'Terminé'
    WHERE id_hosp = p_id_hosp;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Hospitalisation clôturée avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;
/


SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('FUNCTION', 'PROCEDURE')
ORDER BY object_type;



CREATE OR REPLACE TRIGGER trg_audit_patient
AFTER INSERT OR UPDATE OR DELETE ON PATIENT
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDIT_LOG(table_name, action, utilisateur, date_action)
        VALUES('PATIENT', 'INSERT', USER, SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO AUDIT_LOG(table_name, action, utilisateur, date_action)
        VALUES('PATIENT', 'UPDATE', USER, SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO AUDIT_LOG(table_name, action, utilisateur, date_action)
        VALUES('PATIENT', 'DELETE', USER, SYSDATE);
    END IF;
END;
/




CREATE OR REPLACE TRIGGER trg_audit_rdv
AFTER INSERT OR UPDATE OR DELETE ON RENDEZ_VOUS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDIT_LOG(table_name, action, utilisateur, date_action)
        VALUES('RENDEZ_VOUS', 'INSERT', USER, SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO AUDIT_LOG(table_name, action, utilisateur, date_action)
        VALUES('RENDEZ_VOUS', 'UPDATE', USER, SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO AUDIT_LOG(table_name, action, utilisateur, date_action)
        VALUES('RENDEZ_VOUS', 'DELETE', USER, SYSDATE);
    END IF;
END;
/





CREATE OR REPLACE TRIGGER trg_verif_capacite
BEFORE INSERT ON HOSPITALISATION
FOR EACH ROW
DECLARE
    v_capacite NUMBER;
    v_occupes  NUMBER;
BEGIN
    SELECT capacite INTO v_capacite
    FROM SERVICE
    WHERE id_service = :NEW.id_service;
    
    SELECT COUNT(*) INTO v_occupes
    FROM HOSPITALISATION
    WHERE id_service = :NEW.id_service
    AND statut = 'En cours';
    
    IF v_occupes >= v_capacite THEN
        RAISE_APPLICATION_ERROR(-20001, 
        'Service complet. Capacité maximale atteinte.');
    END IF;
END;
/




CREATE OR REPLACE TRIGGER trg_maj_facture
AFTER INSERT ON PAIEMENT
FOR EACH ROW
BEGIN
    UPDATE FACTURE
    SET montant_total = fn_total_paiements(:NEW.id_facture)
    WHERE id_facture = :NEW.id_facture;
END;
/


CREATE OR REPLACE VIEW V_PATIENT_FACTURE AS
SELECT 
    p.id_patient,
    p.nom,
    p.prenom,
    f.id_facture,
    f.montant_total,
    f.date_facture
FROM PATIENT p
JOIN FACTURE f ON p.id_patient = f.id_patient;

CREATE OR REPLACE VIEW V_RDV_JOUR AS
SELECT 
    r.id_rdv,
    p.nom        AS nom_patient,
    p.prenom     AS prenom_patient,
    m.nom        AS nom_medecin,
    m.specialite,
    r.date_rdv,
    r.statut
FROM RENDEZ_VOUS r
JOIN PATIENT p ON r.id_patient = p.id_patient
JOIN MEDECIN m ON r.id_medecin = m.id_medecin
WHERE TRUNC(r.date_rdv) = TRUNC(SYSDATE);

CREATE OR REPLACE VIEW V_OCCUPATION_SERVICE AS
SELECT 
    s.id_service,
    s.nom_service,
    s.capacite,
    COUNT(h.id_hosp)                  AS nb_occupes,
    fn_taux_occupation(s.id_service)  AS taux_occupation
FROM SERVICE s
LEFT JOIN HOSPITALISATION h 
    ON s.id_service = h.id_service 
    AND h.statut = 'En cours'
GROUP BY s.id_service, s.nom_service, s.capacite;




-- Services
INSERT INTO SERVICE VALUES (seq_service.NEXTVAL, 'Cardiologie', 20);
INSERT INTO SERVICE VALUES (seq_service.NEXTVAL, 'Pédiatrie', 15);
INSERT INTO SERVICE VALUES (seq_service.NEXTVAL, 'Urgences', 30);

-- Patients
INSERT INTO PATIENT VALUES (seq_patient.NEXTVAL, 'Benali', 'Ahmed', DATE '1990-05-12', '0612345678', SYSDATE);
INSERT INTO PATIENT VALUES (seq_patient.NEXTVAL, 'Idrissi', 'Fatima', DATE '1985-03-20', '0698765432', SYSDATE);
INSERT INTO PATIENT VALUES (seq_patient.NEXTVAL, 'Alami', 'Youssef', DATE '2000-11-08', '0611223344', SYSDATE);

-- Médecins
INSERT INTO MEDECIN VALUES (seq_medecin.NEXTVAL, 'Dr. Karimi', 'Cardiologie', 1);
INSERT INTO MEDECIN VALUES (seq_medecin.NEXTVAL, 'Dr. Mansouri', 'Pédiatrie', 2);

-- Rendez-vous
INSERT INTO RENDEZ_VOUS VALUES (seq_rdv.NEXTVAL, 1, 1, SYSDATE, 'Planifié');
INSERT INTO RENDEZ_VOUS VALUES (seq_rdv.NEXTVAL, 2, 2, SYSDATE+1, 'Planifié');

-- Hospitalisations
INSERT INTO HOSPITALISATION VALUES (seq_hosp.NEXTVAL, 1, 1, SYSDATE-3, NULL, 'En cours');
INSERT INTO HOSPITALISATION VALUES (seq_hosp.NEXTVAL, 2, 2, SYSDATE-1, NULL, 'En cours');

-- Factures
INSERT INTO FACTURE VALUES (seq_facture.NEXTVAL, 1, 1, 1500, SYSDATE);
INSERT INTO FACTURE VALUES (seq_facture.NEXTVAL, 2, 2, 800, SYSDATE);

-- Paiements
INSERT INTO PAIEMENT VALUES (seq_paiement.NEXTVAL, 1, 1000, SYSDATE, 'Carte');
INSERT INTO PAIEMENT VALUES (seq_paiement.NEXTVAL, 2, 800, SYSDATE, 'Espèces');

COMMIT;



-- Tester les vues
SELECT * FROM V_PATIENT_FACTURE;
SELECT * FROM V_OCCUPATION_SERVICE;

-- Tester les fonctions
SELECT fn_total_paiements(1) FROM DUAL;
SELECT fn_taux_occupation(1) FROM DUAL;

-- Tester les procédures
EXEC proc_creer_rdv(3, 1, SYSDATE+2);
EXEC proc_hospitaliser(3, 3, SYSDATE);