<?php
/**
 * config/database.php
 * Creates the shared MySQLi connection ($conn) using prepared statements elsewhere.
 * XAMPP defaults: user "root", empty password. Override in config/database.local.php
 * (git-ignored) so credentials never reach GitHub.
 */
if (is_file(__DIR__ . '/database.local.php')) {
    require __DIR__ . '/database.local.php';
}
defined('DB_HOST') || define('DB_HOST', 'localhost');
defined('DB_USER') || define('DB_USER', 'root');
defined('DB_PASS') || define('DB_PASS', '');
defined('DB_NAME') || define('DB_NAME', 'online_bookstore');

// BASE_URL: folder name in htdocs. Change if you rename the project folder.
defined('BASE_URL') || define('BASE_URL', '/online-bookstore');

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT); // throw exceptions

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    $conn->set_charset('utf8mb4');
} catch (mysqli_sql_exception $e) {
    error_log('DB connection failed: ' . $e->getMessage()); // log, never show details
    http_response_code(500);
    exit('Service temporarily unavailable. Please try again later.');
}
