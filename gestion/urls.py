from django.urls import path
from . import views

urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('patients/', views.liste_patients, name='liste_patients'),
    path('patients/ajouter/', views.ajouter_patient, name='ajouter_patient'),
    path('rdv/', views.liste_rdv, name='liste_rdv'),
    path('rdv/ajouter/', views.ajouter_rdv, name='ajouter_rdv'),
    path('factures/', views.liste_factures, name='liste_factures'),
]