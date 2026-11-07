-- ============================================================
--  Online Bookstore  |  database.sql
--  Import via phpMyAdmin > Import  (MySQL 5.7+ / MariaDB 10.3+)
--  Default admin:  admin@bookstore.local  /  Admin@123
--  CHANGE THIS PASSWORD after first login.
-- ============================================================
CREATE DATABASE IF NOT EXISTS online_bookstore
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE online_bookstore;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS order_items, orders, cart_items, cart, books, categories, users;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. USERS ---------------------------------------------------
CREATE TABLE users (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name                VARCHAR(100)  NOT NULL,
  email               VARCHAR(150)  NOT NULL,
  password_hash       VARCHAR(255)  NOT NULL,
  phone               VARCHAR(20)   NULL,
  profile_image       VARCHAR(255)  NULL,
  role                ENUM('user','admin') NOT NULL DEFAULT 'user',
  status              ENUM('active','blocked') NOT NULL DEFAULT 'active',
  last_login_at       DATETIME      NULL,
  reset_token_hash    CHAR(64)      NULL,
  reset_token_expires DATETIME      NULL,
  created_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_name (name),
  KEY idx_users_role (role),
  KEY idx_users_last_login (last_login_at)
) ENGINE=InnoDB;

-- 2. CATEGORIES ----------------------------------------------
CREATE TABLE categories (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(80)  NOT NULL,
  slug        VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  icon        VARCHAR(50)  NULL COMMENT 'Bootstrap Icons class, e.g. bi-rocket',
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_categories_name (name),
  UNIQUE KEY uq_categories_slug (slug)
) ENGINE=InnoDB;

