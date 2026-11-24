-- Eliminar tablas previas si existen (para recrear la estructura limpia)
DROP TABLE IF EXISTS historial_auditoria, activo_servicio, servicio, riesgo, sugerencia_ia, activo_politica, clausula, politica, activo, categoria_activo, usuario, rol CASCADE;

-- 1. Rol (EP-01)
CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- 2. Usuario (EP-01: Incluye soporte para 2FA)
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_rol INTEGER NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    rut VARCHAR(15) UNIQUE NOT NULL,
    correo VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    secret_2fa VARCHAR(255),               -- Clave secreta para 2FA / TOTP
    es_2fa_activo BOOLEAN DEFAULT FALSE,    -- Estado de la autenticación de doble factor
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id_rol)
);

-- 3. Catálogo de Categorías de Activos (EP-02)
CREATE TABLE categoria_activo (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- 4. Activo de Información (EP-02: Incluye Valoración CID, Asset Owner y Área)
CREATE TABLE activo (
    id_activo SERIAL PRIMARY KEY,
    id_categoria INT NOT NULL,
    id_propietario INT NOT NULL,            -- Asset Owner responsable del activo
    nombre VARCHAR(150) NOT NULL,
    area_organizativa VARCHAR(100) NOT NULL,
    descripcion TEXT,
    -- Valoración de Criticidad CID (Escala 1 a 5)
    nivel_confidencialidad INT CHECK (nivel_confidencialidad BETWEEN 1 AND 5),
    nivel_integridad INT CHECK (nivel_integridad BETWEEN 1 AND 5),
    nivel_disponibilidad INT CHECK (nivel_disponibilidad BETWEEN 1 AND 5),
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_activo_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES categoria_activo(id_categoria),
    CONSTRAINT fk_activo_propietario
        FOREIGN KEY (id_propietario)
        REFERENCES usuario(id_usuario)
);

-- 5. Política / Norma ISO (EP-03)
CREATE TABLE politica (
    id_politica SERIAL PRIMARY KEY,
    codigo_norma VARCHAR(50) NOT NULL,     -- Ej: ISO/IEC 27001:2022
    titulo_norma VARCHAR(200) NOT NULL,
    version VARCHAR(30),
    descripcion TEXT
);

-- 6. Cláusula / Control ISO (EP-03)
CREATE TABLE clausula (
    id_clausula SERIAL PRIMARY KEY,
    id_politica INT NOT NULL,
    codigo_clausula VARCHAR(50) NOT NULL,   -- Ej: A.5.15
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    CONSTRAINT fk_clausula_politica
        FOREIGN KEY (id_politica)
        REFERENCES politica(id_politica) ON DELETE CASCADE
);

-- 7. Evaluación del Activo según Norma (EP-03)
CREATE TABLE activo_politica (
    id_activo_politica SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    id_politica INT NOT NULL,
    cumplimiento BOOLEAN,                   -- True: Cumple, False: No cumple
    fecha_evaluacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ap_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE,
    CONSTRAINT fk_ap_politica
        FOREIGN KEY (id_politica)
        REFERENCES politica(id_politica) ON DELETE CASCADE
);

-- 8. Sugerencia de IA (EP-04)
CREATE TABLE sugerencia_ia (
    id_sugerencia SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    id_politica INT NOT NULL,
    recomendacion TEXT NOT NULL,
    nivel_criticidad VARCHAR(20),          -- Ej: Bajo, Medio, Alto, Crítico
    score_confianza DECIMAL(5,2),
    fecha_generacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ia_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE,
    CONSTRAINT fk_ia_politica
        FOREIGN KEY (id_politica)
        REFERENCES politica(id_politica) ON DELETE CASCADE
);

-- 9. Riesgos Asociados al Activo (EP-04)
CREATE TABLE riesgo (
    id_riesgo SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    descripcion TEXT NOT NULL,
    impacto VARCHAR(20),                    -- Ej: Bajo, Medio, Alto
    probabilidad VARCHAR(20),               -- Ej: Rara, Frecuente, Muy Frecuente
    nivel_riesgo VARCHAR(20),               -- Ponderación calculada del riesgo
    CONSTRAINT fk_riesgo_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE
);

-- 10. Servicio (EP-02)
CREATE TABLE servicio (
    id_servicio SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT
);

-- 11. Relación Activo - Servicio (M:N) (EP-02)
CREATE TABLE activo_servicio (
    id_activo INT NOT NULL,
    id_servicio INT NOT NULL,
    PRIMARY KEY (id_activo, id_servicio),
    CONSTRAINT fk_as_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE,
    CONSTRAINT fk_as_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES servicio(id_servicio) ON DELETE CASCADE
);

-- 12. Historial de Auditoría Criptográfica (Inmutabilidad con Hash SHA-256)
CREATE TABLE historial_auditoria (
    id_log SERIAL PRIMARY KEY,
    id_usuario INT,
    tabla_afectada VARCHAR(100) NOT NULL,
    registro_id INT,
    accion VARCHAR(50) NOT NULL,           -- INSERT, UPDATE, DELETE
    valor_anterior JSONB,
    valor_nuevo JSONB,
    hash_mod VARCHAR(512) NOT NULL,        -- Hash SHA-256 generado por el worker
    fecha_modificacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON DELETE SET NULL
);