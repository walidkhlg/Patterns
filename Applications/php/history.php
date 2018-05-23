<?php
$hostname = getenv("DB_READ_HOST");
$username = getenv("DB_USER");
$password = getenv("DB_PASS");
$dbname = getenv("DB_NAME");
$conn = new mysqli($hostname, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection to database failed: " . $conn->connect_error);
}
$sql = "SELECT * FROM Connections";
$result = $conn->query($sql);
?>
<html>
<head>
  <?php
    $cf = getenv("CLOUD_FRONT_DOMAIN");
    echo '<link rel="stylesheet" type="text/css" href="http://' .$cf  . '/style.css">';
    ?>
</head>
<body>
  <?php
  echo '<img src="http://'. $cf . '/Airbus-logo.png class="center"">';
  ?>
  <h1> HISTORY </h1>
<table class="blueTable">
  <tr>
    <td><b>Instance Id:</b></td>
    <td><b>User IP :</b></td>
    <td><b>User Agent:</b></td>
    <td><b>Request Date:</b></td>
  </tr>
  <?php

  if ($result->num_rows > 0) {
      // output data of each row
      while($row = $result->fetch_assoc()) {
          echo "<tr><td>" . $row["id"]. "</td><td>" . $row["User_ip"]. "</td><td>" . $row["User_agent"]. "</td><td>" . $row["Request_date"] . "</td></tr>";
      }
  } else {
      echo "0 results";
  }
  $conn->close();
  ?>
</table>
</body>
</html>