-- 3. BOOKS ---------------------------------------------------
CREATE TABLE books (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id INT UNSIGNED NOT NULL,
  title       VARCHAR(200) NOT NULL,
  author      VARCHAR(150) NOT NULL,
  description TEXT         NULL,
  price       DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  stock       INT UNSIGNED NOT NULL DEFAULT 0,
  cover_image VARCHAR(255) NULL,
  is_featured TINYINT(1)   NOT NULL DEFAULT 0,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_books_category FOREIGN KEY (category_id)
    REFERENCES categories(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_books_title (title),
  KEY idx_books_author (author),
  KEY idx_books_price (price),
  KEY idx_books_category (category_id),
  KEY idx_books_featured (is_featured),
  KEY idx_books_created (created_at)
) ENGINE=InnoDB;

-- 4. CART (one per user) -------------------------------------
CREATE TABLE cart (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cart_user (user_id),
  CONSTRAINT fk_cart_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. CART ITEMS ----------------------------------------------
CREATE TABLE cart_items (
  id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cart_id  INT UNSIGNED NOT NULL,
  book_id  INT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cart_book (cart_id, book_id),
  CONSTRAINT fk_ci_cart FOREIGN KEY (cart_id) REFERENCES cart(id)  ON DELETE CASCADE,
  CONSTRAINT fk_ci_book FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. ORDERS --------------------------------------------------
-- Shipping fields are a snapshot at order time (not derived from users),
-- so they legitimately belong to the order (3NF-compliant).
CREATE TABLE orders (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number     VARCHAR(30)  NOT NULL,
  user_id          INT UNSIGNED NOT NULL,
  total_amount     DECIMAL(10,2) NOT NULL,
  status           ENUM('Pending','Processing','Shipped','Delivered','Cancelled') NOT NULL DEFAULT 'Pending',
  payment_method   VARCHAR(30)  NOT NULL DEFAULT 'Cash on Delivery (Simulated)',
  shipping_name    VARCHAR(100) NOT NULL,
  shipping_phone   VARCHAR(20)  NOT NULL,
  shipping_address VARCHAR(255) NOT NULL,
  shipping_city    VARCHAR(80)  NOT NULL,
  shipping_postal  VARCHAR(15)  NOT NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_orders_number (order_number),
  KEY idx_orders_user (user_id),
  KEY idx_orders_status (status),
  KEY idx_orders_created (created_at),
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 7. ORDER ITEMS ---------------------------------------------
-- unit_price and book_title are historical snapshots: prices/titles may
-- change later, but past orders must stay accurate.
CREATE TABLE order_items (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id   INT UNSIGNED NOT NULL,
  book_id    INT UNSIGNED NULL,
  book_title VARCHAR(200) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  quantity   INT UNSIGNED NOT NULL,
  KEY idx_oi_order (order_id),
  KEY idx_oi_book (book_id),
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_oi_book  FOREIGN KEY (book_id)  REFERENCES books(id)  ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
--  SAMPLE DATA
-- ============================================================
INSERT INTO users (name, email, password_hash, phone, role) VALUES
('Store Admin', 'admin@bookstore.local', '$2y$10$AZAjqNvdl4N2jrvHAqEXW.1//NuBn.tZptM7LHs.xROS7QHuEj77a', '9000000000', 'admin');

INSERT INTO categories (name, slug, description, icon) VALUES
('Fiction',          'fiction',          'Novels and storytelling',           'bi-book'),
('Science Fiction',  'science-fiction',  'Futures, space and technology',     'bi-rocket-takeoff'),
('Technology',       'technology',       'Programming and computer science',  'bi-cpu'),
('Business',         'business',         'Management, startups and finance',  'bi-briefcase'),
('Self-Help',        'self-help',        'Habits, growth and mindset',        'bi-lightbulb'),
('History',          'history',          'People, nations and events',        'bi-bank');

INSERT INTO books (category_id, title, author, description, price, stock, is_featured, created_at) VALUES
(1, 'Pride and Prejudice',          'Jane Austen',        'A witty classic of manners, marriage and misjudgment in Regency England.', 349.00, 40, 1, NOW() - INTERVAL 30 DAY),
(1, 'To Kill a Mockingbird',        'Harper Lee',         'A young girl watches her father defend an innocent man in the American South.', 399.00, 35, 1, NOW() - INTERVAL 25 DAY),
(1, 'The Great Gatsby',             'F. Scott Fitzgerald','Jazz Age excess, longing and the cost of reinvention.', 299.00, 50, 0, NOW() - INTERVAL 20 DAY),
(2, 'Dune',                         'Frank Herbert',      'Politics, religion and ecology collide on the desert planet Arrakis.', 499.00, 30, 1, NOW() - INTERVAL 15 DAY),
(2, '1984',                         'George Orwell',      'A chilling vision of surveillance and totalitarian control.', 329.00, 45, 1, NOW() - INTERVAL 12 DAY),
(2, 'The Martian',                  'Andy Weir',          'An astronaut stranded on Mars must science his way home.', 429.00, 25, 0, NOW() - INTERVAL 8 DAY),
(3, 'Clean Code',                   'Robert C. Martin',   'A handbook of agile software craftsmanship.', 899.00, 20, 1, NOW() - INTERVAL 6 DAY),
(3, 'The Pragmatic Programmer',     'Andrew Hunt, David Thomas', 'Practical advice for becoming a better developer.', 849.00, 18, 0, NOW() - INTERVAL 4 DAY),
(4, 'The Lean Startup',             'Eric Ries',          'Build, measure, learn: a scientific approach to new ventures.', 559.00, 22, 0, NOW() - INTERVAL 3 DAY),
(5, 'Atomic Habits',                'James Clear',        'Small changes, remarkable results: a proven framework for habits.', 499.00, 60, 1, NOW() - INTERVAL 2 DAY),
(5, 'Deep Work',                    'Cal Newport',        'Rules for focused success in a distracted world.', 449.00, 28, 0, NOW() - INTERVAL 1 DAY),
(6, 'Sapiens',                      'Yuval Noah Harari',  'A brief history of humankind from the Stone Age to today.', 599.00, 33, 1, NOW());
