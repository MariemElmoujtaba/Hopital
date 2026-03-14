from django.db import models

class Service(models.Model):
    id_service  = models.AutoField(primary_key=True)
    nom_service = models.CharField(max_length=100)
    capacite    = models.IntegerField()

    class Meta:
        db_table = 'SERVICE'

class Patient(models.Model):
    id_patient     = models.AutoField(primary_key=True)
    nom            = models.CharField(max_length=100)
    prenom         = models.CharField(max_length=100)
    date_naissance = models.DateField()
    telephone      = models.CharField(max_length=20, unique=True)
    date_creation  = models.DateField(auto_now_add=True)

    class Meta:
        db_table = 'PATIENT'

class Medecin(models.Model):
    id_medecin = models.AutoField(primary_key=True)
    nom        = models.CharField(max_length=100)
    specialite = models.CharField(max_length=100)
    service    = models.ForeignKey(Service, on_delete=models.SET_NULL, null=True, db_column='ID_SERVICE')

    class Meta:
        db_table = 'MEDECIN'

class RendezVous(models.Model):
    id_rdv    = models.AutoField(primary_key=True)
    patient   = models.ForeignKey(Patient, on_delete=models.CASCADE, db_column='ID_PATIENT')
    medecin   = models.ForeignKey(Medecin, on_delete=models.CASCADE, db_column='ID_MEDECIN')
    date_rdv  = models.DateField()
    statut    = models.CharField(max_length=20, default='Planifié')

    class Meta:
        db_table = 'RENDEZ_VOUS'

class Hospitalisation(models.Model):
    id_hosp     = models.AutoField(primary_key=True)
    patient     = models.ForeignKey(Patient, on_delete=models.CASCADE, db_column='ID_PATIENT')
    service     = models.ForeignKey(Service, on_delete=models.CASCADE, db_column='ID_SERVICE')
    date_entree = models.DateField()
    date_sortie = models.DateField(null=True, blank=True)
    statut      = models.CharField(max_length=20, default='En cours')

    class Meta:
        db_table = 'HOSPITALISATION'

class Facture(models.Model):
    id_facture    = models.AutoField(primary_key=True)
    patient       = models.ForeignKey(Patient, on_delete=models.CASCADE, db_column='ID_PATIENT')
    hospitalisation = models.ForeignKey(Hospitalisation, on_delete=models.SET_NULL, null=True, db_column='ID_HOSP')
    montant_total = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    date_facture  = models.DateField(auto_now_add=True)

    class Meta:
        db_table = 'FACTURE'

class Paiement(models.Model):
    id_paiement   = models.AutoField(primary_key=True)
    facture       = models.ForeignKey(Facture, on_delete=models.CASCADE, db_column='ID_FACTURE')
    montant       = models.DecimalField(max_digits=10, decimal_places=2)
    date_paiement = models.DateField(auto_now_add=True)
    mode_paiement = models.CharField(max_length=50)

    class Meta:
        db_table = 'PAIEMENT'