\connect employee_example;
-- =========================================
-- EMPLOYEE / DEPARTMENT / PROJECT + JOB TITLE + TIMESHEET
-- PostgreSQL-ready: run in pgAdmin Query Tool
-- =========================================

-- Clean drop (safe order)
DROP TABLE IF EXISTS timesheet;
DROP TABLE IF EXISTS employee_project;
DROP TABLE IF EXISTS project;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS job_title;
DROP TABLE IF EXISTS department;

-- =====================
-- 1) TABLES (DDL)
-- =====================

CREATE TABLE department (
  department_id  SERIAL PRIMARY KEY,
  name           VARCHAR(80) NOT NULL UNIQUE,
  location       VARCHAR(80),
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Dimension table for titles (easy to teach joins + slowly changing data later)
CREATE TABLE job_title (
  job_title_id   SERIAL PRIMARY KEY,
  title          VARCHAR(120) NOT NULL UNIQUE,
  level          SMALLINT NOT NULL CHECK (level BETWEEN 1 AND 10),
  min_salary     NUMERIC(12,2) NOT NULL CHECK (min_salary >= 0),
  max_salary     NUMERIC(12,2) NOT NULL CHECK (max_salary >= min_salary)
);

CREATE TABLE employee (
  employee_id    SERIAL PRIMARY KEY,
  department_id  INT NOT NULL,
  job_title_id   INT NOT NULL,
  manager_id     INT NULL,

  first_name     VARCHAR(60) NOT NULL,
  last_name      VARCHAR(60) NOT NULL,
  email          VARCHAR(120) NOT NULL UNIQUE,

  salary         NUMERIC(12,2) NOT NULL CHECK (salary >= 0),
  hire_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,

  CONSTRAINT fk_employee_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

  CONSTRAINT fk_employee_job_title
    FOREIGN KEY (job_title_id)
    REFERENCES job_title(job_title_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

  CONSTRAINT fk_employee_manager
    FOREIGN KEY (manager_id)
    REFERENCES employee(employee_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

CREATE TABLE project (
  project_id     SERIAL PRIMARY KEY,
  department_id  INT NOT NULL,
  name           VARCHAR(120) NOT NULL UNIQUE,
  start_date     DATE NOT NULL,
  end_date       DATE NULL,
  budget         NUMERIC(14,2) NOT NULL CHECK (budget >= 0),

  CONSTRAINT fk_project_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

  CONSTRAINT chk_project_dates
    CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Bridge table: many-to-many employee <-> project
CREATE TABLE employee_project (
  employee_id    INT NOT NULL,
  project_id     INT NOT NULL,
  role           VARCHAR(80) NOT NULL,
  allocation_pct INT NOT NULL CHECK (allocation_pct BETWEEN 1 AND 100),
  assigned_at    TIMESTAMP NOT NULL DEFAULT NOW(),

  PRIMARY KEY (employee_id, project_id),

  CONSTRAINT fk_ep_employee
    FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_ep_project
    FOREIGN KEY (project_id)
    REFERENCES project(project_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Fact table: daily/weekly time logs against a project
CREATE TABLE timesheet (
  timesheet_id   BIGSERIAL PRIMARY KEY,
  employee_id    INT NOT NULL,
  project_id     INT NOT NULL,
  work_date      DATE NOT NULL,
  hours          NUMERIC(4,2) NOT NULL CHECK (hours > 0 AND hours <= 24),
  notes          TEXT,
  created_at     TIMESTAMP NOT NULL DEFAULT NOW(),

  -- prevents duplicate entry for same employee/project/day
  CONSTRAINT uq_timesheet_emp_proj_day UNIQUE (employee_id, project_id, work_date),

  CONSTRAINT fk_timesheet_employee
    FOREIGN KEY (employee_id)
    REFERENCES employee(employee_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_timesheet_project
    FOREIGN KEY (project_id)
    REFERENCES project(project_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  -- optional extra integrity: only allow logging time if employee is assigned to the project
  -- implemented via a composite FK to employee_project
  CONSTRAINT fk_timesheet_assignment
    FOREIGN KEY (employee_id, project_id)
    REFERENCES employee_project(employee_id, project_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

-- Helpful indexes
CREATE INDEX idx_employee_department   ON employee(department_id);
CREATE INDEX idx_employee_job_title    ON employee(job_title_id);
CREATE INDEX idx_employee_manager      ON employee(manager_id);

CREATE INDEX idx_project_department    ON project(department_id);

CREATE INDEX idx_ep_project            ON employee_project(project_id);

CREATE INDEX idx_timesheet_emp_date    ON timesheet(employee_id, work_date);
CREATE INDEX idx_timesheet_proj_date   ON timesheet(project_id, work_date);

-- =====================
-- 2) SAMPLE DATA (DML)
-- =====================

INSERT INTO department (name, location) VALUES
('Engineering', 'Dallas'),
('Analytics',   'Austin'),
('HR',          'Remote'),
('Sales',       'New York');

INSERT INTO job_title (title, level, min_salary, max_salary) VALUES
('Director of Engineering', 9, 160000, 220000),
('Senior Engineer',         7, 130000, 170000),
('Engineer',                5,  90000, 140000),
('Head of Analytics',       8, 150000, 210000),
('Data Scientist',          6, 120000, 170000),
('Data Analyst',            4,  75000, 110000),
('HR Manager',              6,  90000, 140000),
('Sales Director',          8, 140000, 210000),
('Account Executive',       5,  80000, 140000);

-- Employees (insert managers first so manager_id references exist)
INSERT INTO employee (department_id, job_title_id, manager_id, first_name, last_name, email, salary, hire_date)
VALUES
-- Engineering
((SELECT department_id FROM department WHERE name='Engineering'),
 (SELECT job_title_id  FROM job_title  WHERE title='Director of Engineering'),
 NULL, 'Ava', 'Patel', 'ava.patel@company.com', 180000, '2021-02-10'),

((SELECT department_id FROM department WHERE name='Engineering'),
 (SELECT job_title_id  FROM job_title  WHERE title='Senior Engineer'),
 1, 'Noah', 'Kim', 'noah.kim@company.com', 145000, '2022-04-12'),

((SELECT department_id FROM department WHERE name='Engineering'),
 (SELECT job_title_id  FROM job_title  WHERE title='Engineer'),
 1, 'Mia', 'Singh', 'mia.singh@company.com', 120000, '2023-01-09'),

-- Analytics
((SELECT department_id FROM department WHERE name='Analytics'),
 (SELECT job_title_id  FROM job_title  WHERE title='Head of Analytics'),
 NULL, 'Liam', 'Chen', 'liam.chen@company.com', 170000, '2020-08-01'),

((SELECT department_id FROM department WHERE name='Analytics'),
 (SELECT job_title_id  FROM job_title  WHERE title='Data Analyst'),
 4, 'Sophia', 'Garcia', 'sophia.garcia@company.com', 95000, '2023-06-15'),

((SELECT department_id FROM department WHERE name='Analytics'),
 (SELECT job_title_id  FROM job_title  WHERE title='Data Scientist'),
 4, 'Ethan', 'Jones', 'ethan.jones@company.com', 135000, '2022-11-30'),

-- HR
((SELECT department_id FROM department WHERE name='HR'),
 (SELECT job_title_id  FROM job_title  WHERE title='HR Manager'),
 NULL, 'Olivia', 'Brown', 'olivia.brown@company.com', 110000, '2021-09-20'),

-- Sales
((SELECT department_id FROM department WHERE name='Sales'),
 (SELECT job_title_id  FROM job_title  WHERE title='Sales Director'),
 NULL, 'Lucas', 'Wilson', 'lucas.wilson@company.com', 160000, '2020-03-05'),

((SELECT department_id FROM department WHERE name='Sales'),
 (SELECT job_title_id  FROM job_title  WHERE title='Account Executive'),
 8, 'Emma', 'Davis', 'emma.davis@company.com', 105000, '2023-03-27');

-- Projects
INSERT INTO project (department_id, name, start_date, end_date, budget) VALUES
((SELECT department_id FROM department WHERE name='Engineering'), 'Website Revamp', '2024-01-15', NULL,        250000),
((SELECT department_id FROM department WHERE name='Analytics'),   'Churn Modeling', '2024-02-01', NULL,        150000),
((SELECT department_id FROM department WHERE name='Engineering'), 'Mobile App v2',  '2024-03-10', '2024-10-31',400000),
((SELECT department_id FROM department WHERE name='Sales'),       'CRM Cleanup',    '2024-04-05', '2024-07-20', 80000);

-- Assignments (bridge)
INSERT INTO employee_project (employee_id, project_id, role, allocation_pct) VALUES
(1, 1, 'Executive Sponsor', 10),
(2, 1, 'Tech Lead',         60),
(3, 1, 'Backend Engineer',  70),

(4, 2, 'Executive Sponsor', 10),
(6, 2, 'Model Owner',       70),
(5, 2, 'Analyst',           60),

(2, 3, 'API Lead',          40),
(3, 3, 'Feature Dev',       50),

(8, 4, 'Executive Sponsor', 10),
(9, 4, 'Sales Ops',         70);

-- Timesheet logs (note: must match an existing employee_project assignment)
INSERT INTO timesheet (employee_id, project_id, work_date, hours, notes) VALUES
-- Website Revamp
(2, 1, '2024-06-03', 6.00, 'Architecture + PR reviews'),
(3, 1, '2024-06-03', 7.50, 'API endpoints + unit tests'),
(2, 1, '2024-06-04', 5.00, 'Sprint planning + refactor'),
(3, 1, '2024-06-04', 8.00, 'Bug fixes + integration'),

-- Churn Modeling
(6, 2, '2024-06-03', 6.50, 'Feature engineering'),
(5, 2, '2024-06-03', 5.00, 'Data pull + QA checks'),
(6, 2, '2024-06-04', 7.00, 'Model training + evaluation'),
(5, 2, '2024-06-04', 4.50, 'Dashboard draft'),

-- Mobile App v2
(2, 3, '2024-06-05', 4.00, 'API contract updates'),
(3, 3, '2024-06-05', 6.00, 'Feature implementation'),

-- CRM Cleanup
(9, 4, '2024-06-06', 7.00, 'Account mapping + dedupe rules');

-- =====================
-- 3) DEMO QUERIES (JOIN PRACTICE)
-- =====================

-- A) Employee roster with dept + title + manager
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS employee,
  d.name AS department,
  jt.title AS job_title,
  COALESCE(m.first_name || ' ' || m.last_name, '—') AS manager,
  e.salary,
  e.hire_date
FROM employee e
JOIN department d ON d.department_id = e.department_id
JOIN job_title jt ON jt.job_title_id = e.job_title_id
LEFT JOIN employee m ON m.employee_id = e.manager_id
ORDER BY d.name, e.employee_id;

-- B) Show salary vs title range (good for CASE + comparisons)
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS employee,
  jt.title,
  e.salary,
  jt.min_salary,
  jt.max_salary,
  CASE
    WHEN e.salary < jt.min_salary THEN 'Below range'
    WHEN e.salary > jt.max_salary THEN 'Above range'
    ELSE 'In range'
  END AS salary_position
FROM employee e
JOIN job_title jt ON jt.job_title_id = e.job_title_id
ORDER BY jt.level DESC, e.salary DESC;

-- C) Hours by employee and project (GROUP BY)
SELECT
  e.first_name || ' ' || e.last_name AS employee,
  p.name AS project,
  SUM(t.hours) AS total_hours
FROM timesheet t
JOIN employee e ON e.employee_id = t.employee_id
JOIN project p  ON p.project_id  = t.project_id
GROUP BY employee, project
ORDER BY total_hours DESC;

-- D) Weekly hours per employee (DATE_TRUNC demo)
SELECT
  e.first_name || ' ' || e.last_name AS employee,
  DATE_TRUNC('week', t.work_date)::date AS week_start,
  SUM(t.hours) AS hours_in_week
FROM timesheet t
JOIN employee e ON e.employee_id = t.employee_id
GROUP BY employee, week_start
ORDER BY week_start, employee;

-- E) Find employees with NO timesheets (LEFT JOIN + NULL filter)
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS employee,
  d.name AS department,
  jt.title AS job_title
FROM employee e
JOIN department d ON d.department_id = e.department_id
JOIN job_title jt ON jt.job_title_id = e.job_title_id
LEFT JOIN timesheet t ON t.employee_id = e.employee_id
WHERE t.employee_id IS NULL
ORDER BY e.employee_id;