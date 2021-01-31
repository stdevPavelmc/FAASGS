<?php

?>
<html>
    <head>
        <title>
            Automatic Satellite Ground Station
        </title>
        <link rel="stylesheet" href="./style.css" debug="false">
        <script type="text/javascript" src="jquery.min.js"></script>
        <script type="text/javascript">
            $( document ).ready(function() {
                // get height and width of screen
                var h=$(window).height(), w=$(window).width();

                // check for mobile device
                if ( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || (w < 764 || h < 719)) {
                    $(".mobile").remove();
                    $("#dif").css("overflow", "scroll");
                }
            });

            function show_image(sat_folder){
                // open folder
                window.open(sat_folder);
            }
	    </script>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-view,initial-scale=1.0"/>
    </head>
    <body class="body">
        <div id='page'>
            <div id='left' class="left_container">
                <div class="qth_header">
                    <div class="user">
                        <h5>Automatic Satellite Ground Station</h5>
                    </div>
                    <div id='title' class="title">
                        <h1>%LOC_NAME% - %LOC_COUNTRY% - %LOC%</h1>
                    </div>
                    <img style="float: right; margin: 0px 0px 15px 15px;" src="img/satellite.png" />
                    <p class="comments">
                    Autonomous Satellite Ground Station, using Linux an a RTL-SDR</br>
                    Tracking numerous satellites for the ham community, working 24/7</br>
                    Capturing images from NOAAs and audio from FM satellites</br>
                    Visit us on the <a href="https://github.com/stdevPavelmc/FAASGS">Github Repository</a> for more info
                    </p>
                </div>
                <div class="left_sc">
                    <div class="titlehead">next satellite passes</div>
                    <div class="scroll_container">
                        <div class="scrollable">
                            <table>
                            <?php
                            $passes = explode("\n", file_get_contents("sat/passes.txt"));
                            sort($passes );

                            foreach ($passes as $pass) {
                                if ('' === $pass) continue;

                                $pass_txt = explode(",", $pass);

                                $sat_time = $pass_txt[0];
                                $sat_name = $pass_txt[1];
                                $sat_freq = $pass_txt[2];

                                # check the time, if it's in the past jump
                                $now = strtotime(date("Y-m-d"));
                                $aos = strtotime($sat_time);
                                if ( $now > $aos) continue;

                                ?>
                                <tbody class="clickable">
                                    <tr>
                                        <th>Satellite</th>
                                        <th>Time</th>
                                        <th>Freq</th>
                                    </tr>
                                    <tr data-index="1">
                                        <td><?php echo $sat_name ?></td>
                                        <td><?php echo $sat_time ?></td>
                                        <td class="points"><?php echo $sat_freq ?></td>
                                    </tr>
                                </tbody>
                                <?php
                                }
                            ?>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            <div class="right_container">
                <div class="titlehead">recorded satellite passes</div>
                <div class="scroll_container">
                    <div class="scrollable">
                        <table>
                            <?php
                            function listdir_by_date($path){
                                $dir = opendir($path);
                                $list = array();
                                while($file = readdir($dir)){
                                    if ($file != '.' and $file != '..' and $file != 'passes.txt'){
                                        // add the filename, to be sure not to
                                        // overwrite a array key
                                        $fpath = $path."/".$file;
                                        $ctime = date('Y-m-d', filectime($fpath)).','.$file;
                                        $list[$ctime] = $file;
                                    }
                                }
                                closedir($dir);
                                krsort($list);
                                return $list;
                            }

                            $directory = '/var/www/html/sat';

                            foreach (listdir_by_date($directory) as $dir) {
                                if ('.' === $dir) continue;
                                if ('..' === $dir) continue;
                                if ('passes.txt' === $dir) continue;

                                $text_file = "sat/".$dir."/details.txt";
                                $noaa_txt = explode(",", file_get_contents($text_file));

                                $sat_name = $noaa_txt[0];

                                $img_file = "sat/".$dir."/".$sat_name.".png";
                                $sat_freq = $noaa_txt[1];

                                $sat_time = substr($noaa_txt[2], 0, 24);

                                if (count($noaa_txt) > 3) {
                                    $sat_elev = $noaa_txt[3];
                                    $sat_duration = $noaa_txt[4];
                                } else {
                                    $sat_elev = '';
                                    $sat_duration = '';
                                }
                                ?>
                                <tbody onClick="show_image('<?php echo "sat/".$dir."/"; ?>')" class="clickable">
                                    <tr>
                                        <th>Satellite</th>
                                        <th>Time</th>
                                        <th>Freq</th>
                                    </tr>
                                    <tr data-index="1">
                                        <td><?php echo $sat_name." (".$sat_elev.")" ?></td>
                                        <td><?php echo $sat_time ?></td>
                                        <td class="points"><?php echo $sat_freq ?></td>
                                    </tr>
                                </tbody>
                                <?php
                                }
                        ?>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>