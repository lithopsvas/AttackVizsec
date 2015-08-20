<!DOCTYPE html>
<html>

    <head>
        <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
        <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=true"></script>
        <script type="text/javascript" src="javascript/d3.v2.js"></script>
        <script type="text/javascript" src="javascript/d3.tip.v0.6.3.js"></script>
        <script type="text/javascript" src="javascript/d3.js"></script>
        <script src="https://code.jquery.com/jquery-1.10.2.js"></script>
        <style type="text/css"> 
            @import url("style.css?1.10.0");
        </style>
    </head>

    <body onload="removeElements();
            drawPreviews();">

        <form style="position: absolute; z-index: 1; background-color: #3d3d3d; color:#fff;" >
            <input id="pro" type="radio" name="mode" value="proactive" onClick="proactive()" checked>Proactive
            <br>
            <input id="re" type="radio" name="mode" value="reactive" onClick="reactive()" >Reactive
        </form> 



        <!--remove the elements in the map where -->
        <div id="map" style="position: absolute"></div>

        <!-- <button type="button" class="button" id="btn" onclick="changeMode()">Proactive</button>-->
        <script type="text/javascript" >
            // Create the Google Map?
            var map = new google.maps.Map(d3.select("#map").node(), {
                zoom: 11,
                center: new google.maps.LatLng(41.859307, 12.596115), //center of rome
                mapTypeId: google.maps.MapTypeId.ROADMAP
            });

            var styles = [
                {
                    "featureType": "road",
                    "elementType": "labels",
                    "stylers": [
                        {"visibility": "off"}
                    ]
                }, {
                    "featureType": "poi",
                    "stylers": [
                        {"visibility": "off"}
                    ]
                }, {
                    "featureType": "transit.station",
                    "elementType": "labels",
                    "stylers": [
                        {"visibility": "off"}
                    ]
                }
            ];

            map.setOptions({styles: styles});
//map.setOptions({scrollwheel: false});
//redraw function on zoom
            google.maps.event.addListener(map, 'zoom_changed', function () {
                var attack = d3.selectAll(".lineStaticAttack");

                var array = attack[0];
                var arrayID = [];
                //get the relative number of the drawn arcs
                array.forEach(function (d) {
                    var id = d.id.match(/[0-9]+/)[0];
                    if (arrayID.indexOf(id) == -1)
                        arrayID.push(id)
                })

                attack.remove();
                //redraw the arcs
                arrayID.forEach(function (d) {
                    var json = "json attack/attack" + d + ".json";
                    createGraph(json, d, 0);
                })

                //instantiate version
                var attack = d3.selectAll(".lineInstantiateAttack");

                var array = attack[0];
                var arrayID = [];
                //get the relative number of the drawn arcs
                array.forEach(function (d) {
                    var id = d.id.match(/[0-9]+/)[0];
                    if (arrayID.indexOf(id) == -1)
                        arrayID.push(id)
                })

                attack.remove();
                //delete previews
                //d3.selectAll(".attackPreview").selectAll("svg").selectAll("path").remove();
                // d3.selectAll(".attackPreview").selectAll("svg").selectAll("circle").remove();
                //d3.selectAll(".attackPreview").selectAll("svg").selectAll("rect").remove();
                //redraw the arcs
                arrayID.forEach(function (d) {
                    var json = "json attack/attack" + d + ".json";
                    createGraph(json, d, 1);
                })
                /*
                 for(var i=1;i<7;i++)
                 drawFunc(i);*/
            });

            var h = parseInt(window.innerHeight),
                    w = parseInt(window.innerWidth),
                    mode = 0, //0=proactive, 1=reactive
                    overlay = 0,
                    sideFlag = 0, //0 open, 1 hidden
                    bottomFlag = 0, //0 open, 1 hidden
                    sizeLabel = 50,
                    svgshifting = 2500,
                    borderAttackPreview = 2,
                    totalEdges = [],
                    totalNode = [],
                    subnetList = [],
                    queueSVG = [],
                    wSideMenu = w * 0.20,
                    hBottomMenu = h * 0.25,
                    width = wSideMenu,
                    height = wSideMenu,
                    mm = 0,
                    originalPos = [],
                    radius = Math.min(width, height) / 1.5,
                    projection = 0,
                    layer = 0,
                    numberOfPreviewAttack = 5,
                    sideMenu = d3.select("body").append("div").attr("class", "sideMenu"),
                    bottomMenu = d3.select("body").append("div").attr("class", "bottomMenu").style("width", w).style("height", hBottomMenu).style("background-color", "#3d3d3d"),
                    wAttackPreview = (w - borderAttackPreview * (numberOfPreviewAttack * 2)) / numberOfPreviewAttack,
                    flagTable = 0,
                    flagClickedNode = 0, //0 not clicked, 1 clicked
                    lastClickedNode = "",
                    array = ["#8dd3c7", "#bebada", "#80b1d3", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "2035FF", "0AB26C"],
                    color = d3.scale.ordinal().range(array),
                    wMap = w - wSideMenu - w / 5, //w/5 is space in excess
                    hMap = h - hBottomMenu,
                    wSVGPreview = wAttackPreview,
                    hPreviewDiv = 35,
                    likelihoodRank = [],
                    idInstantiated = -1,
                    hSVGPreview = hBottomMenu,
                    json_file = "dati1.json";

            document.getElementById('pro').checked = true;

