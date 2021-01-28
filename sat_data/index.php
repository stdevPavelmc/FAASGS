<?php

function delete_directory( $dir ) {
    if ( is_dir( $dir ) ) {
        $dir_handle = opendir( $dir );
        if( $dir_handle ) {
            while( $file = readdir( $dir_handle ) )  {
                if($file != "." && $file != "..")  {
                    if( ! is_dir( $dir."/".$file ) ) {
                        unlink( $dir."/".$file );
                    } else {
                        delete_directory($dir.'/'.$file);
                    }
                }
            }
        closedir( $dir_handle );
        }
        rmdir( $dir );
        return true;
    }
    return false;
}

# detect passed argument delete=true
if (isset($_GET['delete']) && $_GET['delete'] == "true") {
    # erase directory
    delete_directory(getcwd());
    echo "
    <html>
    <head />
    <body>
    <script type='text/javascript'>
        window.close();
    </script>
    </body>
    </html>
    ";
    exit(0);
}

$satname = "";
$satfreq = "";
$satdate = "";
$satmaxaz = "";
$satlong = "";

# load details of this pass, example
#   AO95,145.920,Wed Dec 30 22:28:00,45,744s
$detailsfile = explode("\n", file_get_contents("./details.txt"));
foreach ($detailsfile as $vars) {
    if ('' === $vars) continue;

    $data = explode(",", $vars);

    $satname = $data[0];
    $satfreq = $data[1];
    $satdate = $data[2];
    if (count($data) > 3) {
        $satmaxaz = $data[3];
        $mins = intval($data[4]) / 60;
        $sec = intval($data[4]) % 60;
        $satlong = intval($mins).":".$sec;
    }
}
?>
<html>
    <head>
        <title>Satelite <?php echo $satname." / ".$satfreq; ?></title>
        <link rel="stylesheet" href="../../style.css" debug="false">
        <script type="text/javascript">
            function confirm_erase() {
                if(window.confirm("Are you sure you want to erase the entire folder?")){
                    return true;
                } else {
                    return false;
                }
            }
	    </script>
    </head>
    <body class="body">
    <div class="wrap">
        <div class='sat_info'>
            <div class="titlehead">recorded satellite data</div>

            <div class="sat_data_head">Satellite:</div>
            <div class="sdata">
                <?php echo $satname?>
            </div>

            <div class="sat_data_head">Reception date:</div>
            <div class="sdata">
                <?php echo $satdate;?>
            </div>

            <div class="sat_data_head">Reception Frequency:</div>
            <div class="sdata">
                <?php echo $satfreq." MHz";?>
            </div>

            <div class="sat_data_head">Pass max elevation:</div>
            <div class="sdata">
                <?php echo $satmaxaz." degrees";?>
            </div>

            <div class="sat_data_head">Pass duration:</div>
            <div class="sdata">
                <?php echo $satlong." (min:secs)";?>
            </div>

            <div class="sat_data_head">&nbsp;</div>
            <div class="titlehead">Actions</div>
            <div class="thumbs">
                <a class="tooltip" href=<?php
                if (file_exists(getcwd()."/".$satname.".mp3")) {
                    echo "'./".$satname.".mp3'";
                } else {
                    echo "'./".$satname.".wav'";
                }?> alt="Click to play, Right click then save to download">
                    <img src="../../img/audio.png" />
                    <span class="tooltiptext">Click to play, Right click, then save link to download.</span>
                </a>

                <a class="tooltip" href="#" onclick="window.close();">
                    <img src="../../img/back.png" />
                    <span class="tooltiptext">Close this windows and go back to listing.</span>
                </a>
                <?php

                // don't show the erase if a file called noerase is present in the folder
                if (!file_exists(getcwd()."/noerase")) {
                ?>
                <a class="tooltip" href="./?delete=true" onclick="return confirm_erase();">
                    <img src="../../img/delete.png" />
                    <span class="tooltiptext">Click to erase the folder if any valuable data was captured.</span>
                </a>
                <?php
                }
                ?>
                <span class="stretch"></span>
            </div>
        </div>
        <div class="image">
            <?php
            // in early version all files are png, in modern ones they are jpeg
            $ext = "jpg";

            if (!file_exists(getcwd()."/".$satname.".".$ext)) {
                $ext = "png";
            }

            // NOAA or voice?
            if (strpos($satname, 'NOAA') !== false) {
            ?>
            <div class="thumbs">
                <a href=<?php echo "'".$satname."C.".$ext."'"; ?>  target="_blank">
                    <img src=<?php echo "'t".$satname."C.jpg'"; ?>/>
                </a>
                <a href=<?php echo "'".$satname.".".$ext."'"; ?> target="_blank">
                    <img src=<?php echo "'t".$satname.".jpg'"; ?> />
                </a>
                <a href=<?php echo "'".$satname."T.".$ext."'"; ?>  target="_blank">
                    <img src=<?php echo "'t".$satname."T.jpg'"; ?> />
                </a>
                <a href=<?php echo "'".$satname."3D.".$ext."'"; ?> target="_blank">
                    <img src=<?php echo "'t".$satname."3D.jpg'"; ?> />
                </a>
                <span class="stretch"></span>
            </div>
            <?php

            } else {
                // is a voice sat
            ?>
            <a href=<?php echo "'".$satname.".".$ext."'"; ?> target="_blank" >
                <img src=<?php echo "'".$satname.".".$ext."'"; ?> style="max-width: 100%; max-height: 100%; display: block;"/>
            </a>
            <?php

            }

            ?>
        </div>
    </div>
    </body>
</html>