<?php
// index.php — Login & Register
session_start();
require_once 'includes/db.php';

if (isset($_SESSION['user_id'])) {
  header('Location: /Petdaycare/' . $_SESSION['role'] . '/dashboard.php');
  exit;
}

$error   = '';
$success = '';
$tab     = $_GET['tab'] ?? 'login';

// ── LOGIN ─────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'login') {
  $email    = trim($_POST['email']    ?? '');
  $password = $_POST['password']      ?? '';

  if ($email && $password) {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
      $_SESSION['user_id'] = $user['user_id'];
      $_SESSION['name']    = $user['name'];
      $_SESSION['role']    = $user['role'];

      if ($user['role'] === 'owner') {
        $r = $pdo->prepare("SELECT owner_id FROM owners WHERE user_id = ?");
        $r->execute([$user['user_id']]);
        $row = $r->fetch();
        $_SESSION['ref_id'] = $row['owner_id'] ?? null;
      } elseif ($user['role'] === 'staff') {
        $r = $pdo->prepare("SELECT staff_id FROM staff WHERE user_id = ?");
        $r->execute([$user['user_id']]);
        $row = $r->fetch();
        $_SESSION['ref_id'] = $row['staff_id'] ?? null;
      }

      header('Location: /Petdaycare/' . $user['role'] . '/dashboard.php');
      exit;
    } else {
      $error = 'Incorrect email or password. Please try again.';
    }
  } else {
    $error = 'Please enter your email and password.';
  }
}

// ── REGISTER (owners only) ────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'register') {
  $tab      = 'register';
  $name     = trim($_POST['name']                    ?? '');
  $email    = trim($_POST['email']                   ?? '');
  $pass     = $_POST['password']                     ?? '';
  $conf     = $_POST['confirm_password']             ?? '';
  $phone    = trim($_POST['phone']                   ?? '');
  $addr     = trim($_POST['address']                 ?? '');
  $ec_name  = trim($_POST['emergency_contact_name']  ?? '');
  $ec_phone = trim($_POST['emergency_contact_phone'] ?? '');

  if (!$name || !$email || !$pass) {
    $error = 'Name, email, and password are required.';
  } elseif ($pass !== $conf) {
    $error = 'Passwords do not match.';
  } elseif (strlen($pass) < 6) {
    $error = 'Password must be at least 6 characters.';
  } else {
    $chk = $pdo->prepare("SELECT user_id FROM users WHERE email = ?");
    $chk->execute([$email]);
    if ($chk->fetch()) {
      $error = 'An account with this email already exists. Please login.';
    } else {
      $hashed = password_hash($pass, PASSWORD_DEFAULT);
      $pdo->beginTransaction();
      try {
        $pdo->prepare("INSERT INTO users (name,email,password,role,phone) VALUES (?,?,?,'owner',?)")
          ->execute([$name, $email, $hashed, $phone]);
        $uid = $pdo->lastInsertId();
        $pdo->prepare("INSERT INTO owners (user_id,address,emergency_contact_name,emergency_contact_phone) VALUES (?,?,?,?)")
          ->execute([$uid, $addr, $ec_name, $ec_phone]);
        $pdo->commit();
        $success = 'Account created! You can now sign in.';
        $tab = 'login';
      } catch (Exception $e) {
        $pdo->rollBack();
        $error = 'Registration failed. Please try again.';
      }
    }
  }
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PetDaycare — Welcome</title>

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css" rel="stylesheet">

  <!-- Login-specific CSS only -->
  <link rel="stylesheet" href="/Petdaycare/assets/css/login.css">
</head>