// Load the station data. When the data comes back, create an overlay.

            d3.json("dati1.json", function (source) {
                overlay = new google.maps.OverlayView();

                //create node list
                createNodeList(source);
                //we lock the position
                totalNode.forEach(function (d) {
                    d.fixed = true;

                });
                // Add the container when the overlay is added to the map.
                overlay.onAdd = function () {

                    //l'svg deve essere pi� grande dello schermo altrimenti taglia
                    layer = d3.select(this.getPanes().overlayLayer)
                            .append("svg")
                            .attr("class", "overlayedSVG")
                            .style("width", svgshifting * 2 + "px")
                            .style("height", svgshifting * 2 + "px")
                            .style("top", -svgshifting + "px")
                            .style("left", -svgshifting + "px");

                    // Draw each marker as a separate SVG element.
                    // We could use a single SVG, but what size would it have?
                    overlay.draw = function () {
                        projection = this.getProjection(),
                                padding = 10;

                        var force = d3.layout.force()
                                .nodes(totalNode)
                                .links(totalEdges)
                                .size([w, h])
                                .start();

                        /*	layer.append("defs")
                         .append('pattern')
                         .attr('id', 'bg')
                         .attr('patternUnits', 'userSpaceOnUse')
                         .attr('width', 400)
                         .attr('height', 400)
                         .append("image")
                         .attr("xlink:href", "img/button_menu.png")
                         .attr('width', 25)
                         .attr('height', 25);*/

                        //marker for arrows map
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "end")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", 10)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse") //adjust the head of the arrow basing on markerWidth and markerHeight attr, prevent the inherit from stoke-width
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");

                        //marker for arrows preview
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "preview")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", 13)
                                .attr("refY", -1)
                                .attr("markerWidth", 4)
                                .attr("markerHeight", 10)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");

                        //marker for arrows instantiate attack
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "instantiate")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", 13)
                                .attr("refY", -1)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");

                        var edges = layer.selectAll(".line")
                                .data(totalEdges)
                                .each(transformLine)
                                .enter()
                                .append("line")
                                .each(transformLine)
                                .attr("class", "line"); //qui metteremo il peso degli archi

                        var nodes = layer.selectAll(".node")
                                .data(totalNode)
                                .each(transformNode)
                                .enter()
                                .append("svg:svg")
                                .each(transformNode)
                                .attr("class", "node");

                        nodes.append("circle")
                                .attr("r", 7) //possiamo cambiare la dimensione del nodo
                                .style("fill", "#3d3d3d")
                                .attr("cx", padding)
                                .attr("cy", padding);

                        nodes.append("text")
                                .attr("x", padding + 7)
                                .attr("y", padding)
                                .attr("dy", ".31em")
                                .text(function (d) {
                                    return d.name
                                });

                        function transformNode(d) {
                            var n = d.name;
                            d = new google.maps.LatLng(d.x, d.y);
                            d = projection.fromLatLngToDivPixel(d);
                            //save the original position of the nodes
                            if (mm == 0) {
                                originalPos.push({
                                    name: n,
                                    x: d.x,
                                    y: d.y
                                });
                            }
                            return d3.select(this)
                                    .attr("x", (d.x - padding + svgshifting))
                                    .attr("y", (d.y - padding + svgshifting));
                        }

                        function transformLine(d) {
                            var d1 = new google.maps.LatLng(d.source.x, d.source.y);
                            var d2 = new google.maps.LatLng(d.target.x, d.target.y);
                            d1 = projection.fromLatLngToDivPixel(d1);
                            d2 = projection.fromLatLngToDivPixel(d2);
                            return d3.select(this)
                                    .attr("x1", (d1.x + svgshifting))
                                    .attr("y1", (d1.y + svgshifting))
                                    .attr("x2", (d2.x + svgshifting))
                                    .attr("y2", (d2.y + svgshifting));
                        }
                        mm++;
                    };
                };
                createSideMenu(sideMenu);
                createBottomMenu(bottomMenu);

                //donut chart

                // Bind our overlay to the map?
                overlay.setMap(map);
                removeElements();
                drawDonutChart();
            });

            function drawPreviews() {

                var time = 3000;
                for (var indexOfPreview = 1; indexOfPreview < 10; indexOfPreview++) {

                    var myVar = setTimeout("drawFunc(" + indexOfPreview + ")", time);
                    time = time + 5000;
                }
            }

            function removeElements() {
                d3.selectAll(".gmnoprint").remove();
                d3.select(".gm-style-cc").remove();
                d3.select("a").remove();
            }

            function createNodeList(source) {
                var i = 0;
                source.children.forEach(function (d) {
                    var j = 0;
                    var name = d.node;
                    var subnet = d.subnet;
                    var size = d.vulnerabilities.length;
                    var patch = 0;
                    var crit = 0;
                    var xlat = d.lat;
                    var ylong = d.long;
                    if (size > 0) {
                        d.vulnerabilities.forEach(function (x) {
                            patch += parseInt(x.patchability);
                            crit += parseFloat(x.score);
                        })
                    }

                    if (!check(subnetList, subnet)) {
                        subnetList.push({
                            subnet: subnet,
                            size: 1
                        });
                    } else {
                        subnetList.forEach(function (x) {
                            if (x.subnet === subnet) {
                                x.size++;
                            }
                        });
                    }

                    totalNode.push({
                        name: name,
                        subnet: subnet,
                        size: size,
                        patchValue: patch, // dovrebbe essere patch/size
                        critValue: crit, // dovrebbe essere crit/size
                        x: xlat,
                        y: ylong
                    });
                    totalNode.forEach(function (d) {

                        if (d.subnet == subnet && d.name != name)
                            totalEdges.push({
                                source: i,
                                target: j
                            })
                        j++;
                    });
                    i++;
                });
            }

            function getCssProperty(elmId, property) {
                var elem = document.getElementById(elmId);
                return window.getComputedStyle(elem, null).getPropertyValue(property);
            }

            function check(list, val) {
                var grandezza = list.length;
                while (grandezza--) {
                    if (list[grandezza].subnet === val) {
                        return true;
                    }
                }
                return false;
            }

            function createSideMenu(sideMenu) {
                sideMenu.style("height", h + "px")
                        .style("width", wSideMenu + "px")
                        .style("top", 0 + "px")
                        .style("left", w - wSideMenu + "px")
                        .style("position", "absolute")
                        .style("background-color", "#3d3d3d");

                sideMenu.append("div").attr("class", "sideMenuLabel")
                        .style("position", "relative")
                        .style("top", 0 + "px")
                        .style("left", -sizeLabel + "px")
                        .style("height", sizeLabel + "px")
                        .style("width", sizeLabel + "px")
                        .on("click", function () {
                            if (sideFlag == 0) {
                                sideMenu.transition().style("left", w + "px").duration(1500);
                                sideFlag = 1;
                            } else {
                                sideMenu.transition().style("left", w - wSideMenu + "px").duration(1500);

                                sideFlag = 0;
                            }
                        })
                        .style("background-color", "#3d3d3d");
            }

