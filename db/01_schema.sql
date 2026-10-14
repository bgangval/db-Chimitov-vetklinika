CREATE TABLE owners (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    phone text NOT NULL UNIQUE,
    email text UNIQUE,
    address text NOT NULL
);

CREATE TABLE pets (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id integer NOT NULL REFERENCES owners(id) ON DELETE RESTRICT,
    name text NOT NULL,
    species text NOT NULL,
    breed text,
    birth_date date,
    microchip_number text UNIQUE,
    notes text,
    CHECK (birth_date IS NULL OR birth_date <= CURRENT_DATE)
);

CREATE TABLE doctors (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL,
    specialization text NOT NULL,
    phone text NOT NULL UNIQUE,
    email text UNIQUE,
    experience_years integer NOT NULL DEFAULT 0,
    CHECK (experience_years >= 0)
);

CREATE TABLE visits (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_id integer NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    doctor_id integer NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    visit_date timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason text NOT NULL,
    diagnosis text,
    notes text,
    CHECK (length(trim(reason)) > 0)
);

CREATE TABLE procedures (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    price numeric(10, 2) NOT NULL,
    duration_minutes integer NOT NULL,
    is_vaccination boolean NOT NULL DEFAULT false,
    CHECK (price >= 0),
    CHECK (duration_minutes > 0)
);

CREATE TABLE visit_procedures (
    visit_id integer NOT NULL
        REFERENCES visits(id) ON DELETE RESTRICT,
    procedure_id integer NOT NULL
        REFERENCES procedures(id) ON DELETE RESTRICT,
    quantity integer NOT NULL DEFAULT 1,
    actual_price numeric(10, 2) NOT NULL,
    notes text,
    PRIMARY KEY (visit_id, procedure_id),
    CHECK (quantity > 0),
    CHECK (actual_price >= 0)
);
