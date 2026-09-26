# AGENTS.md

Este repositorio usa `CLAUDE.md` como guía principal para cualquier agente de código.
Léelo primero; aquí solo va lo mínimo.

- Proyecto: **AgroClima Jalapa**, app Flutter (Android, minSdk 26) + Firebase + OpenWeather (plan gratuito).
- Idioma: interfaz, commits y documentación en **español**; nombres del dominio en español sin tildes.
- Arquitectura: MVVM con `provider`; capas presentación → servicios → repositorios. Ciclo automático en `functions/` (JavaScript).
- Fuente de verdad: `docs/` (requisitos, modelo de datos, umbrales, diseño UI, orden de trabajo). El código debe coincidir con la tesis.
- Antes de cerrar una tarea: `flutter analyze`, `flutter test` y la Definición de listo de `CLAUDE.md` §6.
- Nunca subir claves ni `google-services.json` / `firebase_options.dart` / `env/*.json`.
- Si algo no está definido en `docs/`, pregunta y regístralo en `docs/DECISIONES.md`.
