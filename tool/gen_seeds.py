"""Génère assets/seed_*.json. Les horaires sont en minutes relatives à
l'heure de chargement (startOffsetMin: -120 = il y a 2 h).
Usage : python3 tool/gen_seeds.py"""
import json

agents = [
    {"id": "a1", "firstName": "Karim", "lastInitial": "B", "phone": "06 12 48 73 20"},
    {"id": "a2", "firstName": "Sofia", "lastInitial": "M", "phone": "06 27 91 35 64"},
    {"id": "a3", "firstName": "Julien", "lastInitial": "D", "phone": "07 81 22 49 17"},
    {"id": "a4", "firstName": "Aminata", "lastInitial": "K", "phone": "06 45 73 18 92"},
    {"id": "a5", "firstName": "Thomas", "lastInitial": "L", "phone": "06 58 30 66 41"},
    {"id": "a6", "firstName": "Nadia", "lastInitial": "R", "phone": "07 63 14 85 29"},
]

def interventions(comment):
    # 12 interventions. Karim (a1) : 1 terminée, 1 dans 30 min, 1 cet après-midi.
    # Exactement une en retard : i7 (Julien, prévue il y a 40 min, non démarrée).
    # Thomas (a5) absent : sa tournée est reprise par Nadia (a6).
    return [
        {"id": "i1", "agentId": "a1", "siteId": "s1", "startOffsetMin": -180, "durationMin": 90,
         "status": "done", "arrivedOffsetMin": -183, "leftOffsetMin": -98, "allTasksDone": True,
         "photosBefore": "PAIR0_BEFORE", "photosAfter": "PAIR0_AFTER", "comment": comment},
        {"id": "i2", "agentId": "a1", "siteId": "s2", "startOffsetMin": 30, "durationMin": 75, "status": "planned"},
        {"id": "i3", "agentId": "a1", "siteId": "s3", "startOffsetMin": 240, "durationMin": 120, "status": "planned"},
        {"id": "i4", "agentId": "a2", "siteId": "s4", "startOffsetMin": -240, "durationMin": 120,
         "status": "done", "arrivedOffsetMin": -236, "leftOffsetMin": -118, "allTasksDone": True,
         "photosBefore": "PAIR1_BEFORE", "photosAfter": "PAIR1_AFTER"},
        {"id": "i5", "agentId": "a2", "siteId": "s5", "startOffsetMin": -30, "durationMin": 120,
         "status": "onSite", "arrivedOffsetMin": -27, "tasksDone": 2},
        {"id": "i6", "agentId": "a2", "siteId": "s10", "startOffsetMin": 150, "durationMin": 90, "status": "planned"},
        {"id": "i7", "agentId": "a3", "siteId": "s7", "startOffsetMin": -40, "durationMin": 90, "status": "planned"},
        {"id": "i8", "agentId": "a3", "siteId": "s8", "startOffsetMin": 120, "durationMin": 90, "status": "planned"},
        {"id": "i9", "agentId": "a4", "siteId": "s9", "startOffsetMin": 10, "durationMin": 60, "status": "enRoute"},
        {"id": "i10", "agentId": "a4", "siteId": "s10", "startOffsetMin": -200, "durationMin": 90,
         "status": "done", "arrivedOffsetMin": -198, "leftOffsetMin": -105, "allTasksDone": True},
        {"id": "i11", "agentId": "a6", "siteId": "s6", "startOffsetMin": -60, "durationMin": 150,
         "status": "onSite", "arrivedOffsetMin": -57, "tasksDone": 3},
        {"id": "i12", "agentId": "a6", "siteId": "s4", "startOffsetMin": 180, "durationMin": 90, "status": "planned"},
    ]

absences = [{"agentId": "a5", "dayOffset": 0, "reason": "Maladie", "replacementAgentId": "a6"}]

def build(company, tasks, sites, comment, pairs):
    items = interventions(comment)
    for it in items:
        for key in ("photosBefore", "photosAfter"):
            v = it.get(key)
            if isinstance(v, str):
                n = int(v[4]); side = 0 if v.endswith("BEFORE") else 1
                it[key] = [pairs[n][side]]
    return {
        "companyName": company,
        "demoAgentId": "a1",
        "tasks": tasks,
        "examplePhotos": {"before": [p[0] for p in pairs], "after": [p[1] for p in pairs]},
        "agents": agents,
        "sites": sites,
        "interventions": items,
        "absences": absences,
    }

def site(i, name, addr, city, instr):
    return {"id": f"s{i}", "clientName": name, "address": addr, "city": city, "instructions": instr}

