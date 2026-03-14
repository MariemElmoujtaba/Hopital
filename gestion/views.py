from django.shortcuts import render, redirect
from django.db import connection
from .models import Patient, Medecin, Service, RendezVous, Facture


def dashboard(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM MV_REVENUS_MENSUELS")
            revenus = cursor.fetchall()
    except Exception:
        revenus = []
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM V_OCCUPATION_SERVICE")
            occupation = cursor.fetchall()
    except Exception:
        occupation = []
    return render(request, 'dashboard.html', {
        'revenus': revenus,
        'occupation': occupation
    })


def liste_patients(request):
    patients = Patient.objects.all()
    return render(request, 'patients/liste.html', {'patients': patients})


def ajouter_patient(request):
    if request.method == 'POST':
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO PATIENT (id_patient, nom, prenom, date_naissance, telephone, date_creation)
                VALUES (seq_patient.NEXTVAL, :nom, :prenom, TO_DATE(:dn, 'YYYY-MM-DD'), :tel, SYSDATE)
            """, {
                'nom': request.POST['nom'],
                'prenom': request.POST['prenom'],
                'dn': request.POST['date_naissance'],
                'tel': request.POST['telephone']
            })
        return redirect('liste_patients')
    return render(request, 'patients/ajouter.html')


def liste_rdv(request):
    rdvs = RendezVous.objects.select_related('patient', 'medecin').all()
    return render(request, 'rdv/liste.html', {'rdvs': rdvs})


def ajouter_rdv(request):
    if request.method == 'POST':
        try:
            with connection.cursor() as cursor:
                cursor.callproc('PROC_CREER_RDV', [
                    request.POST['patient'],
                    request.POST['medecin'],
                    request.POST['date_rdv']
                ])
        except Exception as e:
            print("Erreur Oracle:", e)
        return redirect('liste_rdv')
    patients = Patient.objects.all()
    medecins = Medecin.objects.all()
    return render(request, 'rdv/ajouter.html', {
        'patients': patients,
        'medecins': medecins
    })


def liste_factures(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM V_PATIENT_FACTURE")
            factures = cursor.fetchall()
    except Exception:
        factures = []
    return render(request, 'factures/liste.html', {'factures': factures})
