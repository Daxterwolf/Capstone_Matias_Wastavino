-- 1. Rol
CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- 2. Usuario
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    id_rol INTEGER NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    rut VARCHAR(15) UNIQUE NOT NULL,
    correo VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id_rol)
);

-- 3. Activo (Agregada para resolver referencias de FK)
CREATE TABLE activo (
    id_activo SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Categoria Activo
CREATE TABLE categoria_activo (
    id_categoria SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    descripcion TEXT,
    CONSTRAINT fk_categoria_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE
);

-- 5. Politica
CREATE TABLE politica (
    id_politica SERIAL PRIMARY KEY,
    codigo_norma VARCHAR(50) NOT NULL,
    titulo_norma VARCHAR(200) NOT NULL,
    version VARCHAR(30),
    descripcion TEXT
);

-- 6. Clausula
CREATE TABLE clausula (
    id_clausula SERIAL PRIMARY KEY,
    id_politica INT NOT NULL,
    codigo_clausula VARCHAR(50),
    titulo VARCHAR(200),
    descripcion TEXT,
    CONSTRAINT fk_clausula_politica
        FOREIGN KEY (id_politica)
        REFERENCES politica(id_politica) ON DELETE CASCADE
);

-- 7. Activo Politica
CREATE TABLE activo_politica (
    id_activo_politica SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    id_politica INT NOT NULL,
    cumplimiento BOOLEAN,
    fecha_evaluacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ap_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE,
    CONSTRAINT fk_ap_politica
        FOREIGN KEY (id_politica)
        REFERENCES politica(id_politica) ON DELETE CASCADE
);

-- 8. Evidencia
CREATE TABLE evidencia (
    id_evidencia SERIAL PRIMARY KEY,
    id_activo_politica INT NOT NULL,
    subido_por INT NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    url_blob TEXT NOT NULL,
    hash VARCHAR(512),
    tamano_bytes BIGINT,
    fecha_subida TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evidencia_activo_politica
        FOREIGN KEY (id_activo_politica)
        REFERENCES activo_politica(id_activo_politica) ON DELETE CASCADE,
    CONSTRAINT fk_evidencia_usuario
        FOREIGN KEY (subido_por)
        REFERENCES usuario(id_usuario)
);

-- 9. Sugerencia IA
CREATE TABLE sugerencia_ia (
    id_sugerencia SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    id_politica INT NOT NULL,
    recomendacion TEXT NOT NULL,
    nivel_criticidad VARCHAR(20),
    score_confianza DECIMAL(5,2),
    fecha_generacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ia_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE,
    CONSTRAINT fk_ia_politica
        FOREIGN KEY (id_politica)
        REFERENCES politica(id_politica) ON DELETE CASCADE
);

-- 10. Riesgo
CREATE TABLE riesgo (
    id_riesgo SERIAL PRIMARY KEY,
    id_activo INT NOT NULL,
    descripcion TEXT NOT NULL,
    impacto VARCHAR(20),
    probabilidad VARCHAR(20),
    nivel_riesgo VARCHAR(20),
    CONSTRAINT fk_riesgo_activo
        FOREIGN KEY (id_activo)
        REFERENCES activo(id_activo) ON DELETE CASCADE
);

-- 11. Servicio
CREATE TABLE servicio (
    id_servicio SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT
);

-- 12. Activo Servicio (Tabla intermedia M:N)
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

-- 13. Historial Auditoria
CREATE TABLE historial_auditoria (
    id_log SERIAL PRIMARY KEY,
    id_usuario INT,
    tabla_afectada VARCHAR(100) NOT NULL,
    registro_id INT,
    accion VARCHAR(50) NOT NULL,
    valor_anterior JSONB,
    valor_nuevo JSONB,
    hash_mod VARCHAR(512),
    fecha_modificacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario(id_usuario) ON DELETE SET NULL
);