<body>

  <div class="auth-wrap">

    <!-- ── LEFT HERO ──────────────────────────────────── -->
    <div class="auth-left">
      <div class="auth-brand">
        <div class="auth-brand-icon">🐾</div>
        <div class="auth-brand-name">PetDaycare</div>
      </div>

      <h1 class="auth-headline">
        Where every pet<br>gets <span>premium care.</span>
      </h1>

      <p class="auth-tagline">
        A complete boarding and daycare management platform for modern pet care facilities — bookings, health logs, vaccinations, and more.
      </p>

      <div class="auth-feature"><i class="fas fa-calendar-check"></i> Online booking with real-time availability</div>
      <div class="auth-feature"><i class="fas fa-notes-medical"></i> Daily health logs by trained staff</div>
      <div class="auth-feature"><i class="fas fa-syringe"></i> Vaccination tracking with automatic alerts</div>
      <div class="auth-feature"><i class="fas fa-file-invoice-dollar"></i> Auto-generated invoices at checkout</div>

      <div class="role-strip">
        🐾 <strong>Owners</strong>: manage pets & bookings
        👩 <strong>Staff</strong>: care logs & check-ins
        ⚙ <strong>Admin</strong>: full facility control
      </div>
    </div>

    <!-- ── RIGHT FORM ─────────────────────────────────── -->
    <div class="auth-right">
      <h2 class="auth-right-title">
        <?= $tab === 'login' ? 'Welcome back 👋' : 'Create account 🐶' ?>
      </h2>
      <p class="auth-right-sub">
        <?= $tab === 'login'
          ? 'Sign in to your account to continue'
          : 'Register as a pet owner to get started' ?>
      </p>

      <!-- Tabs -->
      <div class="auth-tabs">
        <a href="?tab=login" class="auth-tab <?= $tab === 'login'    ? 'active' : '' ?>">
          <i class="fas fa-sign-in-alt me-1"></i> Sign In
        </a>
        <a href="?tab=register" class="auth-tab <?= $tab === 'register' ? 'active' : '' ?>">
          <i class="fas fa-user-plus me-1"></i> Register
        </a>
      </div>

      <!-- Alerts -->
      <?php if ($error): ?>
        <div class="auth-alert auth-alert-error">
          <i class="fas fa-exclamation-circle"></i> <?= htmlspecialchars($error) ?>
        </div>
      <?php endif; ?>
      <?php if ($success): ?>
        <div class="auth-alert auth-alert-success">
          <i class="fas fa-check-circle"></i> <?= htmlspecialchars($success) ?>
        </div>
      <?php endif; ?>

      <!-- ── LOGIN FORM ─────────────────────────────── -->
      <?php if ($tab === 'login'): ?>
        <form method="POST">
          <input type="hidden" name="action" value="login">

          <div class="auth-field">
            <label class="auth-label">Email Address</label>
            <input type="email" name="email" class="auth-input" placeholder="you@example.com" required>
          </div>

          <div class="auth-field">
            <label class="auth-label">Password</label>
            <input type="password" name="password" class="auth-input" placeholder="••••••••" required>
          </div>

          <button type="submit" class="auth-btn">
            <i class="fas fa-arrow-right-to-bracket me-2"></i>Sign In
          </button>
        </form>

        <!-- ── REGISTER FORM ──────────────────────────── -->
      <?php else: ?>
        <form method="POST">
          <input type="hidden" name="action" value="register">
          <div class="auth-scroll">

            <div class="auth-row">
              <div class="auth-field">
                <label class="auth-label">Full Name *</label>
                <input type="text" name="name" class="auth-input" placeholder="Ahmed Ali" required>
              </div>
              <div class="auth-field">
                <label class="auth-label">Phone</label>
                <input type="text" name="phone" class="auth-input" placeholder="0300-1234567">
              </div>
            </div>

            <div class="auth-field">
              <label class="auth-label">Email Address *</label>
              <input type="email" name="email" class="auth-input" placeholder="you@example.com" required>
            </div>

            <div class="auth-row">
              <div class="auth-field">
                <label class="auth-label">Password *</label>
                <input type="password" name="password" class="auth-input" placeholder="Min 6 chars" required>
              </div>
              <div class="auth-field">
                <label class="auth-label">Confirm Password *</label>
                <input type="password" name="confirm_password" class="auth-input" placeholder="Repeat" required>
              </div>
            </div>

            <div class="auth-field">
              <label class="auth-label">Home Address</label>
              <input type="text" name="address" class="auth-input" placeholder="House 12, Block B, Karachi">
            </div>

            <div class="auth-row">
              <div class="auth-field">
                <label class="auth-label">Emergency Contact Name</label>
                <input type="text" name="emergency_contact_name" class="auth-input" placeholder="Bilal Ali">
              </div>
              <div class="auth-field">
                <label class="auth-label">Emergency Contact Phone</label>
                <input type="text" name="emergency_contact_phone" class="auth-input" placeholder="0321-0000000">
              </div>
            </div>

          </div><!-- end scroll -->

          <button type="submit" class="auth-btn">
            <i class="fas fa-user-plus me-2"></i>Create Account
          </button>

          <p class="auth-note">
            <i class="fas fa-info-circle me-1"></i>
            Registration is for pet owners only. Staff accounts are created by the admin.
          </p>
        </form>
      <?php endif; ?>

    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>