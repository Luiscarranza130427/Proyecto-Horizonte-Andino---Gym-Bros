-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 21-09-2026 a las 23:15:33
-- Versión del servidor: 8.0.30
-- Versión de PHP: 8.3.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `gym-bros`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alimentos`
--

CREATE TABLE `alimentos` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` enum('proteina','carbohidrato','grasa','fruta','verdura','lacteo','cereal','legumbre','bebida','otro') COLLATE utf8mb4_unicode_ci NOT NULL,
  `calorias` decimal(6,2) NOT NULL,
  `proteinas` decimal(6,2) NOT NULL,
  `carbohidratos` decimal(6,2) NOT NULL,
  `grasas` decimal(6,2) NOT NULL,
  `fibra` decimal(6,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `base_unidad` enum('gramos','mililitros') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado_preparacion` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gramos_por_unidad` decimal(8,2) DEFAULT NULL,
  `densidad_g_ml` decimal(8,4) DEFAULT NULL,
  `fuente_nutricional` text COLLATE utf8mb4_unicode_ci,
  `nutricion_verificada` tinyint(1) NOT NULL DEFAULT '0',
  `restricciones_verificadas` tinyint(1) NOT NULL DEFAULT '0',
  `grupo_menu` enum('proteina','carbohidrato','grasa','fruta','verdura') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipos_comida` json DEFAULT NULL,
  `porcion_min` decimal(8,2) DEFAULT NULL,
  `porcion_max` decimal(8,2) DEFAULT NULL,
  `paso_porcion` decimal(8,2) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `alimentos`
--

INSERT INTO `alimentos` (`id`, `nombre`, `tipo`, `calorias`, `proteinas`, `carbohidratos`, `grasas`, `fibra`, `created_at`, `updated_at`, `base_unidad`, `estado_preparacion`, `gramos_por_unidad`, `densidad_g_ml`, `fuente_nutricional`, `nutricion_verificada`, `restricciones_verificadas`, `grupo_menu`, `tipos_comida`, `porcion_min`, `porcion_max`, `paso_porcion`, `activo`) VALUES
(1, 'Pechuga de pollos', 'proteina', 165.00, 31.00, 0.00, 3.60, 0.00, '2026-09-07 23:16:09', '2026-09-22 00:12:56', 'gramos', 'Simulado - no destinado a consumo', 100.00, 1.0000, 'BEDCA', 100, 1, 'proteina', '[\"desayuno\", \"almuerzo\"]', 1.00, 600.00, 1.00, 1),
(2, 'Arroz integral', 'carbohidrato', 111.00, 2.60, 23.00, 0.90, 1.80, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 'mililitros', 'Simulado - no destinado a consumo', 100.00, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(3, 'Palta', 'grasa', 160.00, 2.00, 8.50, 14.70, 6.70, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 'mililitros', 'Simulado - no destinado a consumo', 100.00, NULL, 'BEDCA', 100, 1, 'grasa', NULL, 1.00, 600.00, 1.00, 1),
(4, 'Platano', 'fruta', 89.00, 1.10, 22.80, 0.30, 2.60, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 'gramos', 'Simulado - no destinado a consumo', 100.00, NULL, 'BEDCA', 100, 1, 'fruta', NULL, 1.00, 600.00, 1.00, 1),
(5, 'Brocoli', 'verdura', 34.00, 2.80, 6.60, 0.40, 2.60, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 'mililitros', 'Simulado - no destinado a consumo', 100.00, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(6, 'Pechuga de pavo', 'proteina', 135.00, 29.00, 0.00, 1.80, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'grasa', NULL, 1.00, 600.00, 1.00, 1),
(7, 'Atun en agua', 'proteina', 116.00, 25.50, 0.00, 0.80, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(8, 'Salmon', 'proteina', 208.00, 20.50, 0.00, 13.40, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(9, 'Carne de res magra', 'proteina', 172.00, 26.00, 0.00, 7.00, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(10, 'Huevo entero', 'proteina', 143.00, 12.60, 0.70, 9.50, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(11, 'Claras de huevo', 'proteina', 52.00, 10.90, 0.70, 0.20, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'grasa', NULL, 1.00, 600.00, 1.00, 1),
(12, 'Yogur griego natural', 'lacteo', 59.00, 10.00, 3.60, 0.40, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(13, 'Leche descremada', 'lacteo', 34.00, 3.40, 5.00, 0.10, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(14, 'Queso fresco', 'lacteo', 265.00, 18.00, 3.40, 20.00, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(15, 'Quinua cocida', 'cereal', 120.00, 4.40, 21.30, 1.90, 2.80, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(16, 'Avena', 'cereal', 389.00, 16.90, 66.30, 6.90, 10.60, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(17, 'Papa sancochada', 'carbohidrato', 87.00, 1.90, 20.10, 0.10, 1.80, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(18, 'Camote', 'carbohidrato', 86.00, 1.60, 20.10, 0.10, 3.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(19, 'Pasta integral cocida', 'carbohidrato', 149.00, 5.80, 30.10, 1.60, 3.90, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(20, 'Pan integral', 'carbohidrato', 247.00, 13.00, 41.00, 4.20, 7.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(21, 'Lentejas cocidas', 'legumbre', 116.00, 9.00, 20.10, 0.40, 7.90, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'grasa', NULL, 1.00, 600.00, 1.00, 1),
(22, 'Garbanzos cocidos', 'legumbre', 164.00, 8.90, 27.40, 2.60, 7.60, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'grasa', NULL, 1.00, 600.00, 1.00, 1),
(23, 'Frijol negro cocido', 'legumbre', 132.00, 8.90, 23.70, 0.50, 8.70, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(24, 'Manzana', 'fruta', 52.00, 0.30, 13.80, 0.20, 2.40, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(25, 'Naranja', 'fruta', 47.00, 0.90, 11.80, 0.10, 2.40, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(26, 'Fresas', 'fruta', 32.00, 0.70, 7.70, 0.30, 2.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(27, 'Arandanos', 'fruta', 57.00, 0.70, 14.50, 0.30, 2.40, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(28, 'Espinaca', 'verdura', 23.00, 2.90, 3.60, 0.40, 2.20, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(29, 'Zanahoria', 'verdura', 41.00, 0.90, 9.60, 0.20, 2.80, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'verdura', NULL, 1.00, 600.00, 1.00, 1),
(30, 'Tomate', 'verdura', 18.00, 0.90, 3.90, 0.20, 1.20, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(31, 'Coliflor', 'verdura', 25.00, 1.90, 5.00, 0.30, 2.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(32, 'Aceite de oliva', 'grasa', 884.00, 0.00, 0.00, 100.00, 0.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'fruta', NULL, 1.00, 600.00, 1.00, 1),
(33, 'Almendras', 'grasa', 579.00, 21.20, 21.60, 49.90, 12.50, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'carbohidrato', NULL, 1.00, 600.00, 1.00, 1),
(34, 'Mantequilla de mani', 'grasa', 588.00, 25.10, 20.00, 50.00, 6.00, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(35, 'Agua de coco', 'bebida', 19.00, 0.70, 3.70, 0.20, 1.10, '2026-09-11 05:19:18', '2026-09-11 05:19:18', 'mililitros', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 100, 1, 'proteina', NULL, 1.00, 600.00, 1.00, 1),
(37, '[DEMO] proteina 3 b8546d61', 'proteina', 138.00, 25.00, 5.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'proteina', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(38, '[DEMO] proteina 2 b85', 'proteina', 138.00, 25.00, 5.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'proteina', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(39, '[DEMO] proteina 1 b85', 'proteina', 138.00, 25.00, 5.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'proteina', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(40, '[DEMO] carbohidrato 3', 'carbohidrato', 226.00, 2.00, 50.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'carbohidrato', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(41, '[DEMO] carbohidrato 2 b8546', 'carbohidrato', 226.00, 2.00, 50.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'carbohidrato', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(42, '[DEMO] carbohidrato 1 ', 'carbohidrato', 226.00, 2.00, 50.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'carbohidrato', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(43, '[DEMO] grasa 3 b85', 'grasa', 900.00, 0.00, 0.00, 100.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'grasa', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 60.00, 1.00, 1),
(44, '[DEMO] grasa 2 b854', 'grasa', 900.00, 0.00, 0.00, 100.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'grasa', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 60.00, 1.00, 1),
(45, '[DEMO] grasa 1 ', 'grasa', 900.00, 0.00, 0.00, 100.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'grasa', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 60.00, 1.00, 1),
(46, '[DEMO] fruta 3 ', 'fruta', 48.00, 1.00, 11.00, 0.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'fruta', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(47, '[DEMO] fruta 2 b8546', 'fruta', 48.00, 1.00, 11.00, 0.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'fruta', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(48, '[DEMO] fruta 1 b85', 'fruta', 48.00, 1.00, 11.00, 0.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'fruta', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(49, '[DEMO] verdura 3 b', 'verdura', 28.00, 2.00, 5.00, 0.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'verdura', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(50, '[DEMO] verdura 2 b8', 'verdura', 28.00, 2.00, 5.00, 0.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'verdura', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(51, '[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666', 'verdura', 28.00, 2.00, 5.00, 0.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'verdura', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(52, '[DEMO] EXCLUIR alergia b8546', 'proteina', 138.00, 25.00, 5.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'proteina', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(53, '[DEMO] EXCLUIR11f188ec6c9466970666', 'proteina', 138.00, 25.00, 5.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'proteina', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1),
(54, '[DEMO] EXCLUIR rechazo b8546d61', 'proteina', 138.00, 25.00, 5.00, 2.00, 0.00, '2026-09-12 09:45:03', '2026-09-12 09:45:03', 'gramos', 'Simulado - no destinado a consumo', NULL, NULL, 'BEDCA', 1, 1, 'proteina', '[\"desayuno\", \"media_manana\", \"almuerzo\", \"media_tarde\", \"cena\"]', 1.00, 600.00, 1.00, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `banners`
--

CREATE TABLE `banners` (
  `id` bigint UNSIGNED NOT NULL,
  `imagen` varchar(250) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contenido_text` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `texto_boton` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `enlace_boton` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `banners`
--

INSERT INTO `banners` (`id`, `imagen`, `contenido_text`, `texto_boton`, `enlace_boton`, `created_at`, `updated_at`) VALUES
(1, '\\storage\\app\\public\\banners-web\\banner-prueba-gymbros.webp', 'Entrena con una rutina personalizada.', 'Solicitar Código', 'https://gymbros.test/rutinas', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, '\\storage\\app\\public\\banners-web\\banner-prueba-gymbros.webp', 'Mejora tu alimentacion semanal.', 'Solicitar Código', 'https://gymbros.test/alimentacion', '2026-09-07 23:16:09', '2026-09-07 23:16:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comidas`
--

CREATE TABLE `comidas` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` enum('desayuno','media_manana','almuerzo','media_tarde','cena','snack','otro') COLLATE utf8mb4_unicode_ci NOT NULL,
  `orden` int NOT NULL,
  `hora_sugerida` time NOT NULL,
  `notas` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_planes_alimentacion` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `dia` smallint UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `comidas`
--

INSERT INTO `comidas` (`id`, `nombre`, `tipo`, `orden`, `hora_sugerida`, `notas`, `id_planes_alimentacion`, `created_at`, `updated_at`, `fecha`, `dia`) VALUES
(1, 'Desayuno volumen', 'desayuno', 1, '07:30:00', 'Comida alta en carbohidratos para iniciar el dia.', 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL, NULL),
(2, 'Almuerzo volumen', 'almuerzo', 2, '13:00:00', 'Comida principal con proteina magra.', 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL, NULL),
(3, 'Desayuno deficit', 'desayuno', 1, '08:00:00', 'Porcion moderada y saciante.', 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL, NULL),
(4, 'Cena deficit', 'cena', 2, '20:00:00', 'Cena ligera con verduras.', 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL, NULL),
(47, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-12', 1),
(48, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-12', 1),
(49, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-12', 1),
(50, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-13', 2),
(51, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-13', 2),
(52, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-13', 2),
(53, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-14', 3),
(54, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-14', 3),
(55, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-14', 3),
(56, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-15', 4),
(57, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-15', 4),
(58, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-15', 4),
(59, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-16', 5),
(60, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-16', 5),
(61, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-16', 5),
(62, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-17', 6),
(63, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-17', 6),
(64, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-17', 6),
(65, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-18', 7),
(66, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-18', 7),
(67, 'Cena', 'cena', 3, '19:00:00', 'Menu general sujeto a seguimiento profesional.', 5, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '2026-09-18', 7),
(68, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-14', 1),
(69, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-14', 1),
(70, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-14', 1),
(71, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-15', 2),
(72, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-15', 2),
(73, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-15', 2),
(74, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-16', 3),
(75, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-16', 3),
(76, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-16', 3),
(77, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-17', 4),
(78, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-17', 4),
(79, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-17', 4),
(80, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-18', 5),
(81, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-18', 5),
(82, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-18', 5),
(83, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-19', 6),
(84, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-19', 6),
(85, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-19', 6),
(86, 'Desayuno', 'desayuno', 1, '08:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-20', 7),
(87, 'Almuerzo', 'almuerzo', 2, '13:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-20', 7),
(88, 'Cena', 'cena', 3, '20:00:00', 'Menu general sujeto a seguimiento profesional.', 6, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '2026-09-20', 7);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comida_alimentos`
--

CREATE TABLE `comida_alimentos` (
  `id` bigint UNSIGNED NOT NULL,
  `cantidad` decimal(8,2) NOT NULL,
  `unidad` enum('gramos','mililitros','unidad') COLLATE utf8mb4_unicode_ci NOT NULL,
  `notas` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_comidas` bigint UNSIGNED NOT NULL,
  `id_alimentos` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `detalle_nutricional` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `comida_alimentos`
--

INSERT INTO `comida_alimentos` (`id`, `cantidad`, `unidad`, `notas`, `id_comidas`, `id_alimentos`, `created_at`, `updated_at`, `detalle_nutricional`) VALUES
(1, 120.00, 'gramos', 'Porcion cocida.', 1, 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(2, 1.00, 'unidad', 'Platano mediano.', 1, 4, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(3, 180.00, 'gramos', 'Pechuga a la plancha.', 2, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(4, 100.00, 'gramos', 'Acompanar con arroz.', 2, 5, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(5, 1.00, 'unidad', 'Platano pequeno.', 3, 4, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(6, 150.00, 'gramos', 'Pechuga a la plancha.', 4, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(7, 120.00, 'gramos', 'Verdura al vapor.', 4, 5, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(176, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 47, 37, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(177, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 47, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(178, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 47, 46, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(179, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 47, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(180, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 48, 38, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(181, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 48, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(182, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 48, 49, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(183, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 48, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(184, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 49, 39, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(185, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 49, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(186, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 49, 50, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(187, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 49, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(188, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 50, 52, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR alergia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(189, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 50, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(190, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 50, 47, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(191, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 50, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(192, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 51, 53, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR intolerancia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(193, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 51, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(194, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 51, 51, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(195, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 51, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(196, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 52, 54, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR rechazo b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(197, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 52, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(198, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 52, 49, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(199, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 52, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(200, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 53, 37, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(201, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 53, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(202, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 53, 48, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(203, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 53, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(204, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 54, 38, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(205, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 54, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(206, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 54, 50, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(207, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 54, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(208, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 55, 39, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(209, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 55, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(210, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 55, 51, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(211, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 55, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(212, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 56, 52, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR alergia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(213, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 56, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(214, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 56, 46, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(215, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 56, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(216, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 57, 53, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR intolerancia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(217, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 57, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(218, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 57, 49, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(219, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 57, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(220, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 58, 54, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR rechazo b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(221, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 58, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(222, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 58, 50, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(223, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 58, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(224, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 59, 37, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(225, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 59, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(226, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 59, 47, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(227, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 59, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(228, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 60, 38, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(229, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 60, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(230, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 60, 51, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(231, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 60, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(232, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 61, 39, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(233, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 61, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(234, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 61, 49, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(235, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 61, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(236, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 62, 52, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR alergia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(237, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 62, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(238, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 62, 48, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(239, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 62, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(240, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 63, 53, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR intolerancia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(241, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 63, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(242, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 63, 50, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(243, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 63, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(244, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 64, 54, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR rechazo b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(245, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 64, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(246, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 64, 51, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(247, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 64, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(248, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 65, 37, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(249, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 65, 40, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(250, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 65, 46, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(251, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 65, 43, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(252, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 66, 38, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(253, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 66, 41, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(254, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 66, 49, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(255, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 66, 44, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(256, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 67, 39, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(257, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 67, 42, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(258, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 67, 50, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(259, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 67, 45, '2026-09-13 03:10:03', '2026-09-13 03:10:03', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(260, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 68, 37, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(261, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 68, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(262, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 68, 46, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(263, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 68, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(264, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 69, 38, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(265, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 69, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}');
INSERT INTO `comida_alimentos` (`id`, `cantidad`, `unidad`, `notas`, `id_comidas`, `id_alimentos`, `created_at`, `updated_at`, `detalle_nutricional`) VALUES
(266, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 69, 49, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(267, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 69, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(268, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 70, 39, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(269, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 70, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(270, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 70, 50, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(271, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 70, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(272, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 71, 52, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR alergia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(273, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 71, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(274, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 71, 47, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(275, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 71, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(276, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 72, 53, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR intolerancia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(277, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 72, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(278, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 72, 51, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(279, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 72, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(280, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 73, 54, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR rechazo b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(281, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 73, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(282, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 73, 49, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(283, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 73, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(284, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 74, 37, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(285, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 74, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(286, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 74, 48, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(287, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 74, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(288, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 75, 38, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(289, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 75, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(290, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 75, 50, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(291, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 75, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(292, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 76, 39, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(293, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 76, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(294, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 76, 51, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(295, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 76, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(296, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 77, 52, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR alergia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(297, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 77, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(298, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 77, 46, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(299, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 77, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(300, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 78, 53, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR intolerancia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(301, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 78, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(302, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 78, 49, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(303, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 78, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(304, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 79, 54, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR rechazo b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(305, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 79, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(306, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 79, 50, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(307, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 79, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(308, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 80, 37, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(309, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 80, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(310, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 80, 47, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(311, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 80, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(312, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 81, 38, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(313, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 81, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(314, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 81, 51, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(315, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 81, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(316, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 82, 39, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(317, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 82, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(318, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 82, 49, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(319, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 82, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(320, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 83, 52, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR alergia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(321, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 83, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(322, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 83, 48, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(323, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 83, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(324, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 84, 53, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR intolerancia b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(325, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 84, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(326, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 84, 50, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(327, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 84, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(328, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 85, 54, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] EXCLUIR rechazo b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(329, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 85, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(330, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 85, 51, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(331, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 85, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(332, 148.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 86, 37, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.96, \"calorias\": 204.24, \"proteinas\": 37, \"carbohidratos\": 7.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(333, 120.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 86, 40, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.4, \"calorias\": 271.2, \"proteinas\": 2.4, \"carbohidratos\": 60}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(334, 496.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 86, 46, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] fruta 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 238.08, \"proteinas\": 4.96, \"carbohidratos\": 54.56}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(335, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 86, 43, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(336, 173.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 87, 38, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.46, \"calorias\": 238.74, \"proteinas\": 43.25, \"carbohidratos\": 8.65}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(337, 254.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 87, 41, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 5.08, \"calorias\": 574.04, \"proteinas\": 5.08, \"carbohidratos\": 127}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(338, 538.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 87, 49, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 3 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 150.64, \"proteinas\": 10.76, \"carbohidratos\": 26.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(339, 24.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 87, 44, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 24, \"calorias\": 216, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(340, 118.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 88, 39, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] proteina 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 2.36, \"calorias\": 162.84, \"proteinas\": 29.5, \"carbohidratos\": 5.9}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(341, 175.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 88, 42, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] carbohidrato 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 3.5, \"calorias\": 395.5, \"proteinas\": 3.5, \"carbohidratos\": 87.5}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(342, 568.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 88, 50, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] verdura 2 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 0, \"calorias\": 159.04, \"proteinas\": 11.36, \"carbohidratos\": 28.4}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}'),
(343, 19.00, 'gramos', 'Cantidad de alimento en estado: Simulado - no destinado a consumo.', 88, 45, '2026-09-13 03:21:34', '2026-09-13 03:21:34', '{\"fuente\": \"DATOS SINTETICOS - NO CONSUMO REAL - lote b8546d61ae6411f188ec6c9466970666\", \"nombre\": \"[DEMO] grasa 1 b8546d61ae6411f188ec6c9466970666\", \"nutrientes\": {\"fibra\": 0, \"grasas\": 19, \"calorias\": 171, \"proteinas\": 0, \"carbohidratos\": 0}, \"base_unidad\": \"gramos\", \"base_cantidad\": 100, \"estado_preparacion\": \"Simulado - no destinado a consumo\"}');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ejercicios`
--

CREATE TABLE `ejercicios` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `tipo` enum('fuerza','cardio','flexibilidad','equilibrio') COLLATE utf8mb4_unicode_ci NOT NULL,
  `instrucciones` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `nivel` enum('principiante','intermedio','avanzado') COLLATE utf8mb4_unicode_ci NOT NULL,
  `equipamiento` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '0',
  `enlace_video` varchar(350) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imagen_ejercicio` varchar(350) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_grupos_musculares` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ejercicios`
--

INSERT INTO `ejercicios` (`id`, `nombre`, `descripcion`, `tipo`, `instrucciones`, `nivel`, `equipamiento`, `estado`, `enlace_video`, `imagen_ejercicio`, `id_grupos_musculares`, `created_at`, `updated_at`) VALUES
(1, 'Press banca', 'Ejercicio basico de empuje para pecho.', 'fuerza', 'Mantener escapulas retraidas, bajar controlado y empujar sin despegar la espalda.', 'intermedio', 'barra y banco', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 'Remo con polea', 'Ejercicio de traccion para espalda.', 'fuerza', 'Tirar la polea hacia el abdomen manteniendo el torso estable.', 'principiante', 'polea', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(3, 'Sentadilla goblet', 'Ejercicio para piernas con mancuerna.', 'fuerza', 'Bajar manteniendo rodillas alineadas y pecho arriba.', 'principiante', 'mancuerna', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 3, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(4, 'Plancha frontal', 'Ejercicio de estabilidad abdominal.', 'equilibrio', 'Mantener abdomen activo y cadera alineada.', 'principiante', 'peso corporal', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 4, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(5, 'Press inclinado con mancuernas', 'Ejercicio de empuje enfocado en la parte superior del pecho.', 'fuerza', 'Ajustar el banco inclinado, bajar las mancuernas con control y empujar sin bloquear agresivamente los codos.', 'intermedio', 'mancuernas y banco', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(6, 'Aperturas en maquina', 'Ejercicio de aislamiento para pecho.', 'fuerza', 'Mantener la espalda apoyada, juntar los brazos al frente y regresar controlando el movimiento.', 'principiante', 'maquina contractora', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(7, 'Fondos asistidos', 'Ejercicio de empuje para pecho y triceps.', 'fuerza', 'Mantener el torso ligeramente inclinado y bajar hasta un rango comodo sin dolor.', 'intermedio', 'maquina asistida', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(8, 'Jalon al pecho', 'Ejercicio de traccion vertical para espalda.', 'fuerza', 'Tirar la barra hacia la parte alta del pecho manteniendo los hombros abajo y el torso estable.', 'principiante', 'polea alta', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 2, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(9, 'Remo con mancuerna', 'Ejercicio unilateral para espalda.', 'fuerza', 'Apoyar una mano en el banco, llevar la mancuerna hacia la cadera y controlar la bajada.', 'intermedio', 'mancuerna y banco', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 2, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(10, 'Peso muerto rumano', 'Ejercicio dominante de cadera para cadena posterior.', 'fuerza', 'Flexionar ligeramente rodillas, llevar la cadera atras y mantener la espalda neutra durante todo el recorrido.', 'intermedio', 'barra', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 8, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(11, 'Prensa de piernas', 'Ejercicio de tren inferior con maquina.', 'fuerza', 'Ubicar los pies firmes, bajar con control y empujar sin despegar la cadera del asiento.', 'principiante', 'prensa', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 3, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(12, 'Extension de cuadriceps', 'Ejercicio de aislamiento para cuadriceps.', 'fuerza', 'Extender las piernas hasta contraer el cuadriceps y regresar lentamente.', 'principiante', 'maquina extension', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 3, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(13, 'Curl femoral acostado', 'Ejercicio de aislamiento para isquiotibiales.', 'fuerza', 'Flexionar rodillas llevando el rodillo hacia los gluteos y controlar la fase de bajada.', 'principiante', 'maquina curl femoral', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 8, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(14, 'Hip thrust con barra', 'Ejercicio principal para gluteos.', 'fuerza', 'Apoyar la espalda alta en banco, empujar la cadera hacia arriba y contraer gluteos al final.', 'intermedio', 'barra y banco', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 9, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(15, 'Patada de gluteo en polea', 'Ejercicio de aislamiento para gluteos.', 'fuerza', 'Mantener el torso estable y extender la pierna hacia atras sin arquear la espalda.', 'principiante', 'polea baja', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 9, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(16, 'Elevacion de talones de pie', 'Ejercicio para pantorrillas.', 'fuerza', 'Subir los talones hasta la maxima contraccion y bajar lentamente.', 'principiante', 'maquina pantorrilla', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 10, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(17, 'Press militar con barra', 'Ejercicio de empuje vertical para hombros.', 'fuerza', 'Empujar la barra sobre la cabeza manteniendo el abdomen firme y la trayectoria controlada.', 'intermedio', 'barra', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 5, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(18, 'Elevaciones laterales', 'Ejercicio de aislamiento para deltoides lateral.', 'fuerza', 'Elevar las mancuernas hasta la altura de los hombros sin balancear el cuerpo.', 'principiante', 'mancuernas', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 5, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(19, 'Face pull', 'Ejercicio para hombro posterior y estabilidad escapular.', 'fuerza', 'Tirar la cuerda hacia el rostro separando las manos y manteniendo codos altos.', 'principiante', 'polea con cuerda', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 5, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(20, 'Curl con barra', 'Ejercicio basico para biceps.', 'fuerza', 'Flexionar los codos sin balancear el torso y bajar la barra de forma controlada.', 'principiante', 'barra', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 6, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(21, 'Curl martillo', 'Ejercicio para biceps y braquial.', 'fuerza', 'Mantener agarre neutro y elevar las mancuernas sin mover los hombros hacia adelante.', 'principiante', 'mancuernas', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 6, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(22, 'Curl predicador', 'Ejercicio de aislamiento para biceps.', 'fuerza', 'Apoyar brazos en el banco predicador, flexionar codos y evitar perder tension abajo.', 'intermedio', 'banco predicador', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 6, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(23, 'Extension de triceps en polea', 'Ejercicio de aislamiento para triceps.', 'fuerza', 'Mantener codos pegados al cuerpo y extender hasta contraer completamente el triceps.', 'principiante', 'polea con cuerda', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 7, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(24, 'Press frances', 'Ejercicio para triceps con barra.', 'fuerza', 'Bajar la barra hacia la frente controlando los codos y extender sin abrirlos demasiado.', 'intermedio', 'barra z', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 7, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(25, 'Abdominal crunch', 'Ejercicio basico para abdomen.', 'fuerza', 'Elevar el torso contrayendo abdomen sin tirar del cuello.', 'principiante', 'colchoneta', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 4, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(26, 'Elevacion de piernas', 'Ejercicio para abdomen inferior.', 'fuerza', 'Elevar piernas manteniendo la zona lumbar controlada y bajar lentamente.', 'intermedio', 'barra o banco', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 4, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(27, 'Plancha lateral', 'Ejercicio de estabilidad para oblicuos.', 'equilibrio', 'Apoyar antebrazo y pies, mantener cadera elevada y cuerpo alineado.', 'principiante', 'colchoneta', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 14, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(28, 'Pallof press', 'Ejercicio antirotacional para core.', 'equilibrio', 'Empujar la polea al frente resistiendo la rotacion del torso.', 'intermedio', 'polea o banda', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 14, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(29, 'Hiperextension lumbar', 'Ejercicio para lumbares y cadena posterior.', 'fuerza', 'Subir el torso hasta quedar alineado, sin extender excesivamente la espalda.', 'principiante', 'banco romano', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 15, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(30, 'Encogimientos con mancuernas', 'Ejercicio para trapecios.', 'fuerza', 'Elevar hombros hacia arriba sin rotarlos y bajar controladamente.', 'principiante', 'mancuernas', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 12, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(31, 'Curl de muneca', 'Ejercicio de aislamiento para antebrazos.', 'fuerza', 'Apoyar antebrazos, flexionar munecas y controlar el regreso.', 'principiante', 'barra o mancuerna', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 11, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(32, 'Aduccion en maquina', 'Ejercicio para aductores.', 'fuerza', 'Cerrar las piernas contra la resistencia y regresar sin perder control.', 'principiante', 'maquina aductora', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 16, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(33, 'Abduccion en maquina', 'Ejercicio para abductores.', 'fuerza', 'Abrir las piernas contra la resistencia manteniendo la espalda apoyada.', 'principiante', 'maquina abductora', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 17, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(34, 'Serratus wall slide', 'Ejercicio de control escapular para serratos.', 'flexibilidad', 'Deslizar los antebrazos por la pared manteniendo control escapular y respiracion estable.', 'principiante', 'pared o banda', 1, 'https://youtu.be/tIxLU8WUK1Y?si=lhQksaPRLvGLmzaN', '\\storage\\app\\public\\ejercicios\\trabajar-musculo.webp', 13, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(35, 'Gym bros', 'isabijasn adajnd psdifjnsad fkjsdanfvalsk dalksjdnv adskjnf sasadas', 'flexibilidad', 'isabijasn adajnd psdifjnsad fkjsdanfvalsk dalksjdnv adskjnf sasadas', 'principiante', 'barra', 0, 'https://youtu.be/RSRzIrOqaN4?si=GSf6mto0RfIn24uU', 'ejercicios/0H2H60zMI36MyTk0yVLb0WaigZiNqdAv2ybAvVzC.webp', 12, '2026-09-18 03:42:16', '2026-09-18 03:42:16');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ejercicios_grupo_muscular`
--

CREATE TABLE `ejercicios_grupo_muscular` (
  `id` bigint UNSIGNED NOT NULL,
  `id_ejercicios` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `id_grupos_musculares` bigint UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ejercicios_grupo_muscular`
--

INSERT INTO `ejercicios_grupo_muscular` (`id`, `id_ejercicios`, `created_at`, `updated_at`, `id_grupos_musculares`) VALUES
(1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 1),
(2, 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 2),
(3, 3, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 3),
(4, 4, '2026-09-07 23:16:09', '2026-09-07 23:16:09', 4),
(5, 5, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 1),
(6, 6, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 1),
(7, 7, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 1),
(8, 8, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 2),
(9, 9, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 2),
(10, 10, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 8),
(11, 11, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 3),
(12, 12, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 3),
(13, 13, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 8),
(14, 14, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 9),
(15, 15, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 9),
(16, 16, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 10),
(17, 17, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 5),
(18, 18, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 5),
(19, 19, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 5),
(20, 20, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 6),
(21, 21, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 6),
(22, 22, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 6),
(23, 23, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 7),
(24, 24, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 7),
(25, 25, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 4),
(26, 26, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 4),
(27, 27, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 14),
(28, 28, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 14),
(29, 29, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 15),
(30, 30, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 12),
(31, 31, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 11),
(32, 32, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 16),
(33, 33, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 17),
(34, 34, '2026-09-09 14:14:21', '2026-09-09 14:14:21', 13);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ejercicios_rutina`
--

CREATE TABLE `ejercicios_rutina` (
  `id` bigint UNSIGNED NOT NULL,
  `dia` int NOT NULL,
  `orden` int NOT NULL,
  `series` int NOT NULL,
  `repeticiones` int NOT NULL,
  `peso` decimal(6,2) NOT NULL,
  `descanso_segundos` int NOT NULL,
  `tiempo_segundos` int NOT NULL,
  `notas` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_rutinas` bigint UNSIGNED NOT NULL,
  `id_ejercicios` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ejercicios_rutina`
--

INSERT INTO `ejercicios_rutina` (`id`, `dia`, `orden`, `series`, `repeticiones`, `peso`, `descanso_segundos`, `tiempo_segundos`, `notas`, `id_rutinas`, `id_ejercicios`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 4, 10, 40.00, 90, 0, 'Calentar antes de la primera serie.', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 1, 2, 4, 12, 35.00, 75, 0, 'Mantener control en la fase excentrica.', 1, 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(3, 2, 1, 3, 12, 18.00, 75, 0, 'Usar peso moderado y buena tecnica.', 1, 3, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(4, 1, 1, 3, 15, 12.00, 60, 0, 'Ritmo constante.', 2, 3, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(5, 1, 2, 3, 0, 0.00, 45, 30, 'Mantener postura estable.', 2, 4, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(6, 1, 1, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 3, 1, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(7, 1, 2, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 3, 9, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(8, 1, 3, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 3, 17, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(9, 1, 4, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 3, 22, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(10, 1, 5, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 3, 24, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(11, 1, 6, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 3, 26, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(12, 2, 1, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 3, 3, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(13, 2, 2, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 3, 10, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(14, 2, 3, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 3, 14, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(15, 2, 4, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 3, 16, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(16, 3, 1, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 3, 5, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(17, 3, 2, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 3, 9, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(18, 3, 3, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 3, 17, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(19, 3, 4, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 3, 22, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(20, 3, 5, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 3, 24, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(21, 3, 6, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 3, 26, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(22, 4, 1, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 3, 11, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(23, 4, 2, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 3, 10, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(24, 4, 3, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 3, 14, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(25, 4, 4, 3, 10, 0.00, 90, 300, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 3, 16, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(26, 1, 1, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 4, 1, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(27, 1, 2, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 4, 9, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(28, 1, 3, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 4, 17, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(29, 1, 4, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 4, 22, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(30, 1, 5, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 4, 24, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(31, 1, 6, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Lunes.', 4, 26, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(32, 2, 1, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 4, 3, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(33, 2, 2, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 4, 10, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(34, 2, 3, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 4, 14, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(35, 2, 4, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Martes.', 4, 16, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(36, 3, 1, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 4, 5, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(37, 3, 2, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 4, 9, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(38, 3, 3, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 4, 17, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(39, 3, 4, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 4, 22, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(40, 3, 5, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 4, 24, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(41, 3, 6, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Jueves.', 4, 26, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(42, 4, 1, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 4, 11, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(43, 4, 2, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 4, 10, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(44, 4, 3, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 4, 14, '2026-09-11 10:16:18', '2026-09-11 10:16:18'),
(45, 4, 4, 3, 15, 0.00, 45, 270, 'Peso pendiente de asignacion por el entrenador. Dia semanal: Viernes.', 4, 16, '2026-09-11 10:16:18', '2026-09-11 10:16:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresas`
--

CREATE TABLE `empresas` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_gerente` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region` enum('Amazonas','Ancash','Apurimac','Arequipa','Ayacucho','Cajamarca','Callao','Cusco','Huancavelica','Huanuco','Ica','Junin','La Libertad','Lambayeque','Lima','Loreto','Madre de Dios','Moquegua','Pasco','Piura','Puno','San Martin','Tacna','Tumbes','Ucayali') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ruc` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `enlace_web` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `direccion` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `correo` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `fecha_registro` date NOT NULL,
  `logo` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color_1` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color_2` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `banner_1` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `banner_2` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `banner_3` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_boton_1` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_boton_2` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_boton_3` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `horario_inicio_lunes` decimal(4,2) NOT NULL,
  `horario_fin_lunes` decimal(4,2) NOT NULL,
  `horario_inicio_martes` decimal(4,2) NOT NULL,
  `horario_fin_martes` decimal(4,2) NOT NULL,
  `horario_inicio_miercoles` decimal(4,2) NOT NULL,
  `horario_fin_miercoles` decimal(4,2) NOT NULL,
  `horario_inicio_jueves` decimal(4,2) NOT NULL,
  `horario_fin_jueves` decimal(4,2) NOT NULL,
  `horario_inicio_viernes` decimal(4,2) NOT NULL,
  `horario_fin_viernes` decimal(4,2) NOT NULL,
  `horario_inicio_sabado` decimal(4,2) DEFAULT NULL,
  `horario_fin_sabado` decimal(4,2) DEFAULT NULL,
  `horario_inicio_domingo` decimal(4,2) DEFAULT NULL,
  `horario_fin_domingo` decimal(4,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `empresas`
--

INSERT INTO `empresas` (`id`, `nombre`, `nombre_gerente`, `region`, `ruc`, `enlace_web`, `direccion`, `telefono`, `correo`, `estado`, `fecha_registro`, `logo`, `color_1`, `color_2`, `banner_1`, `banner_2`, `banner_3`, `link_boton_1`, `link_boton_2`, `link_boton_3`, `horario_inicio_lunes`, `horario_fin_lunes`, `horario_inicio_martes`, `horario_fin_martes`, `horario_inicio_miercoles`, `horario_fin_miercoles`, `horario_inicio_jueves`, `horario_fin_jueves`, `horario_inicio_viernes`, `horario_fin_viernes`, `horario_inicio_sabado`, `horario_fin_sabado`, `horario_inicio_domingo`, `horario_fin_domingo`, `created_at`, `updated_at`) VALUES
(1, 'Titan Gym', 'Carlos Mendoza', 'Lima', '20601234567', 'https://gymbros.test', 'Av. Principal 123, Lima', '999888777', 'central@gymbros.test', 1, '2026-09-01', 'empresas/wkV6UTzGRYcDMmiMb523cI7lKuAaTggJeP62iKWT.webp', '#111111', '#BA270D', 'empresas/Y7LaHETUN1vdoj2QmgwVpOJwmAIdfnkw2WRiQIb5.webp', '\\storage\\app\\public\\banners\\banner1.webp', '\\storage\\app\\public\\banners\\banner1.webp', 'https://api.whatsapp.com/send?phone=917905580&text=Hola', 'https://api.whatsapp.com/send?phone=917905580&text=Hola2', 'https://api.whatsapp.com/send?phone=917905580&text=Hola3', 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 7.00, 20.00, NULL, NULL, '2026-09-07 23:16:09', '2026-09-15 21:50:24'),
(2, 'Iron House Fitness', 'Mariana Torres', 'Arequipa', '20607654321', 'https://ironhouse.test', 'Calle Fitness 456, Arequipa', '988777666', 'contacto@ironhouse.test', 1, '2026-09-01', '\\storage\\app\\public\\empresas\\titan-gym.webp', '#202020', '#00AEEF', '\\storage\\app\\public\\banners\\banner1.webp', '\\storage\\app\\public\\banners\\banner1.webp', '\\storage\\app\\public\\banners\\banner1.webp', 'https://api.whatsapp.com/send?phone=917905580&text=Hola', 'https://api.whatsapp.com/send?phone=917905580&text=Hola2', 'https://api.whatsapp.com/send?phone=917905580&text=Hola3', 5.50, 23.00, 5.50, 23.00, 5.50, 23.00, 5.50, 23.00, 5.50, 23.00, 7.00, 21.00, 8.00, 13.00, '2026-09-07 23:16:09', '2026-09-15 23:00:40'),
(3, 'Imprerio', 'Responsable ficticio', 'Lima', '2015857898', NULL, NULL, '000000000', 'contacto@ironhouse.test', 1, '2026-09-12', '', '#167D50', '#FFFFFF', '\\storage\\app\\public\\banners\\banner1.webp', '\\storage\\app\\public\\banners\\banner1.webp', '\\storage\\app\\public\\banners\\banner1.webp', 'https://api.whatsapp.com/send?phone=917905580&text=Hola2', 'https://api.whatsapp.com/send?phone=917905580&text=Hola2', 'https://api.whatsapp.com/send?phone=917905580&text=Hola2', 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, NULL, NULL, NULL, NULL, '2026-09-12 09:45:03', '2026-09-12 09:45:03');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresa_ejercicio`
--

CREATE TABLE `empresa_ejercicio` (
  `id` bigint UNSIGNED NOT NULL,
  `id_empresas` bigint UNSIGNED NOT NULL,
  `id_ejercicios` bigint UNSIGNED NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `empresa_ejercicio`
--

INSERT INTO `empresa_ejercicio` (`id`, `id_empresas`, `id_ejercicios`, `estado`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 0, '2026-09-07 23:16:09', '2026-09-21 10:33:49'),
(2, 1, 2, 0, '2026-09-07 23:16:09', '2026-09-17 21:09:29'),
(3, 1, 3, 0, '2026-09-07 23:16:09', '2026-09-17 21:09:31'),
(4, 1, 4, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(5, 2, 2, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(6, 2, 3, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(7, 2, 4, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(8, 2, 5, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(9, 1, 5, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(10, 2, 6, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(11, 1, 6, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(12, 2, 7, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(13, 1, 7, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(14, 2, 8, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(15, 1, 8, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(16, 2, 9, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(17, 1, 9, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(18, 2, 10, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(19, 1, 10, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(20, 2, 11, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(21, 1, 11, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(22, 2, 12, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(23, 1, 12, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(24, 2, 13, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(25, 1, 13, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(26, 2, 14, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(27, 1, 14, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(28, 2, 15, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(29, 1, 15, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(30, 2, 16, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(31, 1, 16, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(32, 2, 17, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(33, 1, 17, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(34, 2, 18, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(35, 1, 18, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(36, 2, 19, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(37, 1, 19, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(38, 2, 20, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(39, 1, 20, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(40, 2, 21, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(41, 1, 21, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(42, 2, 22, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(43, 1, 22, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(44, 2, 23, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(45, 1, 23, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(46, 2, 24, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(47, 1, 24, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(48, 2, 25, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(49, 1, 25, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(50, 2, 26, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(51, 1, 26, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(52, 2, 27, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(53, 1, 27, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(54, 2, 28, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(55, 1, 28, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(56, 2, 29, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(57, 1, 29, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(58, 2, 30, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(59, 1, 30, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(60, 2, 31, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(61, 1, 31, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(62, 2, 32, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(63, 1, 32, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(64, 2, 33, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(65, 1, 33, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(66, 2, 34, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21'),
(67, 1, 34, 1, '2026-09-09 14:14:21', '2026-09-09 14:14:21');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `evaluaciones_fisicas`
--

CREATE TABLE `evaluaciones_fisicas` (
  `id` bigint UNSIGNED NOT NULL,
  `nivel_experiencia` enum('1a3meses','4a8anos','4a8meses','1ano','mas1ano','2anos','3anosamas','3anos_mas') COLLATE utf8mb4_unicode_ci NOT NULL,
  `actividad_diaria` enum('sedentario','activo_ligero','moderadamente_activo','muy_activo') COLLATE utf8mb4_unicode_ci NOT NULL,
  `objetivo` enum('perdida_peso','ganancia_muscular','resistencia','recomposicion','aumento_fuerza','salud') COLLATE utf8mb4_unicode_ci NOT NULL,
  `edad` int NOT NULL,
  `peso` decimal(6,2) NOT NULL,
  `altura` decimal(5,2) NOT NULL,
  `porcentaje_grasa` decimal(5,2) NOT NULL,
  `masa_muscular` decimal(6,2) NOT NULL,
  `cintura` decimal(6,2) NOT NULL,
  `pecho` decimal(6,2) NOT NULL,
  `brazo` decimal(6,2) NOT NULL,
  `muslo` decimal(6,2) NOT NULL,
  `cadera` decimal(6,2) NOT NULL,
  `dias_semana` int NOT NULL,
  `eleccion_dias` text COLLATE utf8mb4_unicode_ci,
  `tiempo_sesion_min` int NOT NULL,
  `restricciones` enum('sin-restricciones','manco','cojo','paralitico','movilidad-reducida','amputacion-de-extremidad','silla-de-ruedas','uso-de-muletas','uso-de-baston','uso-de-andador','limitacion-de-brazos','limitacion-de-piernas','problemas-de-equilibrio','problemas-de-coordinacion','lesion-reciente','cirugia-reciente','dolor-musculoesqueletico','limitacion-cardiovascular','limitacion-respiratoria','discapacidad-visual','discapacidad-auditiva') COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_evaluacion` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `altura_unidad` enum('cm') COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `evaluaciones_fisicas`
--

INSERT INTO `evaluaciones_fisicas` (`id`, `nivel_experiencia`, `actividad_diaria`, `objetivo`, `edad`, `peso`, `altura`, `porcentaje_grasa`, `masa_muscular`, `cintura`, `pecho`, `brazo`, `muslo`, `cadera`, `dias_semana`, `eleccion_dias`, `tiempo_sesion_min`, `restricciones`, `fecha_evaluacion`, `created_at`, `updated_at`, `id_usuarios`, `altura_unidad`) VALUES
(1, '1ano', 'moderadamente_activo', 'resistencia', 28, 78.50, 1.76, 18.20, 34.00, 84.00, 98.00, 34.00, 58.00, 92.00, 4, '[\"Lunes\",\"Martes\",\"Jueves\",\"Viernes\"]', 50, 'sin-restricciones', '2026-09-02', '2026-09-07 23:16:09', '2026-09-07 23:16:09', 1, NULL),
(2, '1a3meses', 'activo_ligero', 'perdida_peso', 25, 66.20, 1.62, 26.00, 24.00, 78.00, 88.00, 27.00, 52.00, 96.00, 3, '[\"Lunes\",\"Martes\",\"Jueves\"]', 45, 'sin-restricciones', '2026-09-02', '2026-09-07 23:16:09', '2026-09-07 23:16:09', 2, NULL),
(3, '1ano', 'moderadamente_activo', 'resistencia', 28, 74.50, 165.00, 15.00, 45.00, 80.00, 110.00, 38.00, 50.00, 90.00, 4, '[\"Lunes\",\"Martes\",\"Jueves\",\"Viernes\"]', 50, 'sin-restricciones', '2026-09-10', '2026-09-10 10:00:29', '2026-09-10 10:00:29', 1, 'cm');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint UNSIGNED NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `grupos_musculares`
--

CREATE TABLE `grupos_musculares` (
  `id` bigint UNSIGNED NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `tipo` enum('pecho','espalda','hombros','biceps','triceps','cuadriceps','isquitiobiales','gluteos','pantorrillas','abdomen','antebrazos','trapecios','serratos','oblicuos','lumbares','aductores','abductores') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `grupos_musculares`
--

INSERT INTO `grupos_musculares` (`id`, `descripcion`, `estado`, `tipo`, `created_at`, `updated_at`) VALUES
(1, 'Pectoral', 1, 'pecho', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 'Pierna', 1, 'espalda', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(3, 'brazo', 1, 'cuadriceps', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(4, 'antebrazo', 1, 'abdomen', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(5, 'Trabajo principal de hombros y deltoides.', 1, 'hombros', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(6, 'Trabajo principal de biceps.', 1, 'biceps', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(7, 'Trabajo principal de triceps.', 1, 'triceps', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(8, 'Trabajo principal de isquiotibiales.', 1, 'isquitiobiales', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(9, 'Trabajo principal de gluteos.', 1, 'gluteos', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(10, 'Trabajo principal de pantorrillas.', 1, 'pantorrillas', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(11, 'Trabajo principal de antebrazos.', 1, 'antebrazos', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(12, 'Trabajo principal de trapecios.', 1, 'trapecios', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(13, 'Trabajo principal de serratos.', 1, 'serratos', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(14, 'Trabajo principal de oblicuos.', 1, 'oblicuos', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(15, 'Trabajo principal de lumbares.', 1, 'lumbares', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(16, 'Trabajo principal de aductores.', 1, 'aductores', '2026-09-09 14:14:20', '2026-09-09 14:14:20'),
(17, 'Trabajo principal de abductores.', 1, 'abductores', '2026-09-09 14:14:20', '2026-09-09 14:14:20');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_cambios`
--

CREATE TABLE `historial_cambios` (
  `id` bigint UNSIGNED NOT NULL,
  `id_empresas` bigint UNSIGNED NOT NULL,
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `tabla_afectada` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_registros` int NOT NULL,
  `accion` enum('crear','actualizar','eliminar','activar','desactivar') COLLATE utf8mb4_unicode_ci NOT NULL,
  `datos_anteriores` json NOT NULL,
  `datos_nuevos` json NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `historial_cambios`
--

INSERT INTO `historial_cambios` (`id`, `id_empresas`, `id_usuarios`, `tabla_afectada`, `id_registros`, `accion`, `datos_anteriores`, `datos_nuevos`, `descripcion`, `created_at`, `updated_at`) VALUES
(1, 1, 3, 'rutinas', 1, 'crear', '{}', '{\"nombre\": \"Rutina hipertrofia inicial\"}', 'Creacion de rutina inicial para usuario Diego.', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 1, 4, 'empresas', 1, 'actualizar', '{\"banner_1\": null}', '{\"banner_1\": \"banners/central-1.jpg\"}', 'Actualizacion de banner principal de empresa.', '2026-09-07 23:16:09', '2026-09-07 23:16:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint UNSIGNED NOT NULL,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` tinyint UNSIGNED NOT NULL,
  `reserved_at` int UNSIGNED DEFAULT NULL,
  `available_at` int UNSIGNED NOT NULL,
  `created_at` int UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `migrations`
--

CREATE TABLE `migrations` (
  `id` int UNSIGNED NOT NULL,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_08_21_224135_create_empresas', 1),
(5, '2026_08_21_224236_create_usuarios', 1),
(6, '2026_08_21_224244_create_evaluaciones_fisicas', 1),
(7, '2026_08_21_224253_create_grupos_musculares', 1),
(8, '2026_08_21_224303_create_ejercicios', 1),
(9, '2026_08_21_224329_create_ejercicios_grupo_muscular', 1),
(10, '2026_08_21_224335_create_rutinas', 1),
(11, '2026_08_21_224349_create_ejercicios_rutina', 1),
(12, '2026_08_21_224403_create_alimentos', 1),
(13, '2026_08_21_224411_create_planes_alimentacion', 1),
(14, '2026_08_21_224435_create_comidas', 1),
(15, '2026_08_21_224436_create_comida_alimentos', 1),
(16, '2026_08_21_224445_create_preferencias_alimentarias', 1),
(17, '2026_08_21_224451_create_progresos', 1),
(18, '2026_08_21_224459_create_sensaciones', 1),
(19, '2026_08_21_224509_create_historial_cambios', 1),
(20, '2026_08_21_224516_create_notificaciones', 1),
(21, '2026_08_21_224524_create_planes', 1),
(22, '2026_08_21_224533_create_suscripciones', 1),
(23, '2026_08_21_224540_create_pagos', 1),
(24, '2026_08_21_224547_create_banners', 1),
(25, '2026_08_29_170121_create_empresa_ejercicio_table', 1),
(26, '2026_09_02_230717_add_id_usuario_to_evaluaciones_fisicas_table', 1),
(27, '2026_09_09_120000_prepare_routine_generation', 2),
(28, '2026_09_11_120000_create_routine_generation_usage', 3),
(29, '2026_09_12_000001_add_altura_unidad_to_evaluaciones_fisicas', 4),
(30, '2026_09_12_000002_prepare_meal_plan_generation', 5),
(31, '2026_09_12_120000_make_alimentacion_review_optional', 6),
(32, '2026_09_12_130000_use_food_preferences_only', 7),
(33, '2026_09_21_180000_add_datos_to_notificaciones', 8);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notificaciones`
--

CREATE TABLE `notificaciones` (
  `id` bigint UNSIGNED NOT NULL,
  `id_empresas` bigint UNSIGNED DEFAULT NULL,
  `id_usuarios` bigint UNSIGNED DEFAULT NULL,
  `tipo` enum('recordatorio','rutina','alimentacion','suscripcion','sistema','otro') COLLATE utf8mb4_unicode_ci NOT NULL,
  `titulo` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mensaje` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_envio` datetime NOT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT '0',
  `enviada` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `datos` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `notificaciones`
--

INSERT INTO `notificaciones` (`id`, `id_empresas`, `id_usuarios`, `tipo`, `titulo`, `mensaje`, `fecha_envio`, `leida`, `enviada`, `created_at`, `updated_at`, `datos`) VALUES
(1, 1, 1, 'rutina', 'Rutina asignada', 'Ya tienes una rutina activa para esta semana.', '2026-09-05 09:00:00', 0, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(2, 1, 2, 'alimentacion', 'Plan de alimentacion listo', 'Tu plan de alimentacion inicial ya esta disponible.', '2026-09-05 09:30:00', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(3, 1, 1, 'sistema', 'Bienvenido a GYM-BROS', 'Gracias por usar la plataforma.', '2026-09-05 10:00:00', 0, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pagos`
--

CREATE TABLE `pagos` (
  `id` bigint UNSIGNED NOT NULL,
  `id_empresas` bigint UNSIGNED NOT NULL,
  `id_suscripciones` bigint UNSIGNED NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `moneda` varchar(3) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PEN',
  `metodo_pago` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `referencia` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` enum('pendiente','aprobado','rechazado','reembolsado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `fecha_pago` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `pagos`
--

INSERT INTO `pagos` (`id`, `id_empresas`, `id_suscripciones`, `monto`, `moneda`, `metodo_pago`, `referencia`, `estado`, `fecha_pago`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 199.00, 'PEN', 'tarjeta', 'PAY-GYMBROS-0001', 'aprobado', '2026-09-01 12:00:00', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 2, 2, 99.00, 'PEN', 'transferencia', 'PAY-GYMBROS-0002', 'aprobado', '2026-09-01 13:00:00', '2026-09-07 23:16:09', '2026-09-07 23:16:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles_alimentarios`
--

CREATE TABLE `perfiles_alimentarios` (
  `id` bigint UNSIGNED NOT NULL,
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `sexo_calculo` enum('masculino','femenino') COLLATE utf8mb4_unicode_ci NOT NULL,
  `embarazo` tinyint(1) NOT NULL,
  `lactancia` tinyint(1) NOT NULL,
  `requiere_plan_clinico` tinyint(1) NOT NULL,
  `apto_plan_general` tinyint(1) NOT NULL,
  `revision_profesional` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `revisado_en` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `perfiles_alimentarios`
--

INSERT INTO `perfiles_alimentarios` (`id`, `id_usuarios`, `sexo_calculo`, `embarazo`, `lactancia`, `requiere_plan_clinico`, `apto_plan_general`, `revision_profesional`, `revisado_en`, `created_at`, `updated_at`) VALUES
(2, 1, 'masculino', 0, 0, 0, 1, 'si', '2026-09-10', '2026-09-13 01:37:39', '2026-09-13 01:37:39');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planes`
--

CREATE TABLE `planes` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `precio_original` decimal(15,2) NOT NULL,
  `precio_inicial` decimal(15,2) NOT NULL,
  `duracion_dias` int NOT NULL,
  `limite_usuarios` int NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '0',
  `contenido` text COLLATE utf8mb4_unicode_ci,
  `enlace_whatsapp` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `planes`
--

INSERT INTO `planes` (`id`, `nombre`, `descripcion`, `precio_original`, `precio_inicial`, `duracion_dias`, `limite_usuarios`, `activo`, `contenido`, `enlace_whatsapp`, `created_at`, `updated_at`) VALUES
(1, 'Plan Basico', 'Plan inicial para gimnasios pequenos.', 149.00, 99.00, 45, 100, 1, 'Usuarios, rutinas, alimentacion y soporte basico.', 'https://wa.me/51999999999', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 'Plan Pro', 'Plan para gimnasios con mayor cantidad de usuarios.', 299.00, 199.00, 30, 500, 1, 'Usuarios ilimitados por sede, reportes y soporte prioritario.', 'https://wa.me/51999999999', '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(3, 'Plan de Prueba', 'Nuevo Plan para validar', 299.00, 249.00, 30, 50, 1, 'Añadir texto, ara la prueba de plan', 'https://chatgpt.com/', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planes_alimentacion`
--

CREATE TABLE `planes_alimentacion` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `objetivo` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `calorias_objetivo` decimal(6,2) NOT NULL,
  `proteinas_objetivo` decimal(6,2) NOT NULL,
  `carbohidratos_objetivo` decimal(6,2) NOT NULL,
  `grasas_objetivo` decimal(6,2) NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `id_evaluaciones_fisicas` bigint UNSIGNED DEFAULT NULL,
  `calculo` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `planes_alimentacion`
--

INSERT INTO `planes_alimentacion` (`id`, `nombre`, `descripcion`, `objetivo`, `calorias_objetivo`, `proteinas_objetivo`, `carbohidratos_objetivo`, `grasas_objetivo`, `fecha_inicio`, `fecha_fin`, `estado`, `id_usuarios`, `created_at`, `updated_at`, `id_evaluaciones_fisicas`, `calculo`) VALUES
(1, 'Plan volumen limpio', 'Plan base para aumento muscular controlado.', 'ganancia_muscular', 2600.00, 160.00, 320.00, 75.00, '2026-09-03', '2026-10-03', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL, NULL),
(2, 'Plan deficit inicial', 'Plan base para perdida de peso progresiva.', 'perdida_peso', 1800.00, 120.00, 180.00, 55.00, '2026-09-03', '2026-10-03', 1, 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL, NULL),
(5, 'Plan resistencia', 'Generacion por reglas 1.0-provisional.', 'resistencia', 2954.25, 147.71, 406.21, 82.06, '2026-09-12', '2026-09-18', 1, 1, '2026-09-13 03:10:03', '2026-09-13 03:10:03', 3, '{\"formula\": \"Mifflin-St Jeor simplificada\", \"peso_kg\": 74.5, \"version\": \"1.0-provisional\", \"altura_cm\": 165, \"objetivos\": {\"grasas\": 82.06, \"calorias\": 2954.25, \"proteinas\": 147.71, \"carbohidratos\": 406.21}, \"reposo_kcal\": 1641.25, \"revisado_en\": \"2026-09-10\", \"tolerancias\": {\"grasas\": 0.15, \"calorias\": 0.08, \"proteinas\": 0.15, \"carbohidratos\": 0.15}, \"distribucion\": {\"cena\": 0.3, \"almuerzo\": 0.4, \"desayuno\": 0.3}, \"edad_calculo\": 28, \"sexo_calculo\": \"masculino\", \"duracion_dias\": 7, \"ajuste_objetivo\": 0, \"cantidad_comidas\": 3, \"factor_actividad\": 1.8, \"revision_profesional\": \"si\"}'),
(6, 'Plan resistencia', 'Generacion por reglas 1.0-provisional.', 'resistencia', 2954.25, 147.71, 406.21, 82.06, '2026-09-14', '2026-09-20', 1, 1, '2026-09-13 03:21:34', '2026-09-13 03:21:34', 3, '{\"formula\": \"Mifflin-St Jeor simplificada\", \"peso_kg\": 74.5, \"version\": \"1.0-provisional\", \"altura_cm\": 165, \"objetivos\": {\"grasas\": 82.06, \"calorias\": 2954.25, \"proteinas\": 147.71, \"carbohidratos\": 406.21}, \"reposo_kcal\": 1641.25, \"revisado_en\": \"2026-09-10\", \"tolerancias\": {\"grasas\": 0.15, \"calorias\": 0.08, \"proteinas\": 0.15, \"carbohidratos\": 0.15}, \"distribucion\": {\"cena\": 0.3, \"almuerzo\": 0.4, \"desayuno\": 0.3}, \"edad_calculo\": 28, \"sexo_calculo\": \"masculino\", \"duracion_dias\": 7, \"ajuste_objetivo\": 0, \"cantidad_comidas\": 3, \"factor_actividad\": 1.8, \"revision_profesional\": \"si\"}');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `preferencias_alimentarias`
--

CREATE TABLE `preferencias_alimentarias` (
  `id` bigint UNSIGNED NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `id_alimentos` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `tipo` enum('preferido','rechazado') COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `preferencias_alimentarias`
--

INSERT INTO `preferencias_alimentarias` (`id`, `activo`, `id_usuarios`, `id_alimentos`, `created_at`, `updated_at`, `tipo`) VALUES
(1, 1, 1, 1, '2026-09-07 23:16:09', '2026-09-13 03:21:16', 'preferido'),
(2, 1, 1, 2, '2026-09-07 23:16:09', '2026-09-13 03:21:16', 'preferido'),
(3, 1, 2, 4, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(4, 1, 2, 5, '2026-09-07 23:16:09', '2026-09-07 23:16:09', NULL),
(8, 1, 1, 3, '2026-09-13 01:37:39', '2026-09-13 03:21:16', 'preferido'),
(9, 1, 1, 4, '2026-09-13 01:37:39', '2026-09-13 03:21:16', 'rechazado'),
(10, 1, 1, 5, '2026-09-13 01:37:39', '2026-09-13 03:21:16', 'rechazado'),
(11, 1, 1, 6, '2026-09-13 01:37:39', '2026-09-13 03:21:16', 'rechazado'),
(12, 1, 1, 7, '2026-09-13 01:37:39', '2026-09-13 03:21:16', 'preferido'),
(13, 1, 1, 8, '2026-09-13 01:37:39', '2026-09-13 03:21:17', 'preferido'),
(14, 1, 1, 9, '2026-09-13 01:37:39', '2026-09-13 03:21:17', 'preferido'),
(15, 1, 1, 10, '2026-09-13 01:37:39', '2026-09-13 03:21:17', 'preferido'),
(16, 1, 1, 18, '2026-09-13 01:37:39', '2026-09-13 03:21:17', 'rechazado'),
(17, 1, 1, 30, '2026-09-13 01:37:39', '2026-09-13 03:21:17', 'preferido'),
(18, 1, 1, 44, '2026-09-13 01:37:39', '2026-09-13 03:21:17', 'preferido'),
(19, 1, 1, 11, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(20, 1, 1, 12, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(21, 1, 1, 13, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(22, 1, 1, 14, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(23, 1, 1, 15, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(24, 1, 1, 16, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(25, 1, 1, 17, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'rechazado'),
(26, 1, 1, 19, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'rechazado'),
(27, 1, 1, 20, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(28, 1, 1, 21, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(29, 1, 1, 22, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(30, 1, 1, 23, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(31, 1, 1, 24, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(32, 1, 1, 25, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(33, 1, 1, 26, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(34, 1, 1, 27, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(35, 1, 1, 28, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(36, 1, 1, 29, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(37, 1, 1, 31, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(38, 1, 1, 32, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(39, 1, 1, 33, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(40, 1, 1, 34, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(41, 1, 1, 35, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(42, 1, 1, 37, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(43, 1, 1, 38, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(44, 1, 1, 39, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(45, 1, 1, 40, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(46, 1, 1, 41, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(47, 1, 1, 42, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(48, 1, 1, 43, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(49, 1, 1, 45, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(50, 1, 1, 46, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(51, 1, 1, 47, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(52, 1, 1, 48, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(53, 1, 1, 49, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(54, 1, 1, 50, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(55, 1, 1, 51, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(56, 1, 1, 52, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(57, 1, 1, 53, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido'),
(58, 1, 1, 54, '2026-09-13 02:31:12', '2026-09-13 03:21:17', 'preferido');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `progresos`
--

CREATE TABLE `progresos` (
  `id` bigint UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `peso` decimal(6,2) NOT NULL,
  `altura` decimal(5,2) NOT NULL,
  `porcentaje_grasa` decimal(5,2) NOT NULL,
  `masa_muscular` decimal(6,2) NOT NULL,
  `cintura` decimal(6,2) NOT NULL,
  `pecho` decimal(6,2) NOT NULL,
  `brazo` decimal(6,2) NOT NULL,
  `muslo` decimal(6,2) NOT NULL,
  `cadera` decimal(6,2) NOT NULL,
  `notas` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `progresos`
--

INSERT INTO `progresos` (`id`, `fecha`, `peso`, `altura`, `porcentaje_grasa`, `masa_muscular`, `cintura`, `pecho`, `brazo`, `muslo`, `cadera`, `notas`, `id_usuarios`, `created_at`, `updated_at`) VALUES
(1, '2026-09-04', 78.20, 1.76, 18.00, 34.20, 83.50, 98.50, 34.20, 58.20, 92.00, 'Primer registro posterior a evaluacion.', 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, '2026-09-04', 65.90, 1.62, 25.70, 24.10, 77.50, 88.00, 27.00, 52.00, 95.50, 'Inicio de seguimiento semanal.', 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `routine_generation_usage`
--

CREATE TABLE `routine_generation_usage` (
  `id` bigint UNSIGNED NOT NULL,
  `user_id` bigint UNSIGNED NOT NULL,
  `routine_id` bigint UNSIGNED NOT NULL,
  `evaluation_hash` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `routine_generation_usage`
--

INSERT INTO `routine_generation_usage` (`id`, `user_id`, `routine_id`, `evaluation_hash`, `created_at`) VALUES
(1, 1, 4, '92cdafefe6387ae630368046c8dfa774571af3f065412b1320af9f2f8966b7d3', '2026-09-11 10:16:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rutinas`
--

CREATE TABLE `rutinas` (
  `id` bigint UNSIGNED NOT NULL,
  `nombre` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `objetivo` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dias_semana` int NOT NULL,
  `duracion_estimada` int NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `rutinas`
--

INSERT INTO `rutinas` (`id`, `nombre`, `descripcion`, `objetivo`, `dias_semana`, `duracion_estimada`, `fecha_inicio`, `fecha_fin`, `estado`, `id_usuarios`, `created_at`, `updated_at`) VALUES
(1, 'Rutina hipertrofia ', 'Rutina base para ganar masa muscular con cuatro sesiones semanales.', 'ganancia_muscular', 4, 50, '2026-09-03', '2026-10-03', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, 'Rutina perdida de peso inicial', 'Rutina de acondicionamiento para tres dias semanales.', 'perdida_peso', 3, 45, '2026-09-03', '2026-10-03', 1, 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(3, 'Rutina ganancia_muscular', 'Generada por reglas v1. Evaluacion 1. Actividad: moderadamente_activo.', 'ganancia_muscular', 4, 39, '2026-09-14', '2026-10-11', 1, 1, '2026-09-09 20:47:03', '2026-09-09 20:47:03'),
(4, 'Rutina resistencia', 'Generada por reglas v1. Evaluacion 3. Actividad: moderadamente_activo.', 'resistencia', 4, 36, '2026-09-14', '2026-10-11', 1, 1, '2026-09-11 10:16:18', '2026-09-11 10:16:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sensaciones`
--

CREATE TABLE `sensaciones` (
  `id` bigint UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `energia` int NOT NULL,
  `dificultad` int NOT NULL,
  `fatiga` int NOT NULL,
  `dolor` int NOT NULL,
  `comentario` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_usuarios` bigint UNSIGNED NOT NULL,
  `id_rutinas` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sensaciones`
--

INSERT INTO `sensaciones` (`id`, `fecha`, `energia`, `dificultad`, `fatiga`, `dolor`, `comentario`, `id_usuarios`, `id_rutinas`, `created_at`, `updated_at`) VALUES
(1, '2026-09-05', 4, 3, 2, 1, 'Entrenamiento manejable y buena energia.', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(2, '2026-09-05', 3, 4, 3, 1, 'Sesion intensa pero completada.', 2, 2, '2026-09-07 23:16:09', '2026-09-07 23:16:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `suscripciones`
--

CREATE TABLE `suscripciones` (
  `id` bigint UNSIGNED NOT NULL,
  `id_empresas` bigint UNSIGNED NOT NULL,
  `id_planes` bigint UNSIGNED NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `estado` enum('pendiente','activa','vencida','cancelada','suspendida') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `renovacion_automatica` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `suscripciones`
--

INSERT INTO `suscripciones` (`id`, `id_empresas`, `id_planes`, `fecha_inicio`, `fecha_fin`, `estado`, `renovacion_automatica`, `created_at`, `updated_at`) VALUES
(1, 1, 2, '2026-09-02', '2026-09-30', 'activa', 1, '2026-09-07 23:16:09', '2026-09-15 23:54:44'),
(2, 2, 1, '2026-09-01', '2026-10-01', 'activa', 0, '2026-09-07 23:16:09', '2026-09-07 23:16:09'),
(9, 3, 1, '2026-08-12', '2026-09-19', 'activa', 0, '2026-08-05 18:52:32', '2026-09-05 18:52:41');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` bigint UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Administrador Laravel', 'admin@gymbros.test', '2026-09-07 23:16:09', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', NULL, '2026-09-07 23:16:09', '2026-09-07 23:16:09');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` bigint UNSIGNED NOT NULL,
  `nombres` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apellidos` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apodo` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `genero` enum('Varon','Mujer') COLLATE utf8mb4_unicode_ci NOT NULL,
  `correo` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo_documento` enum('DNI','PASAPORTE','OTRO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_documento` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telefono` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `direccion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `foto_perfil` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_registro` date NOT NULL,
  `fecha_nacimiento` date NOT NULL,
  `asistencia_semanal` datetime DEFAULT NULL,
  `tipo_usuario` enum('Administrador','Empresa','Entrenador','Usuario') COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `id_empresas` bigint UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `inicio_suscripcion` date DEFAULT NULL,
  `fin_suscripcion` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombres`, `apellidos`, `apodo`, `genero`, `correo`, `password_hash`, `tipo_documento`, `numero_documento`, `telefono`, `direccion`, `foto_perfil`, `fecha_registro`, `fecha_nacimiento`, `asistencia_semanal`, `tipo_usuario`, `estado`, `id_empresas`, `created_at`, `updated_at`, `inicio_suscripcion`, `fin_suscripcion`) VALUES
(1, 'Juanito', 'Perezz', 'Juancit', 'Varon', 'juan@gmail.com', '1234', 'PASAPORTE', '74581236', '987654321', 'Av. Los Olivos 100', 'C:\\laragon\\www\\gym-bros\\storage\\app\\public\\usuario\\B716Inh5DPVsTnONiQCFhzAZvITgKcBKV2mfoZSW.jpg', '2026-09-01', '1998-04-15', '2026-09-07 07:00:00', 'Administrador', 1, 1, '2026-09-07 23:16:09', '2026-09-17 19:08:06', '2026-09-02', '2026-09-30'),
(2, 'Lucia', 'Salazar', 'Lu', 'Mujer', 'lucia@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'DNI', '70889911', '976543210', 'Jr. Progreso 220', '\\storage\\app\\public\\usuario\\prueba-gym.png', '2026-09-01', '2001-02-20', '2026-09-07 18:00:00', 'Usuario', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', '2026-09-01', '2026-09-30'),
(3, 'Marco', 'Vargas', 'Coach Marco', 'Varon', 'marco@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'DNI', '70112233', '965432109', 'Av. Trainer 300', '\\storage\\app\\public\\usuario\\prueba-gym.png', '2026-09-01', '1990-07-10', NULL, 'Entrenador', 1, 1, '2026-09-07 23:16:09', '2026-09-07 23:16:09', '2026-09-01', '2026-09-30'),
(4, 'Admin', 'Empresa Central', 'Central Admin', 'Varon', 'empresa2@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'OTRO', '20601234567', '954321098', 'Av. Principal 123', '\\storage\\app\\public\\usuario\\prueba-gym.png', '2026-09-01', '1988-01-01', NULL, 'Empresa', 0, 3, '2026-09-07 23:16:09', '2026-09-17 04:22:49', '2026-09-01', '2026-09-30');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `alimentos`
--
ALTER TABLE `alimentos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`);

--
-- Indices de la tabla `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`);

--
-- Indices de la tabla `comidas`
--
ALTER TABLE `comidas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `plan_dia_orden_unique` (`id_planes_alimentacion`,`dia`,`orden`);

--
-- Indices de la tabla `comida_alimentos`
--
ALTER TABLE `comida_alimentos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `comida_alimentos_id_comidas_foreign` (`id_comidas`),
  ADD KEY `comida_alimentos_id_alimentos_foreign` (`id_alimentos`);

--
-- Indices de la tabla `ejercicios`
--
ALTER TABLE `ejercicios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ejercicios_id_grupos_musculares_foreign` (`id_grupos_musculares`);

--
-- Indices de la tabla `ejercicios_grupo_muscular`
--
ALTER TABLE `ejercicios_grupo_muscular`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ejercicios_grupo_muscular_id_ejercicios_foreign` (`id_ejercicios`),
  ADD KEY `ejercicios_grupo_muscular_id_grupos_musculares_foreign` (`id_grupos_musculares`);

--
-- Indices de la tabla `ejercicios_rutina`
--
ALTER TABLE `ejercicios_rutina`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ejercicios_rutina_id_rutinas_foreign` (`id_rutinas`),
  ADD KEY `ejercicios_rutina_id_ejercicios_foreign` (`id_ejercicios`);

--
-- Indices de la tabla `empresas`
--
ALTER TABLE `empresas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `empresa_ejercicio`
--
ALTER TABLE `empresa_ejercicio`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `empresa_ejercicio_id_empresas_id_ejercicios_unique` (`id_empresas`,`id_ejercicios`),
  ADD KEY `empresa_ejercicio_id_ejercicios_foreign` (`id_ejercicios`);

--
-- Indices de la tabla `evaluaciones_fisicas`
--
ALTER TABLE `evaluaciones_fisicas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `evaluaciones_fisicas_id_usuarios_foreign` (`id_usuarios`);

--
-- Indices de la tabla `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indices de la tabla `grupos_musculares`
--
ALTER TABLE `grupos_musculares`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `historial_cambios`
--
ALTER TABLE `historial_cambios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `historial_cambios_id_empresas_foreign` (`id_empresas`),
  ADD KEY `historial_cambios_id_usuarios_foreign` (`id_usuarios`);

--
-- Indices de la tabla `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indices de la tabla `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notificaciones_id_empresas_foreign` (`id_empresas`),
  ADD KEY `notificaciones_id_usuarios_foreign` (`id_usuarios`);

--
-- Indices de la tabla `pagos`
--
ALTER TABLE `pagos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pagos_id_empresas_foreign` (`id_empresas`),
  ADD KEY `pagos_id_suscripciones_foreign` (`id_suscripciones`);

--
-- Indices de la tabla `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indices de la tabla `perfiles_alimentarios`
--
ALTER TABLE `perfiles_alimentarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `perfiles_alimentarios_id_usuarios_unique` (`id_usuarios`);

--
-- Indices de la tabla `planes`
--
ALTER TABLE `planes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `planes_alimentacion`
--
ALTER TABLE `planes_alimentacion`
  ADD PRIMARY KEY (`id`),
  ADD KEY `planes_alimentacion_id_usuarios_foreign` (`id_usuarios`),
  ADD KEY `planes_alimentacion_id_evaluaciones_fisicas_foreign` (`id_evaluaciones_fisicas`);

--
-- Indices de la tabla `preferencias_alimentarias`
--
ALTER TABLE `preferencias_alimentarias`
  ADD PRIMARY KEY (`id`),
  ADD KEY `preferencias_alimentarias_id_usuarios_foreign` (`id_usuarios`),
  ADD KEY `preferencias_alimentarias_id_alimentos_foreign` (`id_alimentos`);

--
-- Indices de la tabla `progresos`
--
ALTER TABLE `progresos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `progresos_id_usuarios_foreign` (`id_usuarios`);

--
-- Indices de la tabla `routine_generation_usage`
--
ALTER TABLE `routine_generation_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `routine_generation_usage_user_id_index` (`user_id`);

--
-- Indices de la tabla `rutinas`
--
ALTER TABLE `rutinas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `rutinas_id_usuarios_foreign` (`id_usuarios`);

--
-- Indices de la tabla `sensaciones`
--
ALTER TABLE `sensaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sensaciones_id_usuarios_foreign` (`id_usuarios`),
  ADD KEY `sensaciones_id_rutinas_foreign` (`id_rutinas`);

--
-- Indices de la tabla `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indices de la tabla `suscripciones`
--
ALTER TABLE `suscripciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `suscripciones_id_empresas_foreign` (`id_empresas`),
  ADD KEY `suscripciones_id_planes_foreign` (`id_planes`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuarios_id_empresas_foreign` (`id_empresas`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `alimentos`
--
ALTER TABLE `alimentos`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT de la tabla `banners`
--
ALTER TABLE `banners`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `comidas`
--
ALTER TABLE `comidas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=89;

--
-- AUTO_INCREMENT de la tabla `comida_alimentos`
--
ALTER TABLE `comida_alimentos`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=344;

--
-- AUTO_INCREMENT de la tabla `ejercicios`
--
ALTER TABLE `ejercicios`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT de la tabla `ejercicios_grupo_muscular`
--
ALTER TABLE `ejercicios_grupo_muscular`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT de la tabla `ejercicios_rutina`
--
ALTER TABLE `ejercicios_rutina`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT de la tabla `empresas`
--
ALTER TABLE `empresas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `empresa_ejercicio`
--
ALTER TABLE `empresa_ejercicio`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

--
-- AUTO_INCREMENT de la tabla `evaluaciones_fisicas`
--
ALTER TABLE `evaluaciones_fisicas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `grupos_musculares`
--
ALTER TABLE `grupos_musculares`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `historial_cambios`
--
ALTER TABLE `historial_cambios`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `pagos`
--
ALTER TABLE `pagos`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `perfiles_alimentarios`
--
ALTER TABLE `perfiles_alimentarios`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `planes`
--
ALTER TABLE `planes`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `planes_alimentacion`
--
ALTER TABLE `planes_alimentacion`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `preferencias_alimentarias`
--
ALTER TABLE `preferencias_alimentarias`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT de la tabla `progresos`
--
ALTER TABLE `progresos`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `routine_generation_usage`
--
ALTER TABLE `routine_generation_usage`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `rutinas`
--
ALTER TABLE `rutinas`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `sensaciones`
--
ALTER TABLE `sensaciones`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `suscripciones`
--
ALTER TABLE `suscripciones`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `comidas`
--
ALTER TABLE `comidas`
  ADD CONSTRAINT `comidas_id_planes_alimentacion_foreign` FOREIGN KEY (`id_planes_alimentacion`) REFERENCES `planes_alimentacion` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `comida_alimentos`
--
ALTER TABLE `comida_alimentos`
  ADD CONSTRAINT `comida_alimentos_id_alimentos_foreign` FOREIGN KEY (`id_alimentos`) REFERENCES `alimentos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `comida_alimentos_id_comidas_foreign` FOREIGN KEY (`id_comidas`) REFERENCES `comidas` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `ejercicios`
--
ALTER TABLE `ejercicios`
  ADD CONSTRAINT `ejercicios_id_grupos_musculares_foreign` FOREIGN KEY (`id_grupos_musculares`) REFERENCES `grupos_musculares` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `ejercicios_grupo_muscular`
--
ALTER TABLE `ejercicios_grupo_muscular`
  ADD CONSTRAINT `ejercicios_grupo_muscular_id_ejercicios_foreign` FOREIGN KEY (`id_ejercicios`) REFERENCES `ejercicios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `ejercicios_grupo_muscular_id_grupos_musculares_foreign` FOREIGN KEY (`id_grupos_musculares`) REFERENCES `grupos_musculares` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `ejercicios_rutina`
--
ALTER TABLE `ejercicios_rutina`
  ADD CONSTRAINT `ejercicios_rutina_id_ejercicios_foreign` FOREIGN KEY (`id_ejercicios`) REFERENCES `ejercicios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `ejercicios_rutina_id_rutinas_foreign` FOREIGN KEY (`id_rutinas`) REFERENCES `rutinas` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `empresa_ejercicio`
--
ALTER TABLE `empresa_ejercicio`
  ADD CONSTRAINT `empresa_ejercicio_id_ejercicios_foreign` FOREIGN KEY (`id_ejercicios`) REFERENCES `ejercicios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `empresa_ejercicio_id_empresas_foreign` FOREIGN KEY (`id_empresas`) REFERENCES `empresas` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `evaluaciones_fisicas`
--
ALTER TABLE `evaluaciones_fisicas`
  ADD CONSTRAINT `evaluaciones_fisicas_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `historial_cambios`
--
ALTER TABLE `historial_cambios`
  ADD CONSTRAINT `historial_cambios_id_empresas_foreign` FOREIGN KEY (`id_empresas`) REFERENCES `empresas` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `historial_cambios_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE RESTRICT;

--
-- Filtros para la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD CONSTRAINT `notificaciones_id_empresas_foreign` FOREIGN KEY (`id_empresas`) REFERENCES `empresas` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `notificaciones_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL;

--
-- Filtros para la tabla `pagos`
--
ALTER TABLE `pagos`
  ADD CONSTRAINT `pagos_id_empresas_foreign` FOREIGN KEY (`id_empresas`) REFERENCES `empresas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `pagos_id_suscripciones_foreign` FOREIGN KEY (`id_suscripciones`) REFERENCES `suscripciones` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `perfiles_alimentarios`
--
ALTER TABLE `perfiles_alimentarios`
  ADD CONSTRAINT `perfiles_alimentarios_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `planes_alimentacion`
--
ALTER TABLE `planes_alimentacion`
  ADD CONSTRAINT `planes_alimentacion_id_evaluaciones_fisicas_foreign` FOREIGN KEY (`id_evaluaciones_fisicas`) REFERENCES `evaluaciones_fisicas` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `planes_alimentacion_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `preferencias_alimentarias`
--
ALTER TABLE `preferencias_alimentarias`
  ADD CONSTRAINT `preferencias_alimentarias_id_alimentos_foreign` FOREIGN KEY (`id_alimentos`) REFERENCES `alimentos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `preferencias_alimentarias_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `progresos`
--
ALTER TABLE `progresos`
  ADD CONSTRAINT `progresos_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `rutinas`
--
ALTER TABLE `rutinas`
  ADD CONSTRAINT `rutinas_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `sensaciones`
--
ALTER TABLE `sensaciones`
  ADD CONSTRAINT `sensaciones_id_rutinas_foreign` FOREIGN KEY (`id_rutinas`) REFERENCES `rutinas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `sensaciones_id_usuarios_foreign` FOREIGN KEY (`id_usuarios`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `suscripciones`
--
ALTER TABLE `suscripciones`
  ADD CONSTRAINT `suscripciones_id_empresas_foreign` FOREIGN KEY (`id_empresas`) REFERENCES `empresas` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `suscripciones_id_planes_foreign` FOREIGN KEY (`id_planes`) REFERENCES `planes` (`id`) ON DELETE RESTRICT;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_id_empresas_foreign` FOREIGN KEY (`id_empresas`) REFERENCES `empresas` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
