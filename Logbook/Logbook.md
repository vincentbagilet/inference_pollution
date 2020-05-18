# Vincent's logbook - Lockdown air pollution 

I usually try to write a logbook to keep track of my work. It often ends up being a huge mess.

## Project description in Notion

### Goals

- essayer d'estimer l'effet causal du confinement sur les concentrations de polluants dans certaines villes françaises.
- le but est de créer le contrefactuel pour les concentrations des polluants sans le confinement. Le problème est qu'il faut absolument bien contrôler pour les facteurs liés au calendrier et à la météo.
- C'est un sujet hyper important car les gens disaient avant que si on baissait le trafic routier, les PM10 et PM2.5 allaient baisser alors qu'il semblerait que ce sont seulement les NOx, NO2 qui ont véritablement chuté.

### Methods

- L'algorithme de matching créé par Marie-Abèle Bind et son équipe à Harvard.
- C'est un algorithme qui permet d'apparier les unités traitées à des unités de contrôle en spécifiant précisément la distance tolérée pour chaque covariate.
- C'est un algorithme assez stricte donc généralement il y a assez peu d'unités traitées qui sont appariées.
- Une fois que les unités ont été appariées, on peut faire
    1. de la *randomization inference* (le bouquin à lire est **Imbens et Rubin (2015)**, chapitre 5)
    2. on verra mais on peut ensuite analyser les données en mode fréquentiste ou bayésien

### Data

- Link for air pollution data: [https://discomap.eea.europa.eu/map/fme/AirQualityExport.htm](https://discomap.eea.europa.eu/map/fme/AirQualityExport.htm)
- Link for Météo-France data: [https://donneespubliques.meteofrance.fr/](https://donneespubliques.meteofrance.fr/)
- Link for bank and holidays data: [https://www.data.gouv.fr/fr/datasets/vacances-scolaires-par-zones/](https://www.data.gouv.fr/fr/datasets/vacances-scolaires-par-zones/) et [https://www.data.gouv.fr/fr/datasets/jours-feries-en-france/](https://www.data.gouv.fr/fr/datasets/jours-feries-en-france/)

## Logbook entries

- Projet suggested by Léo
- Project initially described in the Notion as coppy/pasted above 
- Léo is in charge of downloading the weather data, I am in charge of downloading the pollution data
- Ultimately, would be great if we could build a shiny app to facilitate the whole process to run th algorithm





