# Synapse
A logic gate connection game

# Features
PJ
-	Collisions (ne peut pas occuper le même espace) avec :
    o	Le hub
    o	Les gisements
    o	Les robots
    o	Les obstacles environnementaux (arbres, rivières, etc) 
-	Mouvements sur deux axes (libres ou avec direction fixe, à définir ensemble) :
    o	En pressant les touches fléchées ou les touches WASD :
        	Le personnage se tourne dans la direction de la dernière touche pressé non relâchée.
        	La vitesse du personnage est changée pour produire un déplacement dans la direction appropriée.
    o	En relâchant une touche fléchée ou une touche WASD pressée :
        	Le personnage se tourne dans la direction de la dernière touche pressé non relâchée.
        	La vitesse du personnage est changée pour produire un déplacement dans la direction appropriée, ou arrêter le déplacement.
-	Ouverture du menu d’upgrade :
    o	Quand à proximité d’un robot, en pressant la touche E ou la touche enter :
        	Le menu d’upgrade du robot en question est ouvert.
-	Ramassage des robots :
    o	Quand à proximité d’un robot, si le PJ ne transporte pas déjà de robot, le robot le plus proche est highlighté.
    o	Si un robot est highlighté, en pressant la barre espace :
        	L’instance du robot est désactivée. 
        	Le sprite du haut du corps du PJ est remplacé par la version « robot transporté ». 
        	Un sprite de robot est ajouté au PJ, au-dessus de la tête.
        	Les ressources accumulées par le robot sont ajoutées au compteur de ressources du PJ. 
-	Dépôt des robots
    o	Si le PJ transporte un robot, en pressant la barre espace :
        	Le sprite de robot est retiré du PJ.
        	Le haut du corps passe en version « Iddle », « Mouvement gauche/droite » ou « Mouvement haut/bas » selon l’état actuel du PJ.
        	L’instance du robot est réactivée et transporté à l’avant du PJ (donc à côté du PJ, dans la direction à laquelle le PJ fait face). 
        	Si l’espace est occupé par un gisement, le robot est déposé sur le gisement. 
        	Si l’espace est occupé par un autre élément, le robot est déposé à côté de l’élément, sur un espace disponible (sans collision) aussi proche du PJ que possible.
-	Récupération des ressources stockées par les robots
    o	Pour l’instant, il faut ramasser un robot et l’amener au hub pour récupérer ses ressources. (Voir ensembles si cela est un problème)
-	Sprites :
    o	Bas du corps - Iddle
    o	Bas du corps - Mouvements gauche/droite
    o	Bas du corps - Mouvements haut/bas
    o	Haut du corps – Iddle
    o	Haut du corps - Mouvements gauche/droite
    o	Haut du corps - Mouvements haut/bas
    o	Haut du corps – Interactions
    o	Haut du corps – Robot transporté
-	Animations :
    o	Bas du corps - Iddle
    o	Bas du corps - Mouvements gauche/droite
    o	Bas du corps - Mouvements haut/bas
    o	Haut du corps – Iddle
    o	Haut du corps - Mouvements gauche/droite
    o	Haut du corps - Mouvements haut/bas
    o	Haut du corps – Interactions
    o	Haut du corps – Robot transporté
-	Sons :
    o	Mouvements
    o	Interactions (ouverture de menu – hub, puzzle)
    o	Récupération des ressources / Ramassage de robot
PUZZLES
-	Diviser l’écran en deux (gauche/droite) ; une partie puzzle et une partie composante
-	UI :
    o	Pour chaque porte (NOT, AND, OR, XOR, NAND, NOR, XNOR) :
        	Icône
        	Prix
        	Grisé si trop cher
        	Noir OU silhouette (à définir ensemble) si non-disponible
        	Si cliqué ET disponible : devient l’élément sélectionné
    o	Possibilité de scroll OU grille permettant d’afficher d’un coup toutes les composantes déblocables (à définir ensemble)
    o	Coûts :
        	Compteur montrant les ressources actuelles
        	Compteur montrant le coût des composantes ajoutées au puzzle
        	Compteur montrant les ressources restantes après validation du puzzle
    o	Boutons :
        	« Valider » : Tente de valider le puzzle. Si la solution est valide, l’argent est dépensé (Le compteur de ressources du PJ prend la valeur du compteur montrant les ressources restantes après validation), et le puzzle est résolu.
            •	Presser la touche enter devrait avoir le même effet
        	« Quitter » : Quitte le puzzle et le réinitialise.
            •	Presser la touche escape devrait avoir le même effet