//creates bottom menu and associates for each div a svg
            function createBottomMenu(bottomMenu) {
                bottomMenu.style("height", hBottomMenu + borderAttackPreview * 2 + "px")
                        .style("width", w + "px")
                        .style("max-width", w + "px")
                        .style("top", h - hBottomMenu - borderAttackPreview * 2 + "px")
                        .style("left", 0 + "px")
                        .style("position", "absolute");

                var label = d3.select("body").append("div").attr("class", "bottomMenuLabel");
                label.style("position", "absolute")
                        .style("top", h - hBottomMenu - sizeLabel - borderAttackPreview * 2 + "px")
                        .style("left", "0px")
                        .style("height", sizeLabel + "px")
                        .style("width", sizeLabel + "px")
                        .on("click", function () {
                            if (bottomFlag == 0) {
                                bottomMenu.transition().style("top", h + "px").duration(1500);
                                label.transition().style("top", h - sizeLabel + "px").duration(1500);
                                bottomFlag = 1;
                            } else {
                                bottomMenu.transition().style("top", h - hBottomMenu - borderAttackPreview * 2 + "px").duration(1500);
                                label.transition().style("top", h - sizeLabel - hBottomMenu - borderAttackPreview * 2 + "px").duration(1500);
                                bottomFlag = 0;
                            }
                        })
                        .style("background-color", "#3d3d3d");

                /* for (var i = 0; i < numberOfPreviewAttack+1; i++) {
                 var previewDiv = bottomMenu.append("div");
                 previewDiv.attr("class", "attackPreview")
                 .attr("id", "attackPreview" + (i + 1))
                 .style("width", wAttackPreview + "px")
                 .style("height", hBottomMenu + "px")
                 .append("svg")
                 .style("width", wAttackPreview+ "px")
                 .style("height", hBottomMenu + "px");
                 }
                 */
            }

            function changeMode() {
                //var btn = document.getElementById("btn");
                var btn = d3.select(".button");
                if (btn.text() == "Proactive")
                    btn.text("Reactive")
                else
                    btn.text("Proactive")
            }

            function drawPreview(svg, json, indexOfPreview) {
                var graphAttack = [];
                d3.json(json, function (source) {
                    source.attack.forEach(function (d) {
                        var nodeS = d.source.name,
                                nodeT = d.target.name;
                        totalNode.forEach(function (e) {
                            if (e.name == nodeS)
                                nodeS = e;
                            if (e.name == nodeT)
                                nodeT = e;
                        });
                        //console.log(nodeS)
                        graphAttack.push({
                            s: nodeS,
                            t: nodeT
                        })
                    });
                    graphAttack.pop();
                    drawArcs(svg, graphAttack);
                    //animationArcs(svg,graphAttack);
                    drawNodes(svg, graphAttack);

                    var g = svg.append("g")
                            .attr("transform", "translate(" + (wSVGPreview - 75 - 5) + "," + 5 + ")");

                    var button = d3.select(svg.node().parentNode).select("div").append("button")
                            .style("width", "75px")
                            .style("height", "25px")
                            .style("float", "right")
                            .html("Start (" + graphAttack.length + ")")
                            .on("click", function () {
                                svg.selectAll(".linePreviewAttack").remove();
                                animationArcs(svg, graphAttack);
                                //d3.event.stopPropagation();
                            });

                    var buttonRP = d3.select(svg.node().parentNode).select("div").append("button")
                            .style("width", "150px")
                            .style("height", "25px")
                            .style("float", "left")
                            .html("View Response Plan")
                            .on("click", function () {
                                drawResponsePlan(indexOfPreview);
                            });

                    /* g.append("text")
                     .attr("cursor","default")
                     .attr("dy", 20)
                     .style("text-anchor", "middle")
                     .attr("dx", 35)
                     .text(graphAttack.length)
                     .on("click", function(){
                     svg.selectAll(".linePreviewAttack").remove();
                     //var previewGraphAttack=svg.selectAll("#previewNodes");
                     animationArcs(svg,graphAttack);
                     d3.event.stopPropagation();
                     });*/
                });
            }

            /**
             * Draws list of mitigation actions for an attack
             * @param {Number} indexOfPreview Number of preview to draw
             */
            function drawResponsePlan(indexOfPreview) {

                d3.json("response plan/RP" + indexOfPreview + ".json", function (source) {

                    var rows = [];

                    source.responseplan.forEach(function (d) {
                        var name = d.mitigation.name;
                        var id = d.mitigation.ID;
                        rows.push({
                            name: name,
                            id: id
                        });
                    });

                    if (!d3.select('#responsePlanList').empty()) {
                        d3.select('#responsePlanList').remove();
                    }

                    var div = sideMenu.append("div")
                            .attr("id", "responsePlanList")
                            .attr("width", width)
                            .style("height", (h - height - hBottomMenu - sizeLabel - 35) + "px");

                    var table = div.append("table")
                            .attr("id", "responsePlanTable");
                    thead = table.append("thead");
                    tbody = table.append("tbody");
                    thead.append("th").text("ID");
                    thead.append("th").text("Name");

                    var tr = tbody.selectAll("tr")
                            .data(rows)
                            .enter().append("tr");
                    tr.selectAll("td")
                            .data(function (d) {
                                return [d.id, d.name];
                            })
                            .enter().append("td")
                            .text(function (d) {
                                return d;
                            });
                })
            }

            function drawArcs(svgPreview, list) {
                svgPreview.selectAll(".path")
                        .data(list)
                        .enter()
                        .append("path")
                        .attr("class", "linePreviewAttack")
                        .attr("marker-end", "url(#preview)")
                        .attr("d", transformArc);
            }

            function animationArcs(svgPreview, list) {
                var delay = -1000;
                svgPreview.selectAll(".path")
                        .data(list)
                        .enter()
                        .append("path")
                        .attr("class", "linePreviewAttack")
                        .attr("marker-end", "url(#preview)")
                        .attr("d", function (d) {
                            var s = svgPreview.selectAll("#previewNodes").filter(function (e) {
                                return e.name == d.s.name;
                            });
                            var dx = s.attr("cx"),
                                    dy = s.attr("cy"),
                                    dr = Math.sqrt(dx * dx + dy * dy);
                            return "M" +
                                    dx + "," +
                                    dy + "A" +
                                    dr + "," + dr + " 0 0,1 " +
                                    dx + "," +
                                    dy;
                        })
                        .transition()
                        .duration(1000)
                        .delay(function () {
                            delay = delay + 1000;
                            return delay;
                        })
                        .attr("d", function (d) {
                            var s = svgPreview.selectAll("#previewNodes").filter(function (e) {
                                return e.name == d.s.name;
                            });
                            var t = svgPreview.selectAll("#previewNodes").filter(function (e) {
                                return e.name == d.t.name;
                            });
                            var px1SVG = s.attr("cx");
                            var py1SVG = s.attr("cy");
                            var px2SVG = t.attr("cx");
                            var py2SVG = t.attr("cy");
                            var dx = px2SVG - px1SVG,
                                    dy = py2SVG - py1SVG,
                                    dr = Math.sqrt(dx * dx + dy * dy);
                            return "M" +
                                    px1SVG + "," +
                                    py1SVG + "A" +
                                    dr + "," + dr + " 0 0,1 " +
                                    px2SVG + "," +
                                    py2SVG;
                        });
            }

            function transformArc(d) {
                var lat1 = 0;
                var long1 = 0;
                var lat2 = 0;
                var long2 = 0;
                originalPos.forEach(function (e) {
                    if (e.name == d.s.name) {
                        lat1 = e.x;
                        long1 = e.y;
                    }
                    if (e.name == d.t.name) {
                        lat2 = e.x;
                        long2 = e.y;
                    }
                })

                var x1 = lat1 - w / 5;
                var y1 = long1;
                var x2 = lat2 - w / 5;
                var y2 = long2;
                //now it need W and H of the map, and W and H of the svg of the preview and map the nodes from the map to the svg
                //the formula for the mapping are rx= x/wMap ry=y/hMap ----> pxSVG = wSVGPreview*rx pySVG = hSVGPreview*ry
                var rx1 = x1 / wMap;
                var ry1 = y1 / hMap;
                var px1SVG = wSVGPreview * rx1;
                var py1SVG = hSVGPreview * ry1;
                var rx2 = x2 / wMap;
                var ry2 = y2 / hMap;
                var px2SVG = wSVGPreview * rx2;
                var py2SVG = hSVGPreview * ry2;
                var dx = px2SVG - px1SVG,
                        dy = py2SVG - py1SVG,
                        dr = Math.sqrt(dx * dx + dy * dy);
                return "M" +
                        px1SVG + "," +
                        py1SVG + "A" +
                        dr + "," + dr + " 0 0,1 " +
                        px2SVG + "," +
                        py2SVG;
            }

            function drawNodes(svgPreview, list) {
                var nodelist = [];
                var index = 0;
                var sourceTarget = [];
                var source = [];
                var target = [];
                list.forEach(function (d) {
                    if (index == 0)
                        nodelist.push(d.s);
                    nodelist.push(d.t);
                    index++;
                });
                sourceTarget.push(nodelist[0]);
                sourceTarget.push(nodelist[nodelist.length - 1]);
                source.push(nodelist[0]);
                target.push(nodelist[nodelist.length - 1]);
                //drawing of the normal node
                svgPreview.selectAll(".circle")
                        .data(nodelist)
                        .enter()
                        .append("circle")
                        .attr("id", "previewNodes")
                        .attr("cx", function (d) {
                            return calculateX(d);
                        })
                        .attr("cy", function (d) {
                            return calculateY(d);
                        })
                        .attr("r", 3)
                        .style("fill", "white");
                /*	//source and target
                 svgPreview.selectAll(".circle")
                 .data(sourceTarget)
                 .enter()
                 .append("circle")
                 .attr("id","previewNodesST")
                 .attr("cx", function(d){
                 return calculateX(d);
                 })
                 .attr("cy", function(d){
                 return calculateY(d);
                 })
                 .attr("r", 5)
                 .style("fill","white");
                 */

                //source
                var r = svgPreview.selectAll(".rect")
                        .data(source)
                        .enter()
                        .append("rect")
                        .attr("id", "previewNodesST")
                        .attr("width", 10)
                        .attr("height", 10)
                        .style("fill", "white")
                        .attr("transform", function (d) {
                            return "translate(" + (calculateX(d) - 10 / 2) + "," + (calculateY(d) - 10 / 2) + ")"
                        });
                //target
                var r = svgPreview.selectAll(".rect")
                        .data(target)
                        .enter()
                        .append("rect")
                        .attr("id", "previewNodesST")
                        .attr("width", 10)
                        .attr("height", 10)
                        .style("fill", "white")
                        .attr("transform", function (d) {
                            return "translate(" + (calculateX(d) - 10 * Math.sqrt(2) / 2) + "," + calculateY(d) + ")rotate(-45)"
                        });
                svgPreview.selectAll(".circle")
                        .data(sourceTarget)
                        .enter()
                        .append("circle")
                        .attr("r", 2)
                        .attr("cx", function (d) {
                            return calculateX(d);
                        })
                        .attr("cy", function (d) {
                            return calculateY(d);
                        })
                        .style("fill", "black");
            }

            function calculateX(d) {
                var lat = d.x;
                var googleCoord = 0;
                originalPos.forEach(function (e) {
                    if (e.name == d.name)
                        googleCoord = e.x;
                })
                var x = googleCoord - w / 5;
                var rx = x / wMap;
                var pxSVG = wSVGPreview * rx;
                return pxSVG;
            }

            function calculateY(d) {
                var l = d.y;
                var googleCoord = 0;
                originalPos.forEach(function (e) {
                    if (e.name == d.name)
                        googleCoord = e.y;
                })

                var y = googleCoord;
                var ry = y / hMap;
                var pySVG = hSVGPreview * ry;
                return pySVG;
            }

            function createChart(json, x) {
                var index = 0, i = 0;
                var graphAttack = [], lines = [], tableAttack = d3.select(".tableAttack");
                //draw graph attacck and donut chart


                flagTable = 1;
                //draw donut and graph attack
                d3.json(json, function (source) {
                    var yOffset = 0;
                    var i = 0;
                    var svgTable = d3.select("#svgTable_" + x);
                    if (svgTable[0][0] == null) {

                        var svgTable = tableAttack.append("svg")
                                .attr("id", "svgTable_" + x)
                                .attr("width", tableAttack.style("width"))
                                .attr("height", (parseInt(radius * 0.1) + 1) * source.attack.length);
                    }

                    source.attack.forEach(function (d) {
                        var s_attack = source.attack[i++];
                        var g1 = svgTable.append("g")
                                .attr("transform", "translate(" + radius / 8 + "," + yOffset + ")")
                                .attr("id", "idGTable" + getSubnet(s_attack.source.name).replace(/\./g, "_")) //id will be #idGTable192_168_1
                                .on("mouseover", function () {
                                    var node = d3.selectAll(".node").filter(function (e) {
                                        return e.name == s_attack.source.name;
                                    });
                                    node.select("circle")
                                            .transition()
                                            .duration(1000)
                                            .attr("r", 9)
                                            .attr("stroke", "#ff0")
                                            .style("fill", "#ff0")
                                            .each("end", function () {
                                                node.select("circle").transition()
                                                        .duration(500)
                                                        .attr("r", 9)
                                                        .attr("stroke", "#ff0")
                                                        .style("fill", "#3d3d3d")
                                                        .attr("stroke-width", "2px")
                                            });
                                    //animation for normal nodes
                                    d3.select(".bottomMenu").selectAll("#previewNodes").filter(function (d) {
                                        return d.name == s_attack.source.name;
                                    })
                                            .transition()
                                            .duration(1000)
                                            .attr("r", 5)
                                            .style("fill", "yellow")
                                            .each("end", function () {
                                                d3.select(this)
                                                        .transition()
                                                        .duration(1000)
                                                        .attr("r", 3);
                                            });
                                    //animation for source and target nodes
                                    d3.select(".bottomMenu").selectAll("#previewNodesST").filter(function (d) {
                                        return d.name == s_attack.source.name;
                                    })
                                            .transition()
                                            .duration(1000)
                                            .attr("r", 7)
                                            .style("fill", "yellow")
                                            .each("end", function () {
                                                d3.select(this)
                                                        .transition()
                                                        .duration(1000)
                                                        .attr("r", 5);
                                            });
                                })
                                .on("mouseout", function () {
                                    var node = d3.selectAll(".node").filter(function (e) {
                                        return e.name == s_attack.source.name;
                                    });
                                    node.select("circle")
                                            .transition()
                                            .duration(500)
                                            .attr("r", 7)
                                            .style("fill", "#3d3d3d")
                                            .attr("stroke-width", "0px");
                                    //set back normal nodes
                                    d3.select(".bottomMenu").selectAll("#previewNodes").filter(function (d) {
                                        return d.name == s_attack.source.name;
                                    })
                                            .transition()
                                            .duration(1000)
                                            .attr("r", 3)
                                            .style("fill", "white");
                                    //set back source and target nodes
                                    d3.select(".bottomMenu").selectAll("#previewNodesST").filter(function (d) {
                                        return d.name == s_attack.source.name;
                                    })
                                            .transition()
                                            .duration(1000)
                                            .attr("r", 5)
                                            .style("fill", "white");
                                })
                                .on("click", function () {
                                    var previousArcs = true;
                                    var id = d3.select(d3.select(this).node().parentNode).attr("id").match(/[0-9]+/)[0];
                                    //arcs
                                    var remainAttackArcs = d3.selectAll(".lineStaticAttack");
                                    //this one shows only the outgoing arcs
                                    /*  var outgoingAttackArcs = d3.selectAll(".lineStaticAttack").filter( function(d){ //outgoing arcs
                                     return d.source.name == s_attack.source.name;
                                     }); */
                                    //this one shows the previous arcs too
                                    var outgoingAttackArcs = d3.selectAll("#lineStaticAttack" + id).filter(function (d) { //outgoing arcs
                                        if (d.source.name == s_attack.source.name) {
                                            previousArcs = false;
                                            return true;
                                        }
                                        return (d.source.name != s_attack.source.name) && previousArcs;
                                    });
                                    //instantiate
                                    var remainInstantiateAttackArcs = d3.selectAll(".lineInstantiateAttack");
                                    var outgoingInstantiateAttackArcs = d3.selectAll("#lineInstantiateAttack" + id).filter(function (d) { //outgoing arcs
                                        if (d.source.name == s_attack.source.name) {
                                            previousArcs = false;
                                            return true;
                                        }
                                        return (d.source.name != s_attack.source.name) && previousArcs;
                                    });
                                    //iinks
                                    var remainLinks = d3.selectAll(".line");
                                    var outgoingLinks = d3.selectAll(".line").filter(function (d) { //outgoing arcs
                                        return (d.source.name == s_attack.source.name) || (d.target.name == s_attack.source.name);
                                    });
                                    if (lastClickedNode != s_attack.source.name || flagClickedNode == 0) {
                                        remainAttackArcs.transition().duration(1000).style("opacity", 0);
                                        remainInstantiateAttackArcs.transition().duration(1000).style("opacity", 0);
                                        outgoingAttackArcs.transition().duration(1000).style("opacity", 1);
                                        outgoingInstantiateAttackArcs.transition().duration(1000).style("opacity", 1);
                                        remainLinks.transition().duration(1000).style("opacity", 0);
                                        outgoingLinks.transition().duration(1000).style("opacity", 1);
                                        //restore the border of the other cells
                                        d3.select(".tableAttack").selectAll("rect").attr("stroke-width", "0px");
                                        //color the border of the cell
                                        var rect = g1.select("rect")
                                                .attr("stroke", "#ff0")
                                                .attr("stroke-width", "1px");
                                        //set the flag
                                        flagClickedNode = 1;
                                    }
                                    else {
                                        //if the node is pressed
                                        outgoingLinks.transition().duration(1000).style("opacity", 0.2);
                                        remainLinks.transition().duration(1000).style("opacity", 0.2);
                                        remainAttackArcs.transition().duration(1000).style("opacity", 1);
                                        remainInstantiateAttackArcs.transition().duration(1000).style("opacity", 1);
                                        //color the border of the cell
                                        var rect = g1.select("rect")
                                                .attr("stroke-width", "0px");
                                        //set the flag
                                        flagClickedNode = 0;
                                    }
                                    lastClickedNode = s_attack.source.name;
                                });
                        g1.append("rect")
                                .attr("width", radius / 2 + "px")
                                .attr("height", radius * 0.1 + "px")
                                .attr("fill", function () {
                                    return color(getSubnet(s_attack.source.name));
                                });
                        g1.append("text")
                                .attr("dy", radius * 0.1 / 1.5)
                                .style("text-anchor", "middle")
                                .attr("dx", radius / 4)
                                .text(function () {
                                    return s_attack.source.name;
                                });
                        yOffset += parseInt(radius * 0.1) + 1;
                        graphAttack.push(s_attack.source.name);
                    });
                });
            }

            function createGraph(json, x, type) {
                //reset all lines
                d3.selectAll(".line").style("opacity", 0.2);
                var index = 0,
                        graphAttack = [],
                        lines = [];
                d3.json(json, function (source) {
                    var i = 0;
                    source.attack.forEach(function (d) {
                        graphAttack.push(d.source.name);
                    });
                    while (index < graphAttack.length) {
                        var x1 = graphAttack[index++];
                        if (index + 1 > graphAttack.length)
                            break;
                        var x2 = graphAttack[index];
                        var s;
                        var t;
                        totalNode.forEach(function (d) {

                            if (d.name == x1)
                                s = d;
                            if (d.name == x2)
                                t = d;
                        })
                        lines.push({
                            source: s,
                            target: t
                        })
                    }

                    var path = layer.append("svg:g")
                            .selectAll("path")
                            .data(lines)
                            .enter().append("svg:path")
                            .attr("d", function (d) {

                                var d1 = new google.maps.LatLng(d.source.x, d.source.y);
                                var d2 = new google.maps.LatLng(d.target.x, d.target.y);
                                d1 = projection.fromLatLngToDivPixel(d1);
                                d2 = projection.fromLatLngToDivPixel(d2);
                                var x1 = d1.x + svgshifting;
                                var y1 = d1.y + svgshifting;
                                var x2 = d2.x + svgshifting;
                                var y2 = d2.y + svgshifting;
                                var dx = x2 - x1,
                                        dy = y2 - y1,
                                        dr = Math.sqrt(dx * dx + dy * dy);
                                return "M" +
                                        x1 + "," +
                                        y1 + "A" +
                                        dr + "," + dr + " 0 0,1 " +
                                        x2 + "," +
                                        y2;
                            })
                            .attr("class", function () {
                                if (type == 0) //static attack graph
                                    return "lineStaticAttack";
                                else
                                    return "lineInstantiateAttack";
                            })
                            .attr("id", function () {
                                if (type == 0) //static attack graph
                                    return "lineStaticAttack" + x;
                                else
                                    return "lineInstantiateAttack" + x;
                            })
                            .style("stroke-width", function () {
                                if (type == 0) { //static attack graph
                                    //function that return the tickness based on the probability of the attack path
                                    //stroke-width has to go from 1 to 6, the probability from 0 to 1
                                    var p = source.probability,
                                            minstroke = 1,
                                            maxstroke = 6;
                                    if (p == 0)
                                        return 0;
                                    return (p * (maxstroke - minstroke)) + minstroke;
                                }
                                else
                                    return 6;
                            })
                            .attr("marker-end",
                                    function () {
                                        if (type == 0) //static attack graph
                                            return "url(#end)";
                                        else
                                            return "url(#instantiate)";
                                    });
                });
            }

            function getSubnet(s) {
                //console.log(s.match(/[0-9]*\.[0-9]*\.[0-9]*/)[0]);
                return s.match(/[0-9]*\.[0-9]*\.[0-9]*/)[0];
            }

            function shiftRect(s) {
                var table = d3.selectAll("#idGTable" + s.replace(/\./g, "_"))
                        .transition()
                        .duration(1000)
                        .attr("transform", function () {
                            //console.log(this.getAttribute("transform"));
                            var array = this.getAttribute("transform").split(",");
                            //console.log(array);
                            var y = array[1].split(")")[0];
                            //console.log(y);
                            return "translate(0," + y + ")";
                        });
                //add border
                table.selectAll("rect")
                        .attr("stroke-width", "1px")
                        .attr("stroke", "#ff0");
            }

            function restoreSiftedRect(s) {
                var table = d3.selectAll("#idGTable" + s.replace(/\./g, "_"))
                        .transition()
                        .duration(1000)
                        .attr("transform", function () {
                            //console.log(this.getAttribute("transform"));
                            var array = this.getAttribute("transform").split(",");
                            //console.log(array);
                            var y = array[1].split(")")[0]; // y =,230
                            //console.log(y);
                            return "translate(" + radius / 8 + "," + y + ")";
                        });
                table.selectAll("rect")
                        .attr("stroke-width", "0px");
            }

            function drawDonutChart() {
                var radius = Math.min(width, height) / 1.5,
                        graphAttack = [],
                        lines = [];
                var arc = d3.svg.arc()
                        .outerRadius(radius - wSideMenu * 0.23)
                        .innerRadius(radius - wSideMenu * 0.28);
                var arcOver = d3.svg.arc()
                        .outerRadius(radius - wSideMenu * 0.2)
                        .innerRadius(radius - wSideMenu * 0.31);
                var arcAttack = d3.svg.arc()
                        .outerRadius((radius - wSideMenu * 0.275) - 2)
                        .innerRadius(radius - wSideMenu * 0.32);
                /*var arcAttack = d3.svg.arc()
                 .outerRadius(radius - wSideMenu * 0.175)
                 .innerRadius(radius - wSideMenu * 0.275);*/

                var pie = d3.layout.pie()
                        .sort(null)
                        .value(function (d) {
                            return d.size;
                        });
                var tableAttack = sideMenu.append("div")
                        .attr("class", "tableAttack")
                        .style("left", (wSideMenu / 3 - (radius / 8)) + "px")
                        .style("top", sizeLabel + height * 0.4 / 2 + "px")
                        .style("width", 5 * radius / 8 + "px") //radius/2 for rect lenght + radius/8 for shifting when mouseover on arc
                        .style("height", height * 0.6 + "px")
                        .style("max-height", height * 0.6 + "px");
                var svg = sideMenu.append("svg")
                        .attr("id", "donutChart")
                        .attr("width", width)
                        .attr("height", height)
                        .append("g")
                        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
                sideMenu.append("button")
                        .style("width", 75 + "px")
                        .style("height", 25 + "px")
                        .text("Reset")
                        .on("click", function () {
                            location.reload();
                        });
                var g = svg.selectAll(".arc")
                        .data(pie(subnetList))
                        .enter().append("g")
                        .attr("class", "arc")
                        .on("mouseover", function (d) {
                            var node = d3.selectAll(".node").filter(function (e) {
                                return d.data.subnet == e.subnet;
                            });
                            node.selectAll("circle").transition()
                                    .duration(500)
                                    .style("fill", function () {
                                        return color(d.data.subnet);
                                    })
                                    .attr("r", 9)
                                    .attr("stroke", "#ff0")
                                    .attr("stroke-width", "2px");
                            var edge = d3.selectAll(".line").filter(function (e) {
                                return (e.source.subnet == d.data.subnet) || (e.target.subnet == d.data.subnet);
                            })
                                    .transition()
                                    .duration(500)
                                    .style("opacity", 1)
                                    .style("stroke", function () {
                                        return color(d.data.subnet)
                                    });
                            /* 
                             if(d3.select(".tableAttack").selectAll("svg")[0].length>0){
                             svg.style("display","none");
                             reDrawDonut()
                             }*/
                        })
                        .on("mouseout", function (d) {
                            var node = d3.selectAll(".node").filter(function (e) {
                                return d.data.subnet == e.subnet;
                            });
                            node.selectAll("circle").transition()
                                    .duration(500)
                                    .style("fill", "#3d3d3d")
                                    .attr("r", 7)
                                    .attr("stroke-width", "0px");
                            var edge = d3.selectAll(".line").filter(function (e) {
                                return (e.source.subnet == d.data.subnet) || (e.target.subnet == d.data.subnet);
                            })
                                    .transition()
                                    .duration(500)
                                    .style("opacity", 0.2)
                                    .style("stroke", "#000");
                        });
                g.append("path")
                        .attr("d", arc)
                        .style("fill", function (d) {
                            return color(d.data.subnet)
                        })
                        .on("mouseover", function (d) {
                            var thisArc = d3.select(this);
                            var a = thisArc[0][0];
                            var attackNode = d3.select(".tableAttack").selectAll("svg").filter(function (e) {
                                return d3.select(this).attr("display") != "none";
                            });
                            attackNode = attackNode.selectAll("#idGTable" + d.data.subnet.replace(/\./g, "_"))
                            // var ratio=1;
                            // if(attackNode[0]>0)
                            //ratio=attackNode[0].length/d.value;

                            if (attackNode.length != 0) {
                                if (attackNode[0].length != 0) {
                                    var ratio = 1 - (attackNode[0].length / d.value);
                                    var initArc = d3.svg.arc().startAngle(a.__data__.startAngle + (a.__data__.endAngle - a.__data__.startAngle) * ratio).endAngle(a.__data__.endAngle).outerRadius((radius - wSideMenu * 0.2) + 2)
                                            .innerRadius((radius - wSideMenu * 0.2) + 2);
                                    var endArc = d3.svg.arc().startAngle(a.__data__.startAngle + (a.__data__.endAngle - a.__data__.startAngle) * ratio).endAngle(a.__data__.endAngle).outerRadius((radius - wSideMenu * 0.2) + 2)
                                            .innerRadius(radius - wSideMenu * 0.175);
                                    var data = [];
                                    data.push({
                                        init: initArc,
                                        end: endArc,
                                        startAngle: a.__data__.startAngle,
                                        endAngle: a.__data__.endAngle,
                                        r: ratio
                                    })

                                    d3.select(d3.select(this).node().parentNode).selectAll(".path")
                                            .data(data)
                                            .enter()
                                            .append("path")
                                            .style("fill", function () {
                                                return d3.rgb(color(d.data.subnet)).darker(1);
                                            })
                                            .transition()
                                            .duration(1)
                                            .attr("d", initArc)
                                            .attr("id", "tempArc")
                                            .each("end", function (e) {
                                                d3.select(this).transition().duration(1000).attr("d", e.end);
                                            });
                                }
                            }
                            //var attackedNode=d3.selectAll("#idGTable"+d.data.subnet.replace(/\./g, "_"))[0].length;

                            //increase size arc
                            d3.select(this).transition()
                                    .duration(1000)
                                    .attr("d", arcOver);
                            //shift rect of the same color
                            shiftRect(d.data.subnet); //and add yellow border too
                            //show lines of the nodes


                        })
                        .on("mouseout", function (d) {
                            var tempArc = d3.select(d3.select(this).node().parentNode).select("#tempArc");
                            var a = tempArc[0][0];
                            var attackNode = d3.select(".tableAttack").selectAll("svg").filter(function (e) {
                                return d3.select(this).attr("display") != "none";
                            });
                            attackNode = attackNode.selectAll("#idGTable" + d.data.subnet.replace(/\./g, "_"))
                            //var attackNode=d3.select(".tableAttack").select("svg").selectAll("#idGTable"+d.data.subnet.replace(/\./g, "_"));
                            //var ratio=1;
                            if (a != null) {
                                var ratio = 1 - (attackNode[0].length / d.value);
                                var initArc = d3.svg.arc().startAngle(a.__data__.startAngle + (a.__data__.endAngle - a.__data__.startAngle) * ratio).endAngle(a.__data__.endAngle).outerRadius((radius - wSideMenu * 0.2) + 2)
                                        .innerRadius((radius - wSideMenu * 0.2) + 2);
                                tempArc.transition().duration(500).attr("d", initArc).each("end", function () {

                                    d3.select(d3.select(this).node().parentNode).selectAll("#tempArc").remove();
                                });
                            }
                            //restore size arc
                            d3.select(this).style("fill", color(d.data.subnet)).transition()
                                    .duration(1000)
                                    .attr("d", arc);
                            //restore shifted rect of the same color
                            restoreSiftedRect(d.data.subnet);
                            //restore old lines
                        });
                g.append("text")
                        .attr("transform", function (d) {
                            return "translate(" + arc.centroid(d) + ")";
                        })
                        .attr("dy", ".35em")
                        .style("text-anchor", "middle")
                        .style("pointer-events", "none")
                        .html(function (d) {
                            return d.data.subnet;
                        });
                g.append("text")
                        .style("pointer-events", "none")
                        .attr("transform", function (d) {
                            return "translate(" + arc.centroid(d) + ")";
                        })
                        .attr("dy", "1.35em")
                        .style("text-anchor", "middle")
                        .html(function (d) {
                            return d.value + "/" + totalNode.length;
                        });
            }

            function removeGraphAndChart(index) {
                //reset all lines
                d3.selectAll(".line").style("opacity", 0.2)
                layer.selectAll("#lineStaticAttack" + index).remove();
                d3.select("#svgTable_" + index).remove();
            }

            function reactive() {
                if (mode == 0 && likelihoodRank.length > 0) {
                    d3.selectAll(".lineStaticAttack").remove();
                    d3.select(".tableAttack").selectAll("svg").remove();
                    d3.selectAll(".line").style("opacity", 0.2);
                    d3.select(".bottomMenu").selectAll(".attackPreview").style("border-color", "white");
                    queueSVG = [];
                    var index = likelihoodRank[0].id;
                    var j = "json attack/attack" + index + ".json";
                    createChart(j, index);
                    createGraph(j, index, 1); // 1 means is an istantiate graph
                    d3.select("#attackPreview_" + index).style("border-color", "#f00")
                }
                else {
                    if (likelihoodRank.length > 0) {
                        if (likelihoodRank[0].id != idInstantiated) {
                            idInstantiated = likelihoodRank[0].id;
                            d3.selectAll(".lineStaticAttack").remove();
                            d3.selectAll(".lineInstantiateAttack").remove();
                            d3.select(".tableAttack").selectAll("svg").remove();
                            d3.selectAll(".line").style("opacity", 0.2);
                            d3.select(".bottomMenu").selectAll(".attackPreview").style("border-color", "white");
                            //d3.select(".bottomMenu").style("pointer-events","none");
                            //d3.select(".bottomMenuLabel").style("display","none");
                            queueSVG = [];
                            var j = "json attack/attack" + idInstantiated + ".json";
                            createChart(j, idInstantiated);
                            createGraph(j, idInstantiated, 1); // 1 means is an istantiate graph
                            d3.select("#attackPreview_" + idInstantiated).style("border-color", "#f00")
                        }
                    }
                }
                mode = 1;
            }

            function proactive() {
                //d3.select(".bottomMenu").style("pointer-events","initial");
                d3.selectAll(".line").style("opacity", 0.2);
                d3.selectAll(".lineInstantiateAttack").remove();
                d3.selectAll(".attackPreview").style("border-color", "#fff");
                d3.select(".tableAttack").selectAll("svg").remove();
                mode = 0;
            }

            function drawFunc(indexOfPreview) {

                $("<div style=\"width:" + wAttackPreview + "px; height:" + hBottomMenu + "px;\" id=\"attackPreview_" + indexOfPreview + "\" class=\"attackPreview\"><div style=\"position: absolute; width:" + wAttackPreview + "px; height:" + hPreviewDiv + "px;\"></div><svg style=\"width:" + wAttackPreview + "px; height:" + hSVGPreview + "px;\" class=\"SVGPreview\"></svg></div>").prependTo(".bottomMenu");
                var svgPreview = d3.select("#attackPreview_" + indexOfPreview).select("svg");
                var json = "json attack/attack" + indexOfPreview + ".json";
                //update likelihood array
                d3.json(json, function (source) {
                    var o = {id: indexOfPreview, p: source.probability};
                    if (likelihoodRank.length == 0) {
                        likelihoodRank.push(o);
                    }
                    else {
                        var i = 0;
                        var position = -1;
                        while (i < likelihoodRank.length) {
                            var p = likelihoodRank[i].p;
                            if (source.probability >= p) {
                                position = i;
                                break;
                            }
                            i++;
                        }
                        if (position == -1) {
                            likelihoodRank.push(o);
                        }
                        else {
                            likelihoodRank.splice(position, 0, o);
                        }
                    }

                    //if we are in reactive mode
                    if (mode == 1)
                        reactive();
                })



                svgPreview.on("click", function () {

                    //delete temporary accumulate arcs
                    d3.selectAll("#tempArc").remove();
                    //if we are in proactive mode we add the graphs on the map
                    if (mode == 0) {
                        var div = d3.select(d3.select(this).node().parentNode);
                        var index = (div.attr("id")).match(/[0-9]+/)[0];
                        var j = "json attack/attack" + index + ".json";
                        if (div.style("border-top-color") == "rgb(255, 255, 255)") {
                            div.style("border-color", "yellow");
                            if (queueSVG.length == 0) {
                                createChart(j, index);
                                createGraph(j, index, 0);
                            }
                            else {
                                //set last svg display property to none 
                                var last = queueSVG[queueSVG.length - 1];
                                d3.select("#svgTable_" + last).attr("display", "none");
                                //add new chart
                                createChart(j, index);
                                createGraph(j, index, 0);
                            }
                            queueSVG.push(index);
                        }
                        else {
                            div.style("border-color", "white");
                            removeGraphAndChart(index);
                            layer.selectAll("#lineStaticAttack" + index).remove();
                            //delete from list
                            var indexOfSVG = queueSVG.indexOf(index);
                            queueSVG.splice(indexOfSVG, 1);
                            //if the list is not empty, set display property of the last svg to initial
                            if (queueSVG.length > 0) {
                                var last = queueSVG[queueSVG.length - 1];
                                d3.select("#svgTable_" + last).attr("display", "initial");
                            }
                        }

                    }
                });
                //delete preview elements
                drawPreview(svgPreview, json, indexOfPreview);
            }


        </script>

    </body>

</html>