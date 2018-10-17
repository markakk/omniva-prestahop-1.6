{*
* 2007-2014 PrestaShop
*
* NOTICE OF LICENSE
*
* This source file is subject to the Academic Free License (AFL 3.0)
* that is bundled with this package in the file LICENSE.txt.
* It is also available through the world-wide-web at this URL:
* http://opensource.org/licenses/afl-3.0.php
* If you did not receive a copy of the license and are unable to
* obtain it through the world-wide-web, please send an email
* to license@prestashop.com so we can send you a copy immediately.
*
*         DISCLAIMER   *
* *************************************** */
/* Do not edit or add to this file if you wish to upgrade Prestashop to newer
* versions in the future.
* ****************************************************
*}
{addJsDef omnivaltdelivery_controller=$link->getModuleLink('omnivaltshipping', 'ajax')}
<div id="omnivalt_parcel_terminal_carrier_details" style="display: block; margin-top: 10px;">
    <select class="select2" name="omnivalt_parcel_terminal">{$parcel_terminals}</select>
    <script type="text/javascript">
        {literal}
        $(document).ready(function(){
            omnivaltDelivery.init();
            $('.select2').select2();
        })
        {/literal}
        var omnivalt_parcel_terminal_carrier_id = {$omnivalt_parcel_terminal_carrier_id}
    </script>

    <style>
        {literal}
            #omnivalt_parcel_terminal_carrier_details{ margin-bottom: 5px }
        {/literal}
    </style>
{if isset($omniva_api_key) and $omniva_api_key != false}


    <script type="text/javascript">
        var locations = {$terminals_list};
        var select_terminal = "{l s='Pasirinkti terminalą'}";
        {literal}
        var base_url = window.location.origin;
        var map, geocoder, opp = true;
        const image = base_url+'/modules/omnivaltshipping/sasi.png';

        window.onload = function(e){
            geocoder = new google.maps.Geocoder();
            if (window.location.protocol != "https:") {
            /*    document.querySelector('.btn-address-gps').style.display = "none"; */
            }
            map = new google.maps.Map(document.getElementById('map-omniva-terminals'), {
                zoom: 7,
                center: new google.maps.LatLng(54.917362, 23.966171),
                mapTypeId: google.maps.MapTypeId.ROADMAP
            });

        var infowindow = new google.maps.InfoWindow();
        var marker, i;

        /** Autocomplete **/
            var input = document.getElementById('address-omniva');
            var options = {
                        componentRestrictions: {country: ['lt', 'lv', 'ee']}
                        };
            var autocomplete = new google.maps.places.Autocomplete(input, options);
            //autocomplete.bindTo('bounds', map);

        autocomplete.setFields(
            ['address_components', 'geometry', 'icon', 'name']);

        autocomplete.addListener('place_changed', function() {

            var place = autocomplete.getPlace();
            const location = place.geometry.location;
            input.lat = location.lat();
            input.lng = location.lng();
            console.log(location.lat(), location.lng())
            if (!place.geometry) {
                console.log("No details available for input: '" + place.name + "'");
                return;
            }
        });

        /** /Autocomplete **/

        function terminalDisplay(terminal) {
            /*terminalSelected(terminal[3], `${terminal[0]} ${terminal[5]}`);*/
            return (
                `<div >\
                <b>${terminal[0]}</b><br /> \
                ${terminal[4]} <br />\
                ${terminal[5]} <br/> \
                ${terminal[6]} <br/> \
                <button class="btn-marker" style="margin-top: 10px;" onclick="terminalSelected(${terminal[3]}, '${terminal[0]} ${terminal[5]}')">${select_terminal}</button>\
                </div>`
            );
        }

        markers = [];
        for (i = 0; i < locations.length; i++) {  
            marker = new google.maps.Marker({
                position: new google.maps.LatLng(locations[i][1], locations[i][2]),
                map: map,
                icon: image,
                ttype: locations[i][0],
                address: locations[i][5],
            });

            markers[i] = marker;

            google.maps.event.addListener(marker, 'click', (function(marker, i) {
                return function() {
                infowindow.setContent(terminalDisplay(locations[i]));
                infowindow.open(map, marker);
                }
            })(marker, i));
        }

        var markerCluster = new MarkerClusterer(map, markers,
                      {imagePath: base_url+'/modules/omnivaltshipping/m'});
        }

        function terminalSelected(terminal) {
            omnivaSelect = document.getElementsByName("omnivalt_parcel_terminal");

            var container = document.querySelector("select[name='omnivalt_parcel_terminal']");
            var matches = document.querySelectorAll(".omnivaOption");

            matches.forEach(node => {
                if(node.getAttribute("value") == terminal)
                    node.selected = 'selected';
                else
                    node.selected = false;
            })
            
            $('select[name="omnivalt_parcel_terminal"]').show();
            $('select[name="omnivalt_parcel_terminal"]').trigger("change");
        }

        function codeAddress() {
            var address = document.getElementById('address-omniva').value;
            geocoder.geocode( { 'address': address}, function(results, status) {
                if (status == 'OK') {
                    find_closest_markers(results[0].geometry.location)
                } else {
                    console.log('Geocode was not successful for the following reason: ' + status);
                }
            });
        }

    var $closest_five = [];
    function find_closest_markers(event) {
        var R = 6371, distances = [], $lengths = [], $to_sort = [], $l = markers.length, closest = -1;

        for (var i in markers) {
            // IE needs that
            if (isNaN(i))
                continue;
            var $mark = markers[i];     
            var rpos1 = $mark.getPosition();
            var d = google.maps.geometry.spherical.computeDistanceBetween(rpos1, event);
            distances[i] = d;
            $lengths[d] = i;
            $to_sort.push({markerId: i, km: d});
            if (closest == -1 || d < distances[closest]) {
                closest = i;
            }
        }

        $to_sort.sort(function(a, b) {
            if (parseFloat(a.km) < parseFloat(b.km)) {
                return -1;
            }
            if (parseFloat(a.km) > parseFloat(b.km)) {
                return 1;
            }
            return 0;
        });

        if ($to_sort.length > 0) {
            var count = 6, counter = 0, html = '';
            $to_sort.forEach(function(terminal){
                
                if (counter == 0) {
                    zoomToMarker(terminal.markerId)
                    closestMarkerId = terminal.markerId;
                }
                if(counter > count) 
                    return;
                    counter++;

                terminal.km = (terminal.km/1000).toFixed(2);
                html += `<li onclick="zoomToMarker(${terminal.markerId})" ><a class="omniva-li"><b>${markers[terminal.markerId].ttype}</b></a> <b>${terminal.km} km.</b></li>`
            });

            document.querySelector('.found_terminals').innerHTML = '<ol class="omniva-terminals-list" start="1" >'+html+'</ol>';
            zoomToMarker(closestMarkerId);
        }
    }

        function zoomToMarker(closest) {
            map.setZoom(15);
            map.panTo(markers[closest].position);
        }

        function findNearest() {
            navigator.geolocation.getCurrentPosition((loc) => {
                console.log('The location in lat lon format is: [', loc.coords.latitude, ',', loc.coords.longitude, ']');
                find_closest_markers(loc.coords)
            })
        }
        {/literal}
    </script>
    <button id="show-omniva-map" class="btn btn-basic btn-sm"><i id="show-omniva-map" class="fa fa-map-marker-alt fa-lg" aria-hidden="true"></i></button>
</div>
{/if}