-	Curseur :
    o	Cliquer sur un élément disponible dans la liste le sélectionne (même si trop cher).
    o	Cliquer sur un élément indisponible dans la liste joue le son approprié.
    o	L’élément actuellement sélectionné apparaît au bout du curseur comme « blueprint » (c’est-à-dire une représentation transparente de l’élément indiquant où il serait placé en cas de clique)
        	En vert si aucun élément n’est en collision avec le blueprint
        	En rouge si un élément est en collision avec le blueprint
        	En gris si les ressources du PJ sont inférieures au coût de l’élément  
-	Placement d’éléments sur le puzzle :
    o	Pour les portes :
        	En cas de clique (bouton gauche de la souris pressé), si le blueprint est vert, le cout de l’élément est ajouté au coût du puzzle et soustrait aux ressources restantes à la fin du puzzle, et une instance de l’élément est créé aux coordonnées du blueprint.
        	En cas de clique (bouton gauche de la souris pressé), si le blueprint est rouge ou gris, un son indiquant l’impossibilité du placement est joué.
    o	Pour les câbles :
        	Dépend de si l’on veut une structure libre ou en grille (à définir ensemble)
-	Graphismes :
    o	Portes
        	NOT
        	AND
        	OR
        	XOR
        	NAND
        	NOR
        	XNOR
    o	Curseur
    o	Câbles
    o	Background
    o	Boutons
-	Sons :
    o	Dépôt d’élément
    o	Impossibilité de sélectionner un élément non-disponible dans la liste
    o	Impossibilité de déposer un élément (manque de place ou de ressources)
    o	Clique de bouton
    o	Puzzle résolu
    o	Tentative de résolution du puzzle invalide
ROBOTS
-	Collisions (ne peut pas occuper le même espace) avec :
    o	Le PJ
    o	Le hub
    o	Les gisements
    o	Les robots
    o	Les obstacles environnementaux (arbres, rivières, etc) 
-	Collecte :
    o	Quand posé sur un gisement, récolte les ressources selon sa vitesse de récolte.
    o	La collecte remplit un compteur de ressources du robot, qui a une valeur maximale. Quand la valeur maximale est atteinte, la collecte s’arrête.
-	Menu d’upgrades :
    o	UI :
        	Arbre d’upgrade :
            •	Chaque upgrade du jeu est représentée dans un arbre.
            •	Le premier étage de l’arbre (tout en haut ou tout en bas de l’arbre, selon dev) contient :
                o	Navigation 1, qui a deux options : gauche/droite ou haut/bas. Les deux icônes sont mises côte à côte et en sélectionner une grise l’autre.
                o	Capacité 1
                o	Collecte 1
            •	Le deuxième étage de l’arbre (au-dessus ou au-dessous du premier étage, selon que le premier étage soit en bas ou en haut) contient :
                o	Navigation 2, atteignable à partir de Navigation 1, peu-importe l’option choisie.
                o	Vitesse 1, atteignable à partir de Navigation 1, peu-importe l’option choisie.
                o	Capacité 2, atteignable à partir de Capacité 1.
                o	Collecte 2, atteignable à partir de Collecte 1.
            •	Etc pour les étages 3, 4, …
            •	Chaque upgrade à un coût de base, affiché sous l’icône.
            •	Chaque icône est grisée si le coût est trop élevé. (cf UI Puzzle)
            •	Chaque icône est une silhouette noire si les upgrades précédentes n’ont pas été achetées et leur puzzle validés. (cf UI Puzzle)
            •	Acheter une upgrade donne accès à son puzzle, et remplace l’affichage du prix par le texte « Achetée ».
            •	Cliquer sur une icône d’upgrade déjà achetée ouvre le puzzle correspondant.
            •	L’icône d’une upgrade dont le puzzle est rempli est verte.
        	Boutons :
            •	« Retour » : Quitte le menu.
                o	Presser la touche escape devrait avoir le même effet
                o	Curseur
        	Survoler une icône affiche une boîte de texte indiquant :
            •	Le nom de l’upgrade
            •	Le coût de l’upgrade
            •	L’effet de l’upgrade
            •	Le statut de l’update (indisponible – disponible – achetée – complétée)
    o	Graphismes :
        	Icône pour chaque upgrade
        	Liens entre les icônes selon accès dans l’arbre
        	Bouton « Retour »
    o	Sons
    o	Clique de bouton
    o	Achat
    o	Impossibilité d’acheter une upgrade
