"""Fiches des combattants de la vague 3 : un module par fiche.

Chaque module définit FICHE = {"id", "relations", "questions"} (une source https par paire et par
question) et SOURCES_GENERALES = [(titre, url), …]. fiches.py et sources.py les chargent tous.
"""
import importlib
import os


def modules():
    ici = os.path.dirname(__file__)
    for nom in sorted(os.listdir(ici)):
        if nom.endswith(".py") and not nom.startswith("_"):
            yield importlib.import_module(f"vague3.{nom[:-3]}")