P = "assets/photos/"
nettoyage = build(
    "Oise Propreté",
    ["Sols aspirés et lavés", "Sanitaires désinfectés", "Poubelles vidées",
     "Vitres des parties communes", "Ascenseur nettoyé"],
    [
        site(1, "Résidence Les Tilleuls", "12 avenue du Maréchal Joffre", "Chantilly",
             "Code portail 4512B. Local ménage au sous-sol, clé dans la boîte à code (1984)."),
        site(2, "Cabinet médical du Lys", "3 rue du Connétable", "Chantilly",
             "Passer après 12 h 30. Salle d'attente en priorité. Produit virucide uniquement (armoire bleue)."),
        site(3, "Bureaux Verdier Conseil", "25 rue de la République", "Senlis",
             "Badge à récupérer à l'accueil. Ne pas déplacer les dossiers sur les bureaux."),
        site(4, "École maternelle Les Coquelicots", "8 rue Saint-Pierre", "Senlis",
             "Après le départ des enfants. Clés chez la gardienne, Mme Lopez (loge à droite)."),
        site(5, "Salle de sport FitOise", "40 boulevard Biondi", "Creil",
             "Vestiaires en premier. Code alarme 2207, à désactiver en entrant."),
        site(6, "Résidence Le Clos des Aigles", "5 allée des Pins", "Gouvieux",
             "Code bâtiment A : 1290. Local poubelles derrière le bâtiment B."),
        site(7, "Centre dentaire Sainte-Anne", "17 rue Henri Barbusse", "Creil",
             "Entrée par la porte de service. Ne pas toucher au matériel des cabinets."),
        site(8, "Résidence du Golf", "2 route de Chantilly", "Lamorlaye",
             "Interphone « Gardien ». Aspirateur dans le placard du hall."),
        site(9, "Agence Oise Habitat", "9 place de la Halle", "Senlis",
             "Avant l'ouverture (9 h). Vitrine côté rue à faire chaque passage."),
        site(10, "Cabinet de kinésithérapie Lamorlaye", "14 rue du Général Leclerc", "Lamorlaye",
             "Tables de soin : lingettes désinfectantes. Clé sous la responsabilité du cabinet."),
    ],
    "RAS. Tache tenace sur la moquette de l'entrée, signalée au gardien.",
    [(P + "carrelage_avant.jpg", P + "carrelage_apres.jpg"), (P + "vitres_avant.jpg", P + "vitres_apres.jpg")],
)

espaces_verts = build(
    "Oise Jardins Services",
    ["Tonte", "Taille des haies", "Désherbage des allées", "Ramassage des feuilles",
     "Évacuation des déchets verts"],
    [
        site(1, "Copropriété Le Parc Condé", "18 avenue de Condé", "Chantilly",
             "Portail code 7731. Benne à déchets verts derrière le bâtiment C."),
        site(2, "M. et Mme Lefèvre", "6 chemin des Bruyères", "Lamorlaye",
             "Chien dans le jardin : sonner avant d'entrer. Robinet extérieur à gauche du garage."),
        site(3, "Zone d'activité du Chemin Vert", "Rue des Artisans", "Creil",
             "Accès poids lourds côté nord. Ne pas tondre pendant les livraisons (10 h - 11 h)."),
        site(4, "Mairie annexe de Gouvieux", "2 place de l'Église", "Gouvieux",
             "Se présenter à l'accueil. Massifs fleuris : désherbage manuel uniquement."),
        site(5, "Copropriété Les Jardins de Senlis", "31 rue de Meaux", "Senlis",
             "Code portillon 2468. Arrosage automatique coupé le matin."),
        site(6, "Mme Garnier", "11 rue du Moulin", "Gouvieux",
             "Grand terrain (4 000 m²). Clé du cabanon dans la boîte aux lettres."),
        site(7, "Entrepôt Logistique Nord", "ZA des Marches, allée 4", "Creil",
             "Gilet obligatoire sur le site. Badge à l'accueil sécurité."),
        site(8, "Copropriété Résidence du Lys", "4 avenue du Bouteiller", "Chantilly",
             "Haies côté rue à 1,80 m maximum. Déchets verts à évacuer le jour même."),
        site(9, "M. Dubreuil", "27 route de Crépy", "Senlis",
             "Verger : ne pas tondre sous les pommiers. Portail toujours refermé (chevaux)."),
        site(10, "Copropriété Les Hauts de Lamorlaye", "9 allée des Chênes", "Lamorlaye",
             "Prévenir le gardien (06 70 11 22 33) en arrivant. Souffleur après 9 h seulement."),
    ],
    "Haie côté rue taillée à 1,80 m. Prévoir un désherbage du parking la semaine prochaine.",
    [(P + "pelouse_avant.jpg", P + "pelouse_apres.jpg"), (P + "haie_avant.jpg", P + "haie_apres.jpg")],
)

for name, data in [("nettoyage", nettoyage), ("espaces_verts", espaces_verts)]:
    with open(f"assets/seed_{name}.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
