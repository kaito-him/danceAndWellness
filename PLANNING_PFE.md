# Planning de Réalisation du Projet PFE : Dance & Wellness

Ce planning détaille les étapes de réalisation du projet "Dance & Wellness", une plateforme LMS centralisant la gestion des cours, le suivi des utilisateurs, et l'intégration d'un système de recommandation intelligent.

| Semaine | Description |
| :--- | :--- |
| **Semaine 1** | Prise de connaissance de l'organisme, analyse du système existant, identification des acteurs (Étudiant, Instructeur, Administrateur) et processus métier liés au LMS et au bien-être. Début de la rédaction du chapitre 1. |
| **Semaine 2** | Modélisation du métier : diagrammes d'activité (inscription, publication de cours, suivi de progression), diagramme de contexte métier, diagramme de cas d'utilisation métier. Rédaction et mise à jour du chapitre 1. |
| **Semaine 3** | Capture des besoins : cas d'utilisation du futur système (LMS, recommandations IA, paiements Stripe), descriptions textuelles, exigences fonctionnelles et non fonctionnelles. Rédaction du chapitre 2. |
| **Semaine 4** | Mise en place de l'environnement technique : Spring Boot, MongoDB. Développement des entités de base (User, Course, Lesson, Enrollment) et des repositories. Diagrammes de séquence pour l'authentification et la création de cours. Début de la rédaction du chapitre 3. |
| **Semaine 5** | Développement de la sécurité : Authentification JWT et Spring Security. Mise à jour du diagramme de classes global et de la structure documentaire MongoDB. Rédaction du chapitre 3 en parallèle. |
| **Semaine 6** | Développement de la gestion des cours, du contenu multimédia (vidéos, ressources) et du système de catégories. Gestion fine des rôles et des permissions. Mise à jour du chapitre 3. |
| **Semaine 7** | Développement du module d'inscription (Enrollment), du suivi de progression (LessonProgress) et des évaluations (Quizzes). Intégration de l'API Stripe pour les abonnements et paiements. Mise à jour du chapitre 3. |
| **Semaine 8** | Développement du système de notifications, de la messagerie interne et des badges de récompense. Mise à jour globale du diagramme de classes et finalisation du backend de base. |
| **Semaine 9** | Développement frontend React : Interfaces dynamiques pour le catalogue de cours, le lecteur vidéo et le tableau de bord utilisateur. Début de la rédaction du chapitre 4. |
| **Semaine 10** | Développement du système de recommandation en Python : Prétraitement des données, moteur de recommandation basé sur le profil et les préférences, et intégration via API REST avec le backend Spring Boot. |
| **Semaine 11** | Développement de l'application mobile Flutter : Interface de consultation mobile, notifications push et accès hors-ligne. Tests unitaires et d'intégration (JUnit). Rédaction et mise à jour du chapitre 4. |
| **Semaine 12** | Corrections et révisions finales du mémoire, vérification de la cohérence des diagrammes UML par rapport au code produit, relecture et optimisation du code source et des requêtes MongoDB. |
