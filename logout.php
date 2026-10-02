<?php
session_start();
session_destroy();
header('Location: /petdaycare/index.php');
exit;