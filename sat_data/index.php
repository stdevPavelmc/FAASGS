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
                if(window.confirm("Are you sure you want to erase the recorded folder?")){
                    return true;
                } else {
                    return false;
                }
            }
	    </script>
    </head>
    <body class="body">
    <div id='page' style="display: flex;">
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
            <table class="actions">
                <tr>
                    <td>
                        <a class="tooltip" href=<?php
                        if (file_exists(getcwd()."/".$satname.".mp3")) {
                            echo "'./".$satname.".mp3'";
                        } else {
                            echo "'./".$satname.".wav'";
                        }?> alt="Click to play, Right click then save to download">
                            <img src="../../audio.png" />
                            <span class="tooltiptext">Click to play, Right click, then save link to download</span>
                        </a>
                    </td>
                    <td>
                        <a class="tooltip" href=<?php echo "'./".$satname.".png'"; ?>>
                            <img src="../../image.png" />
                            <span class="tooltiptext">Click to view the original image, Right click, then save link to download</span>
                        </a>
                    </td>
                    <td>
                        <a class="tooltip" href="./?delete=true" onclick="return confirm_erase();">
                            <img src="../../delete.png" />
                            <span class="tooltiptext">Click to erase the folder if any data was captured</span>
                        </a>
                    </td>
                </tr>
            </table>
        </div>
        <div id='image' style="flex: 1;">
                <a href=<?php echo "'./".$satname.".png'"; ?>>
                <img src=<?php echo "'".$satname.".png'"; ?> style="max-width: 100%; max-height: 100%; display: block;"/>
            </a>
        </div>
    </div>
    </body>
</html>