# Imagini vehicule — rpg-garages

Pune aici imaginea fiecarui vehicul, denumita **exact** dupa `personal_vehicle.model_name`:

```
html/images/vehicles/
├── sultan.png
├── adder.png
├── elegy2.png
├── buzzard2.png
├── dinghy.png
└── ...
```

## Reguli

- Numele fisierului = `<model_name>.png` (lowercase, exact codul de spawn).
- Format: `.png` (recomandat), `.jpg` sau `.webp` sunt de asemenea servite.
- Aspect ratio ideal: **16:9** (ex. 640x360 sau 480x270). NUI-ul face `object-fit: cover`.
- **Nu** trebuie sa existe imagine pentru toate modelele. Daca lipseste, NUI-ul
  afiseaza automat un placeholder elegant „NO IMAGE" (fara imagine broken).

## Cum se genereaza path-ul

Serverul trimite catre NUI campul `image = "<model_name>.png"` (derivat din
`model_name`, **nu** stocat in DB). NUI-ul il prefixeaza cu `images/vehicles/`.
Deci pentru a adauga un vehicul nou nu trebuie modificat niciun cod — doar
adaugi fisierul `html/images/vehicles/<model_name>.png` si dai restart resursei
(sau `refresh`).

Fisierele sunt declarate in `fxmanifest.lua` prin glob:
`html/images/vehicles/*.png` (+ `.jpg`, `.webp`).
