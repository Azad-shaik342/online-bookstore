<?php
/**
 * includes/functions.php
 * Reusable helpers: escaping, redirects, flash messages, CSRF, validation,
 * secure uploads, money formatting, pagination.
 */

/** Escape output (XSS protection). Use on EVERY value printed into HTML. */
function e(?string $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function url(string $path = ''): string
{
    return BASE_URL . '/' . ltrim($path, '/');
}

function redirect(string $path): never
{
    header('Location: ' . (str_starts_with($path, 'http') ? $path : url($path)));
    exit;
}

function money(float|string $amount): string
{
    return '₹' . number_format((float)$amount, 2);
}

/* ---------- Flash messages ---------- */
function flash(string $type, string $message): void
{
    $_SESSION['flash'][] = ['type' => $type, 'message' => $message];
}

function render_flash(): void
{
    if (empty($_SESSION['flash'])) return;
    foreach ($_SESSION['flash'] as $f) {
        $cls = $f['type'] === 'error' ? 'danger' : e($f['type']);
        echo '<div class="alert alert-' . $cls . ' alert-dismissible fade show" role="alert">'
           . e($f['message'])
           . '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
    }
    unset($_SESSION['flash']);
}

/* ---------- CSRF ---------- */
function csrf_token(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrf_token()) . '">';
}

/** Call at the top of every POST handler. Aborts with 403 on mismatch. */
function verify_csrf(): void
{
    $sent = $_POST['csrf_token'] ?? '';
    if (!is_string($sent) || !hash_equals($_SESSION['csrf_token'] ?? '', $sent)) {
        http_response_code(403);
        exit('Invalid or expired form token. Go back, refresh the page and try again.');
    }
}

/* ---------- Validation ---------- */
function clean(string $v): string
{
    return trim(preg_replace('/\s+/', ' ', $v));
}

function valid_email(string $v): bool
{
    return (bool)filter_var($v, FILTER_VALIDATE_EMAIL) && strlen($v) <= 150;
}

function valid_phone(string $v): bool
{
    return (bool)preg_match('/^[0-9+\-\s]{7,20}$/', $v);
}

/** Min 8 chars, with letter and digit. Returns error string or null. */
function password_error(string $pw): ?string
{
    if (strlen($pw) < 8)                 return 'Password must be at least 8 characters.';
    if (!preg_match('/[A-Za-z]/', $pw))  return 'Password must contain a letter.';
    if (!preg_match('/\d/', $pw))        return 'Password must contain a number.';
    return null;
}

/* ---------- Secure image upload ---------- */
/**
 * Validates and stores an uploaded image.
 * - size limit, real MIME check via finfo (not the client-supplied type),
 *   getimagesize() sanity check, random server-generated filename.
 * @return array [filename|null, error|null]
 */
function upload_image(array $file, string $subdir, int $maxBytes = 2097152): array
{
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) return [null, null];
    if ($file['error'] !== UPLOAD_ERR_OK)       return [null, 'Upload failed. Please try again.'];
    if ($file['size'] > $maxBytes)              return [null, 'Image must be under ' . ($maxBytes / 1048576) . ' MB.'];

    $allowed = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    if (!isset($allowed[$mime]) || @getimagesize($file['tmp_name']) === false) {
        return [null, 'Only JPG, PNG or WEBP images are allowed.'];
    }

    $dir = __DIR__ . '/../uploads/' . $subdir . '/';
    $name = bin2hex(random_bytes(16)) . '.' . $allowed[$mime];
    if (!move_uploaded_file($file['tmp_name'], $dir . $name)) {
        return [null, 'Could not save the image.'];
    }
    return [$name, null];
}

function delete_upload(?string $filename, string $subdir): void
{
    if ($filename && preg_match('/^[a-f0-9]{32}\.(jpg|png|webp)$/', $filename)) {
        $path = __DIR__ . '/../uploads/' . $subdir . '/' . $filename;
        if (is_file($path)) @unlink($path);
    }
}

function book_cover(?string $file): string
{
    return $file ? url('uploads/books/' . $file) : url('assets/images/book-placeholder.svg');
}

/* ---------- Pagination ---------- */
function paginate(int $total, int $perPage, int $page): array
{
    $pages = max(1, (int)ceil($total / $perPage));
    $page  = min(max(1, $page), $pages);
    return ['page' => $page, 'pages' => $pages, 'offset' => ($page - 1) * $perPage, 'perPage' => $perPage];
}

/** Human-unique order id, e.g. BK-20261107-A3F9C2 */
function generate_order_number(): string
{
    return 'BK-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
}