-	Upgrades (à revoir ensemble)
    o	Déplacements :
        	Navigation 1( gauche/droite): 
            •	Le robot se déplace en ligne droite (gauche/droite). 
            •	Si le robot rencontre un gisement qui n’est pas actuellement en train d’être collecté, il collecte jusqu’à atteindre sa limite de ressources, puis repart dans l’autre sens. 
            •	Si le robot rencontre le hub, les ressources qu’il porte sont ajoutées au total de ressources du PJ, puis son compteur est réinitialisé. Il repart ensuite dans l’autre sens.
        	Navigation 1 (haut/bas) :
            •	Équivalent à « Navigation 1 (gauche/droite) », à la différence que le robot se déplace en ligne droite (bas/haut).
        	Navigation 2 :
            •	Le robot se voit attribuer un gisement parmi les gisement disponible. Un gisement est disponible si 1) il n’est pas attribué à un autre robot et 2) il n’est pas actuellement en train d’être collecté. 
            •	Le robot détermine le chemin le plus court pour atteindre le gisement, et s’y rend.
            •	Quand le robot atteint le gisement, il collecte jusqu’à atteindre sa limite de ressources, puis détermine le chemin le plus court vers le hub et s’y rend.
            •	Quand le robot atteint le hub, les ressources qu’il porte sont ajoutées au total de ressources du PJ, puis son compteur est réinitialisé. Il détermine ensuite le chemin le plus court vers le gisement qui lui est attribué et s’y rend.
            •	Le robot n’évite pas les obstacles. 
        	Navigation 3 :
            •	Le robot prend en compte les obstacles dans son pathfinding. Il évite donc les obstacles pour se rendre au gisement qui lui est attribué ou au hub.
        	Vitesse 1, 2, 3, … :
            •	Augmente la vitesse de déplacement du robot
    o	Collecte :
        	Capacité 1, 2, 3, … :
            •	Augmente la limite de ressources pouvant être stockée par le robot.
        	Collecte 1, 2, 3, … :
            •	Augmente la vitesse de collecte du robot.
-	Sprites :
    o	Base
    o	Roues
    o	Plein de ressources
-	Animations :
    o	Mouvements gauche/droite
    o	Mouvements haut/bas
    o	Collecte
    o	Plein de ressources
-	Sons :
    o	Mouvements
    o	Collecte de ressource 
    o	Pleins de ressources
HUB
-	Dépôt de ressources : 
    o	Tout robot se trouvant dans une zone autour du hub voit ses ressources ajoutées au total de ressources du PJ, et son compteur de ressource réinitialisé. (Cela s’applique au robot « en jeu », pas aux robots portés par le PJ).
    o	Cela produit le son approprié.
-	Achat de robots :
    o	Le hub affiche le prix actuel d’un robot (augment à chaque achat).
    o	Quand le PJ interagit avec le hub en pressant la touche espace, la touche E, ou la touche enter, si le PJ ne porte pas déjà un robot, et si le compteur de ressources du PJ est supérieur au prix d’un robot, alors le PJ obtient un robot (directement porté par le PJ).
-	Sprites :
    o	Hub
    o	Prix
    o	Zone d’influence (zone permettant la collecte)
-	Sons :
    o	Achat de robot
    o	Pas assez de ressources pour acheter un robot
ENVIRONNEMENT
-	Génération de l’environnement
    o	Avoir une carte définie à la main contenant les divers éléments de jeu.
    o	Définir des limites à l’espace de jeu au-delà desquelles les divers éléments de jeu ne peuvent se rendre.
-	Pour chaque élément ajouté (arbres, pierres, rivières, etc)
    o	Collisions (ne peut pas occuper le même espace) avec :
        	Le PJ
        	Le hub
        	Les gisements
        	Les robots
        	Les obstacles environnementaux (arbres, rivières, etc) 
    o	Sprites appropriés
    o	Animations appropriées
    o	Sons appropriés
MENUS
-	Main Menu
    o	Bouton « Jouer »
        	Lance le jeu quand cliqué
    o	Bouton « Quitter »
        	Ferme le jeu quand cliqué
    o	Bouton « Options »
        	Ouvre le menu d’option quand cliqué
    o	Bouton « Crédits »
        	Ouvre l’écran de crédits quand cliqué
    o	Graphismes
        	Background
        	Boutons
        	Titre
    o	Sons :
        	Musique
        	Bouton cliqué
-	Menu « Option »
    o	Mode daltonien (pas implémenté dans les features à ce stade)
    o	Mode dylsexique (pas implémenté dans les features à ce stade)
-	Menu « Crédit »
    o	Liste des rôles et noms
    o	Bouton « Retour » qui ramène au Main Menu quand 
