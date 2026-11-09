# Plateforme SaaS de traçabilité agricole — MVP v1

Ce MVP couvre le cahier des charges : registre des participants et rôles, création de lots, opérations chronologiques, transfert de responsabilité, preuves hashées, consultation publique et QR.

## Déploiement

1. Déployer `contracts/TraceabilityAgriRegistry.sol` dans Remix sur Sepolia.
2. Copier l’adresse dans `config.js` à la place de `0x0000000000000000000000000000000000000000`.
3. Publier le dossier comme site statique HTTPS (GitHub Pages convient pour la démonstration).
4. Le compte du déployeur devient administrateur et peut enregistrer les participants.

## Rôles numériques

`1 PRODUCER`, `2 PACKER`, `3 CARRIER`, `4 DISTRIBUTOR`, `5 AUDITOR`, `6 ADMIN`.

Les données sensibles ne doivent pas être écrites directement sur la blockchain. Conserver les documents dans un stockage contrôlé, puis inscrire seulement une URI et une empreinte `bytes32`.

## Limites avant production

- Sepolia est un réseau de test.
- Faire auditer le contrat et ajouter une gouvernance multi-signature pour l’administrateur.
- Remplacer l’identité MetaMask des opérateurs par un backend avec authentification et relayer sécurisé ; ne jamais stocker de clé privée dans le navigateur.
- Ajouter API, base de données/indexeur, journaux, sauvegardes, RGPD et gestion d’abonnements.
- Prévoir une procédure de révocation et de correction hors chaîne sans effacer les preuves historiques.
