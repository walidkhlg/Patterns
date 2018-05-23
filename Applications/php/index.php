<?php

$hostname = getenv("DB_HOST");
$username = getenv("DB_USER");
$password = getenv("DB_PASS");
$dbname = getenv("DB_NAME");
function getInstanceId(){

  $ch = curl_init();
  curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/meta-data/instance-id");
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
  $info = curl_exec($ch);
  curl_close();
  return $info;
}

function getUserAgent(){
    $ua = $_SERVER['HTTP_USER_AGENT'];
    return $ua;

}
function getUserIpAddr(){

    if(!empty($_SERVER['HTTP_CLIENT_IP'])){

        $ip = $_SERVER['HTTP_CLIENT_IP'];
    }elseif(!empty($_SERVER['HTTP_X_FORWARDED_FOR'])){

        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    }else{
        $ip = $_SERVER['REMOTE_ADDR'];
    }
    return $ip;

}
$dt = date('Y-m-d H:i:s');
$user_ip = getUserIpAddr();
$user_agent = getUserAgent();
$conn = new mysqli($hostname, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection to database failed: " . $conn->connect_error);
}
$sql = "CREATE TABLE IF NOT EXISTS Connections (
id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
User_ip VARCHAR(30) ,
User_agent VARCHAR(100),
Request_date DATETIME)";
$conn->query($sql);
$sql = "INSERT INTO Connections (User_ip, User_agent,Request_date) VALUES ('$user_ip', '$user_agent','$dt')";
$conn->query($sql);
$conn->close();

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
  echo '<img src="http://'. $cf . '/Airbus-logo.png" class="center">';
  ?>
  <h1 align="center"> Current User info</h1>
  <a href="history.php" >HISTORY</a>
<table class="blueTable">
  <thead>
         <tr>
             <td><b>Instance Id:</b></td>
             <td><b>User IP :</b></td>
             <td><b>User Agent:</b></td>
             <td><b>Request Date:</b></td>
         </tr>
       </thead>
       <tbody>
         <tr>
           <td><?php echo getInstanceId(); ?></td>
           <td><?php echo getUserIpAddr(); ?></td>
           <td><?php echo getUserAgent(); ?></td>
                  <td><?php echo $dt ?></td>
          </tr>
        </tbody>
</table>
</body>
</html>
