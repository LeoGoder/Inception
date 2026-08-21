function changerCouleurFond() {
    const teinte = Math.floor(Math.random() * 360);
    const nouvelleCouleur = `hsl(${teinte}, 100%, 20%)`;

    document.body.style.backgroundColor = nouvelleCouleur;
}
changerCouleurFond();
setInterval(changerCouleurFond, 2000);

