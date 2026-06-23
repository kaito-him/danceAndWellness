# danceAndWellness
a web centralizing course management, user tracking, multimedia content distribution, and e-commerce functionalities. The solution will integrate an artificial intelligence module capable of generating personalized recommendations, tracking user engagement and progress, and providing intelligent and motivating feedback.

## Architecture

The architecture is organized into four tiers, each with a well-defined responsibility:

**Client tier** — Two independent frontends communicate with the backend exclusively through RESTful HTTPS calls. The web client is built with React, relying on component-based UI design, React Router for navigation, and Axios for HTTP requests. The mobile client is developed with Flutter, using the Provider package for state management and Dio as the HTTP client. This separation ensures that both frontends remain interchangeable and independently deployable without affecting backend logic.

**Backend tier** — The core of the system is a Spring Boot application that exposes a REST API consumed by both frontends. Internally, it is structured into several main packages: Controllers handle incoming HTTP requests and map them to service calls; Services contain the business logic (enrollment, progress tracking, badge awarding, etc.); Repositories abstract all database interactions using Spring Data MongoDB; and Security manages authentication and authorization via JWT tokens with Spring Security. Two additional modules complete the backend: DTOs/Entities define the request/response contracts, and Email Service handles all transactional email notifications via JavaMailSender.

**Data tier** — MongoDB is used as the primary database, managed through MongoDB Compass. Its document-oriented model is well suited to the platform's flexible data structures, particularly for entities such as courses (with embedded lessons and quizzes), user profiles with nested preferences, and progress records. Spring Data MongoDB handles all query and persistence operations from the backend.

**AI engine tier** — The recommendation and progress analysis features are delegated to a standalone Python microservice, built with Flask and powered by scikit-learn. It exposes its own REST endpoints that the Spring Boot backend calls via HTTP. This separation allows the machine learning models to be developed, trained, and updated independently of the main application, following a microservices principle for AI concerns.

This layered architecture promotes a clear separation of concerns, facilitates independent scaling of each component, and allows the web and mobile clients to evolve in parallel while sharing the same backend and data sources.
