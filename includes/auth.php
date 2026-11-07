<?php
/**
 * includes/auth.php
 * Secure session bootstrap + authentication / authorization guards.
 * Include FIRST on every page (header.php does this for you).
 */
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/functions.php';

if (session_status() === PHP_SESSION_NONE) {
    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => '/',
        'httponly' => true,          // JS cannot read the session cookie
        'samesite' => 'Lax',         // basic CSRF mitigation
        'secure'   => !empty($_SERVER['HTTPS']),
    ]);
    session_start();
}

function is_logged_in(): bool { return !empty($_SESSION['user_id']); }
function is_admin(): bool     { return is_logged_in() && ($_SESSION['role'] ?? '') === 'admin'; }

/** Log a user in and regenerate the session ID (prevents session fixation). */
function login_user(mysqli $conn, array $user): void
{
    session_regenerate_id(true);
    $_SESSION['user_id'] = (int)$user['id'];
    $_SESSION['name']    = $user['name'];
    $_SESSION['role']    = $user['role'];
    csrf_token();

    $stmt = $conn->prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?');
    $stmt->bind_param('i', $user['id']);
    $stmt->execute();
}

function logout_user(): void
{
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
}

/** Guard for customer pages. */
function require_login(): void
{
    if (!is_logged_in()) {
        $_SESSION['redirect_after_login'] = $_SERVER['REQUEST_URI'] ?? '';
        flash('warning', 'Please log in to continue.');
        redirect('auth/login.php');
    }
}

/** Guard for admin pages: re-checks role + active status in the DB on every request. */
function require_admin(mysqli $conn): void
{
    if (!is_logged_in()) {
        flash('warning', 'Please log in.');
        redirect('auth/login.php');
    }
    $stmt = $conn->prepare("SELECT role, status FROM users WHERE id = ?");
    $stmt->bind_param('i', $_SESSION['user_id']);
    $stmt->execute();
    $u = $stmt->get_result()->fetch_assoc();
    if (!$u || $u['role'] !== 'admin' || $u['status'] !== 'active') {
        http_response_code(403);
        exit('403 Forbidden: administrators only.');
    }
}
