<!DOCTYPE html>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
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
            <input id="pro" type="radio" name="mode" value="proactive" onClick="proactive()">Proactive
            <br>
            <input id="re" type="radio" name="mode" value="reactive" onClick="reactive(1)" checked>Reactive
        </form> 



        <!--remove the elements in the map where -->
        <div id="map" style="position: absolute"></div>

        <!-- <button type="button" class="button" id="btn" onclick="changeMode()">Proactive</button>-->
        <script type="text/javascript">

            // Create the Google Map
            var map = new google.maps.Map(d3.select("#map").node(), {
                zoom: 11,
                center: new google.maps.LatLng(41.859307, 12.596115), //center of rome
                mapTypeId: google.maps.MapTypeId.ROADMAP
                        //draggable : false
            });
            var currentPreviewIndex = 0;
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

//                var lineStaticAttacks = d3.selectAll(".lineStaticAttack");
//
//                var array = lineStaticAttacks[0];
//                var arrayID = [];
//                //get the relative number of the drawn arcs
//                array.forEach(function (d) {
//                    var id = d.id.match(/[0-9]+/)[0];
//                    if (arrayID.indexOf(id) == -1)
//                        arrayID.push(id);
//                });
//                //console.log(arrayID);
//                lineStaticAttacks.remove();
//
//                //redraw the arcs
//                arrayID.forEach(function (d) {
//                    var json = "json attack/attack" + d + ".json";
//                    createGraph(json, d, 0);
//                });
//
//                //instantiate version
//                var attack = d3.selectAll(".lineInstantiateAttack");
//                //console.log(".lineInstantiateAttack array: ");
//                //console.log(attack);
//                var array = attack[0];
//                var arrayID = [];
//                //get the relative number of the drawn arcs
//                array.forEach(function (d) {
//                    var id = d.id.match(/[0-9]+/)[0];
//                    if (arrayID.indexOf(id) == -1)
//                        arrayID.push(id);
//                });
//
//                attack.remove();
//                //delete previews
//                //d3.selectAll(".attackPreview").selectAll("svg").selectAll("path").remove();
//                // d3.selectAll(".attackPreview").selectAll("svg").selectAll("circle").remove();
//                //d3.selectAll(".attackPreview").selectAll("svg").selectAll("rect").remove();
//                //redraw the arcs
//                arrayID.forEach(function (d) {
//                    var json = "json attack/attack" + d + ".json";
//                    createGraph(json, d, 1);
//                });
//
//
//                var attack = d3.selectAll(".lineInstantiateOnGoingAttack");
//                var array = attack[0];
//                var arrayID = [];
//                //get the relative number of the drawn arcs
//                array.forEach(function (d) {
//                    var id = d.id.match(/[0-9]+/)[0];
//                    if (arrayID.indexOf(id) == -1)
//                        arrayID.push(id);
//                });
//
//                attack.remove();
//                //delete previews
//                //d3.selectAll(".attackPreview").selectAll("svg").selectAll("path").remove();
//                // d3.selectAll(".attackPreview").selectAll("svg").selectAll("circle").remove();
//                //d3.selectAll(".attackPreview").selectAll("svg").selectAll("rect").remove();
//                //redraw the arcs
//                arrayID.forEach(function (d) {
//                    var json = "json attack/attack" + d + ".json";
//                    createGraph(json, d, 1);
//                });
//
//                /*
//                 for(var i=1;i<7;i++)
//                 drawFunc(i);*/
                removeAllElements();
                for (var i = 1; i < currentPreviewIndex; ++i)
                    reactiveAlert(i, 0, 0);

                setTimeout(function () {
                    reactiveAlert(currentPreviewIndex, 300, 100);
                }, 1000);

            });
            var h = parseInt(window.innerHeight),
                    w = parseInt(window.innerWidth),
                    mode = 1, //0=proactive, 1=reactive
                    alertIndex = 0,
                    overlay = 0,
                    sideFlag = 0, //0 open, 1 hidden
                    bottomFlag = 0, //0 open, 1 hidden
                    sizeLabel = 50,
                    svgshifting = 2500,
                    borderAttackPreview = 2,
                    totalEdges = [],
                    totalNode = [],
                    alertNodes = [
                        "192.168.1.13",
                        "192.168.1.12",
                        "192.168.4.3",
                        "192.168.2.4",
                        "192.168.2.89",
                        "192.168.1.9",
                        "192.168.1.16",
                        "192.168.1.1",
                        "192.168.1.17"],
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

            var nodeRadius = 7;

            var globalAttackEvolution = 0;
            var totalAttacks = [];
            var totalResponse = [];
            var barWidth = "10px";
            var bheight = d3.scale.linear().domain([0, 10]).range([0, 50]);

            document.getElementById('re').checked = true;

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

                    //l'svg deve essere piÃ¹ grande dello schermo altrimenti taglia
                    //layer = d3.select(this.getPanes().overlayLayer)
                    layer = d3.select(this.getPanes().overlayMouseTarget)
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
                                padding = 25;

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
                        //group elements to manage alightment on links and nodes
                        //node are always in front of links
                        layer.append("g").attr("id", "links");
                        layer.append("g").attr("id", "nodes");

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
                                .attr("refX", 10)
                                .attr("refY", 0)
                                .attr("markerWidth", 4)
                                .attr("markerHeight", 10)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");

                        //marker for arrows instantiate attack
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "instantiate")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", 10)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");

                        //marker for arrows instantiateDone attack
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "instantiateDone")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 7)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");

                        d3.selectAll(".line").remove();
                        d3.selectAll(".barrier").remove();

                        var edges = layer.select("#links").selectAll(".line")
                                .data(totalEdges)
                                //.each(transformLine)
                                .enter()
                                .append("svg:path")
                                //.each(transformLine)
                                //.attr("d",transformLine)
                                .attr("d", function (d) {
                                    var d1 = new google.maps.LatLng(d.source.x, d.source.y);
                                    var d2 = new google.maps.LatLng(d.target.x, d.target.y);
                                    d1 = projection.fromLatLngToDivPixel(d1);
                                    d2 = projection.fromLatLngToDivPixel(d2);
                                    var d1x = d1.x + svgshifting;
                                    var d1y = d1.y + svgshifting;
                                    var d2x = d2.x + svgshifting;
                                    var d2y = d2.y + svgshifting;
                                    return "M" + d1x + "," + d1y + "L" + d2x + "," + d2y;
                                })
                                .attr("class", "line") //qui metteremo il peso degli archi
                                .attr("id", function (d) {
                                    return "edge" + replacePoints(d.source.name) + "-" + replacePoints(d.target.name);
                                });

                        /*var riotta=d3.select("#edge192p168p1p2-192p168p1p1");
                         var l=riotta.node().getTotalLength();
                         var p = riotta.node().getPointAtLength(1.0 * l);
                         //console.log(p);
                         layer.append("circle")
                         .attr("class","barrier")
                         .attr("cx",p.x)
                         .attr("cy",p.y)
                         .attr("r",10)
                         .style("fill","red")*/


                        var nodes = layer.select("#nodes").selectAll(".node")
                                .data(totalNode)
                                .each(transformNode)
                                .enter()
                                .append("svg:svg")
                                .each(transformNode)
                                .attr("class", "node");

                        nodes.append("circle")
                                .attr("r", nodeRadius) //possiamo cambiare la dimensione del nodo
                                .style("fill", "#3d3d3d")
                                .attr("cx", padding)
                                .attr("cy", padding);

                        nodes.append("text")
                                .attr("x", padding + 7)
                                .attr("y", padding)
                                .attr("dy", ".31em")
                                .text(function (d) {
                                    return d.name;
                                });



                        /**
                         * Fills originalPos var and returns x and y
                         * @param {type} d
                         * @returns two filled atrributes x and y
                         */
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
                            /*return d3.select(this)
                             .attr("x1", (d1.x + svgshifting))
                             .attr("y1", (d1.y + svgshifting))
                             .attr("x2", (d2.x + svgshifting))
                             .attr("y2", (d2.y + svgshifting));*/
                            var d1x = d1.x + svgshifting;
                            var d1y = d1.y + svgshifting;
                            var d2x = d2.x + svgshifting;
                            var d2y = d2.y + svgshifting;
                            return "M" + d1x + "," + d1y + "L" + d2x + "," + d2y;
                        }
                        mm++;
                    };
                };
                createSideMenu(sideMenu);
                createBottomMenu(bottomMenu);

                //donut chart

                // Bind our overlay to the map
                overlay.setMap(map);
                removeElements();
                drawDonutChart();
            });

            function drawPreviews() {

                //var time = 3000;
                if (mode == 0)
                {
                    var time = 3000;
                    for (var indexOfPreview = 1; indexOfPreview < 10; indexOfPreview++) {
                        var myVar = setTimeout("drawFunc(" + indexOfPreview + ")", time);
                        time = time + 5000;
                    }
                }
                else
                {
                    for (var indexOfPreview = 1; indexOfPreview < 10; indexOfPreview++) {
                        drawFuncReactive(indexOfPreview);
                    }
//                    
//                        var time = 0;
//                    var tt = 1000;
//                    for (var indexOfPreview = 1; indexOfPreview < 10; indexOfPreview++) {
//                        var myVar = setTimeout("drawFuncReactive(" + indexOfPreview + ")", time);
//                        //time=time+5000;
//                    }
//                    for (var indexOfPreview = 1; indexOfPreview < 10; indexOfPreview++) {
//                        var myVar = setTimeout("reactiveAlert(" + indexOfPreview + ")", tt);
//                        tt = tt + 1000;
//                    }

                }
            }

            function removeElements() {
                d3.selectAll(".gmnoprint").remove();
                d3.select(".gm-style-cc").remove();
                d3.select("a").remove();
            }

            function removeAllElements() {
                d3.selectAll(".gmnoprint").remove();
                d3.select(".gm-style-cc").remove();
                d3.select("a").remove();
                //d3.selectAll(".attackPreview").remove();
                d3.selectAll(".lineStaticAttack").remove();
                d3.selectAll(".lineInstantiateAttack").remove();
                d3.selectAll(".lineInstantiateOnGoingAttack").remove();
                d3.selectAll(".barrier").remove();
                //reset all lines
                d3.selectAll(".line").style("opacity", 0.1);
                //reset all node
                d3.selectAll(".node").selectAll("circle")
                        .style("fill", "#3d3d3d")
                        .attr("r", nodeRadius)
                        .attr("stroke", "none");
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
                        });
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
                            });
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
                    btn.text("Reactive");
                else
                    btn.text("Proactive");
            }

            function drawPreview(index, svg, json) {
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
                        });
                    });
                    graphAttack.pop();
                    drawArcs(svg, graphAttack);
                    //animationArcs(svg,graphAttack);
                    drawNodes(svg, graphAttack);



                    var button = d3.select(svg.node().parentNode).select("div").append("button")
                            .style("width", "75px")
                            .style("height", "25px")
                            .style("float", "right")
                            .html("Inspect")
                            .on("click", function () {
                                svg.selectAll(".linePreviewAttack").remove();
                                animationArcs(svg, graphAttack);
                                //d3.event.stopPropagation();
                            });

                    //legend
                    var g = svg.append("g")
                            .attr("transform", "translate(" + (wSVGPreview - 75) + "," + (hPreviewDiv + 5) + ")");

                    g.append("text")
                            .attr("class", "textPreview")
                            .text("Length: " + graphAttack.length);

                    g.append("text")
                            .attr("transform", "translate(0," + 20 + ")")
                            .attr("class", "textPreview")
                            .text("Legend:");

                    var g1 = g.append("g")
                            .attr("transform", "translate(0," + 40 + ")");

                    g1.append("text")
                            .attr("class", "textPreview")
                            .text("Source:");

                    g1.append("rect")
                            .attr("width", 10)
                            .attr("height", 10)
                            .style("fill", "white")
                            .attr("transform", function (d) {
                                return "translate(50,-10)";
                            });

                    g1.append("circle")
                            .attr("r", 2)
                            .attr("cx", 55)
                            .attr("cy", -5)
                            .style("fill", "black");

                    var g2 = g.append("g")
                            .attr("transform", "translate(0," + 60 + ")");

                    g2.append("text")
                            .attr("class", "textPreview")
                            .text("Target:");

                    g2.append("rect")
                            .attr("width", 10)
                            .attr("height", 10)
                            .style("fill", "white")
                            .attr("transform", function (d) {
                                return "translate(55,-10)rotate(45)";
                            });

                    g2.append("circle")
                            .attr("r", 2)
                            .attr("cx", 55)
                            .attr("cy", -2.5)
                            .style("fill", "black");

                    var button = d3.select(svg.node().parentNode).select("div").append("button")
                            .style("width", "100px")
                            .style("height", "25px")
                            .style("float", "right")
                            .html("Response Plan")
                            .on("click", function () {

                            });

                    d3.json("response_plan/RP" + index + ".json", function (data)
                    {
                        totalResponse[index - 1] = data;
                        var rptext = "<b>Response Plan</b> ID" + index + "<br><br>";
                        //console.log(data);
                        //console.log(data["response-plan"].length);
                        for (k = 0; k < data["response-plan"].length; k++)
                        {
                            //console.log(k);
                            nodetext = data["response-plan"][k].mitigation;
                            rptext = rptext + "<b>Action: </b>" + nodetext.name + " <b>Node: </b>" + nodetext.edge.target + "<br>";
                        }
                        //console.log(rptext);

                        //d3.select("#responseText")
                        //  .html(rptext);
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
                });

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
                            return "translate(" + (calculateX(d) - 10 / 2) + "," + (calculateY(d) - 10 / 2) + ")";
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
                            return "translate(" + (calculateX(d) - 10 * Math.sqrt(2) / 2) + "," + calculateY(d) + ")rotate(-45)";
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
                });
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
                });

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
                                                        .attr("stroke-width", "2px");
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

            function createGraph(json, attackIndex, type) { //attackIndex = likelihoodRank[0].id;
//                //reset all lines
//                d3.selectAll(".line").style("opacity", 0.1);
//                //reset all node
//                d3.selectAll(".node").selectAll("circle").style("fill", "#3d3d3d");

                var index = 0,
                        graphAttack = [],
                        lines = [];

                d3.json(json, function (source) {
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
                        });
                        lines.push({
                            source: s,
                            target: t
                        });
                    }

                    var ap = getAttackArray(lines);  //contains the attack path in the form of an array of nodes
                    var path = layer.select("#links").append("svg:g")
                            .selectAll("path")
                            .data(lines)
                            .enter()
                            .append("svg:path")
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
//                                {
//                                    //console.log(lines)
//                                    //console.log(i+"----"+globalAttackEvolution)
//                                    if ((i < globalAttackEvolution) && alertNodes[i + 1] === ap[i + 1]) {
//                                        console.log("(i < globalAttackEvolution) && alertNodes[i + 1] === ap[i + 1]");
//                                        console.log("(" + i + " < " + globalAttackEvolution + ") && " + alertNodes[i + 1] + " === " + ap[i + 1]);
//                                        return "lineInstantiateAttack";
//
//                                    }
//                                    else
                                    return "lineInstantiateOnGoingAttack";
//                                }
                            })
                            .attr("id", function () {
                                if (type == 0) //static attack graph
                                    return "lineStaticAttack" + attackIndex;
                                else
//                                {
//                                    if ((i < globalAttackEvolution) && alertNodes[i + 1] === ap[i + 1])
//                                        return "lineInstantiateAttack" + attackIndex;
//                                    else
                                    return "lineInstantiateOnGoingAttack" + attackIndex;
//                                }
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

            /**
             * Draw lineInstantiateAttack lines separately on the base on alertNodes
             * @returns {undefined}
             */
            function drawAttackGraph() {
                //let's draw lineInstantiateAttack lines separately on the base on alertNodes
                // if (type == 1) {
                d3.selectAll(".lineInstantiateAttack").remove();
                var alertedNodesList = alertNodes.slice(0, currentPreviewIndex);
                var instantiateAttackLines = [];
                if (alertedNodesList.length > 1) {
                    for (var index = 0; index < (alertedNodesList.length - 1); index++) {
                        var sourceNode;
                        var targetNode;
                        totalNode.forEach(function (d) {
                            if (d.name == alertedNodesList[index])
                                sourceNode = d;
                            if (d.name == alertedNodesList[index + 1])
                                targetNode = d;
                        });
                        instantiateAttackLines.push({
                            source: sourceNode,
                            target: targetNode
                        });
                    }
                }

                layer.select("#links").append("svg:g")
                        .selectAll("path")
                        .data(instantiateAttackLines)
                        .enter()
                        .append("svg:path")
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
                        .attr("class", "lineInstantiateAttack")
                        .attr("id", "lineInstantiateAttack" + currentPreviewIndex)
                        .style("stroke-width", 6)
                        .attr("marker-end", "url(#instantiateDone)");
                // }
            }
            /**
             * Transform oject of nodes into array on IP adresses
             * @param {type} arlines
             */
            function getAttackArray(arlines)
            {
                var result = [];
                for (i = 0; i < arlines.length; i++)
                {
                    if (i == 0)
                    {
                        result.push(arlines[i].source.name);
                        result.push(arlines[i].target.name);
                    }
                    else
                    {
                        result.push(arlines[i].target.name);
                    }
                }
                return result;
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
                        .text("Play 1")
                        .on("click", function () {
                            currentPreviewIndex++;
                            if (currentPreviewIndex == 10) {
                                removeAllElements();
                                drawPreviews();
                                currentPreviewIndex = 1;
                                d3.select(this).text("Play " + currentPreviewIndex);
                            }
                            else {
                                reactiveAlert(currentPreviewIndex, 500, 200);
                            }

                            if (currentPreviewIndex == 10)
                                d3.select(this).text("Clear");
                            else
                                d3.select(this).text("Play " + currentPreviewIndex);


                        });

                sideMenu.append("button")
                        .style("width", 75 + "px")
                        .style("height", 25 + "px")
                        .text("Play all")
                        .on("click", function () {
                            currentPreviewIndex = 1;
                            removeAllElements();
                            var tt = 1000;
                            drawPreviews();

                            for (var indexOfPreview = 1; indexOfPreview < 10; indexOfPreview++) {
                                setTimeout(function () {
                                    reactiveAlert(currentPreviewIndex, 500, 200);
                                    currentPreviewIndex++;
                                }, tt);
                                tt = tt + 2000;
                            }
                        });

                sideMenu.append("button")
                        .style("width", 75 + "px")
                        .style("height", 25 + "px")
                        .text("Reset")
                        .on("click", function () {
                            //location.reload();
                            removeAllElements();
                        });

                //Append Response Plan DIV
                sideMenu.append("div")
                        .attr("id", "responseText")
                        .style("width", wSideMenu + "px")
                        .style("height", "200px");

                //d3.select("#responseText")
                //.html("<b>Response Plan</b>");



                var responseTable = sideMenu.append("div")
                        .attr("class", "tableResponse");

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
                                        return color(d.data.subnet);
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
                            return color(d.data.subnet);
                        })
                        .on("mouseover", function (d) {
                            var thisArc = d3.select(this);
                            var a = thisArc[0][0];
                            var attackNode = d3.select(".tableAttack").selectAll("svg").filter(function (e) {
                                return d3.select(this).attr("display") != "none";
                            });
                            attackNode = attackNode.selectAll("#idGTable" + d.data.subnet.replace(/\./g, "_"));
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
                                    });

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
                            attackNode = attackNode.selectAll("#idGTable" + d.data.subnet.replace(/\./g, "_"));
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
                d3.selectAll(".line").style("opacity", 0.2);
                layer.selectAll("#lineStaticAttack" + index).remove();
                d3.select("#svgTable_" + index).remove();
            }

            function bestMatch(array, index)
            {
                //console.log("blerah "+index);
                var ordered = likelihoodRank.sort(function (a, b) {
                    return a.id - b.id;
                });
                var best = maxim(ordered, index);
                return best;
            }

            function maxim(array, index)
            {
                var max = 0;
                var id;
                for (i = 0; i < index; i++)
                {
                    //console.log("è nel max "+array[i].p+"   "+max);
                    if (+array[i].p > max)
                    {
                        max = array[i].p;
                        id = array[i].id;
                        //console.log("è nel max");
                    }
                }
                return id;
            }

            function reactive(indexOfAlert) {
                if (mode == 0 && likelihoodRank.length > 0) {
                    d3.selectAll(".lineStaticAttack").remove();
                    d3.selectAll(".lineInstantiateOnGoingAttack").remove();
                    d3.select(".tableAttack").selectAll("svg").remove();
                    d3.selectAll(".line").style("opacity", 0.2);
                    d3.select(".bottomMenu").selectAll(".attackPreview").style("border-color", "white");

                    queueSVG = [];
                    var index = likelihoodRank[0].id;
                    var j = "json attack/attack" + index + ".json";
                    createChart(j, index);
                    createGraph(j, index, 1); // 1 means is an istantiate graph
                    d3.select("#attackPreview_" + index).style("border-color", "#f00");
                }
                else {
                    if (likelihoodRank.length > 0) {
                        //if(likelihoodRank[0].id!=idInstantiated){
                        //idInstantiated=likelihoodRank[0].id;
                        //console.log(likelihoodRank+" ++++++++ "+indexOfAlert);
                        idInstantiated = bestMatch(likelihoodRank, indexOfAlert);
                        //console.log("PARAPPPAAAAAAA---- "+idInstantiated);
                        d3.selectAll(".lineStaticAttack").remove();

                        d3.selectAll(".lineInstantiateOnGoingAttack").remove();
                        d3.select(".tableAttack").selectAll("svg").remove();
                        d3.selectAll(".line").style("opacity", 0.1);
                        d3.select(".bottomMenu").selectAll(".attackPreview").style("border-color", "white");
                        d3.selectAll(".barrier").transition().attr("fill-opacity", 0.1).attr("stroke-opacity", 0.1);
                        //d3.select(".bottomMenu").style("pointer-events","none");
                        //d3.select(".bottomMenuLabel").style("display","none");
                        queueSVG = [];

                        var j = "json attack/attack" + idInstantiated + ".json";
                        createChart(j, idInstantiated);
                        createGraph(j, idInstantiated, 1); // 1 means is an istantiate graph
                        d3.select("#attackPreview_" + idInstantiated).style("border-color", "#f00");
                        //}
                    }
                }
                //playmode = 1;
            }

            function proactive() {
                //d3.select(".bottomMenu").style("pointer-events","initial");
                d3.selectAll(".line").style("opacity", 0.2);
                d3.selectAll(".node").selectAll("circle").style("fill", "#3d3d3d");
                d3.selectAll(".lineInstantiateAttack").remove();
                d3.selectAll(".attackPreview").style("border-color", "#fff");
                d3.select(".tableAttack").selectAll("svg").remove();
                mode = 0;
            }

            function drawFunc(indexOfPreview) {

                $("<div style=\"width:" + wAttackPreview + "px; height:" + hBottomMenu + "px;\" id=\"attackPreview_" + indexOfPreview + "\" class=\"attackPreview\"><div style=\"position: absolute; width:" + wAttackPreview + "px; height:" + hPreviewDiv + "px;\"></div><svg style=\"width:" + wAttackPreview + "px; height:" + hSVGPreview + "px;\" class=\"SVGPreview\"></svg></div>").prependTo(".bottomMenu");

                var divPreview = d3.select("#attackPreview_" + indexOfPreview);
                globalAttackEvolution = indexOfPreview - 1;
                //IDff
                divPreview.select("div").append("text")
                        .attr("class", "textAttackID")
                        .text("Attack ID: " + indexOfPreview)
                        .style("left", "5px")
                        .style("top", "5px");

                var svgPreview = divPreview.select("svg");
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
                    if (mode == 1) {
                        reactive(indexOfPreview);
                        var a = alertNodes.slice(0, indexOfPreview);
                        var node = d3.selectAll(".node").filter(function (e) {
                            return a.indexOf(e.name) != -1;
                        });
                        node.selectAll("circle").style("fill", "red");

                        node.filter(function (d) {
                            return d.name == alertNodes[indexOfPreview - 1];
                        }).select("circle")
                                .transition()
                                .duration(500)
                                .attr("r", 10)
                                .style("fill", "red")
                                .each("end", function () {
                                    d3.select(this)
                                            .transition()
                                            .duration(500)
                                            .attr("r", 7);
                                });
                    }
                    //blink animation
                    if (mode == 0) {
                        divPreview.transition().duration(500).style("border-color", "#fff");
                    }
                    else {
                        //console.log(idInstantiated +" ////// "+indexOfPreview)
                        if (idInstantiated === indexOfPreview) {
                            divPreview.transition().duration(500).style("border-color", "#f00");
                        }
                        else {
                            divPreview.transition().duration(500).style("border-color", "#fff");
                        }
                    }

                });
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

                drawPreview(indexOfPreview, svgPreview, json);

            }

            function replacePoints(string)
            {
                var res = "";
                for (l = 0; l < string.length; l++)
                {
                    if (string[l] === ".")
                        res = res + "_";
                    else
                        res = res + string[l];
                }
                return res;
            }


            function getNode(node)
            {
                for (k = 0; k < totalNode.length; k++)
                {
                    if (totalNode[k].name === node)
                        return totalNode[k];
                }
                console.log("(!) getNode(node): node " + node + " is not found in totalNode");
            }

            function computeBarrier(index, s, t)
            {
                var result = [];
                var activeResponse = totalResponse[index]["response-plan"];
                for (k = 0; k < activeResponse.length; k++)
                {
                    //console.log(k);
                    if ((activeResponse[k].mitigation.edge.source === s) && (activeResponse[k].mitigation.edge.target === t))
                        result.push(activeResponse[k]);
                }
                //console.log(result);
                return result;
            }

            function perimeter(indexOfPreview)
            {
                var activeNode = alertNodes[indexOfPreview - 1];
                var activeEdges = [];
                for (var k = 0; k < totalEdges.length; k++)
                {
                    if (totalEdges[k].source.name === activeNode)
                        activeEdges.push(totalEdges[k]);
                }
                //Active attack predicted edges which are then covered by barriers  

                var activeAttackEdges = [];
                for (var h = 0; h < totalAttacks.length; h++)//for all attacs
                {
                    for (var k = 0; k < totalAttacks[h].attack.length; k++)//for each attack path in attack
                    {
                        outerloop:
                                if (totalAttacks[h].attack[k].source.name === activeNode)//if attack path goes from our activeNode 
                        {
                            //we compute mitigations anyway
                            var s = totalAttacks[h].attack[k].source.name;
                            var t = totalAttacks[h].attack[k].target.name;
                            var mitigationActions = computeBarrier(h, s, t);
                            var barrierData = {
                                attackId: h,
                                barrier: mitigationActions
                            };
                            for (var i = 0; i < activeAttackEdges.length; i++) {//for all activeAttackEdges
                                if (totalAttacks[h].attack[k].target.name === activeAttackEdges[i].target.name) {//We see if there exsist the same edge in our activeAttackEdges
                                    //we only add mitigations to the existing edge
                                    activeAttackEdges[i].barrierData.push(barrierData);
                                    break outerloop; //to skip adding new new edge to activeAttackEdges
                                }
                            }
                            //if there is no edge, we add new new edge to activeAttackEdges
                            if (totalAttacks[h].attack[k].target.name != "x") { //if not the last node though
                                var o = {
                                    source: getNode(s),
                                    target: getNode(t),
                                    barrierData: [barrierData]
                                };
                                activeAttackEdges.push(o);
                            }
                        }
                    }
                }
                var maxAttacksPerEdge = 0;
                activeAttackEdges.forEach(function (d) {
                    if (d.barrierData.length > maxAttacksPerEdge)
                        maxAttacksPerEdge = d.barrierData.length;
                });
                var scaleStrokeWidth = d3.scale.linear()
                        .domain([0, maxAttacksPerEdge])
                        .range([2, 6]);

                layer.select("#links").append("svg:g")
                        .selectAll("path")
                        .data(activeAttackEdges)
                        .enter()
                        .append("svg:path")
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
                        .attr("class", "lineStaticAttack")
                        .style("stroke-width", function (d) {
                            return scaleStrokeWidth(d.barrierData.length);
                        })
                        .attr("id", "lineStaticAttack" + indexOfPreview);

                d3.selectAll(".barrier").transition().attr("fill-opacity", 0.1).attr("stroke-opacity", 0.1);

                createBarrier(activeAttackEdges);

                //black links
                var outgoingLinks = layer.selectAll(".line").filter(function (d) { //outgoing arcs
                    return (d.source.name === activeNode);
                })
                        //.style("stroke-width", "5px")
                        .style("opacity", "0.5");
            }

            function mitigationsPreview(mitigations)
            {
                var countMitigations = mitigations.length;
                var success = 0;
                for (m = 0; m < countMitigations; m++)
                {
                    if (mitigations[m].mitigation.status === "success")
                        success = success + 1;
                }
                var failed = countMitigations - success;
                var step = 10;
                var count = 1;

                d3.select("#responseText")
                        .html("<b>Barrier of Mitigation Actions</b>");

                var barlayer = d3.select("#responseText")
                        .append("svg")
                        .attr("id", "barrierDetailsArea")
                        .attr("width", "400px")
                        .attr("height", "200px")
                        .style("fill", "white");

                for (j = 0; j < mitigations.length; j++)
                {
                    if ((mitigations[j].mitigation.status == "inactive") || (mitigations[j].mitigation.status == "failed"))
                    {
                        barlayer.append("svg:rect")
                                .datum(mitigations[j].mitigation)
                                .attr("x", "5px")
                                .attr("y", function () {
                                    return count * 20;
                                })
                                .attr("width", "50px")
                                .attr("height", "20px")
                                .style("fill", "red")
                                .style("stroke", "black")
                                .style("stroke-width", "2px")
                                .on("click", function (d) {
                                    var c = parseInt(d3.select(this).attr("y"));
                                    showDetails(d, c);
                                });
                        d3.select("#barrierDetailsArea")
                                .append("text")
                                .attr("x", "70px")
                                .attr("y", function () {
                                    return count * 20 + 10;
                                })
                                .style("font-size", "10px")
                                .text("ID: " + mitigations[j].mitigation.ID + " type: " + mitigations[j].mitigation.name + " node: " + mitigations[j].mitigation.edge.target);

                        count = count + 1;
                    }
                }

                for (j = 0; j < mitigations.length; j++)
                {
                    if (mitigations[j].mitigation.status == "success")
                    {
                        barlayer.append("svg:rect")
                                .datum(mitigations[j].mitigation)
                                .attr("x", "5px")
                                .attr("y", function () {
                                    return count * 20;
                                })
                                .attr("width", "50px")
                                .attr("height", "20px")
                                .style("fill", "green")
                                .style("stroke", "black")
                                .style("stroke-width", "2px")
                                .on("click", function (d) {
                                    var c = parseInt(d3.select(this).attr("y"));
                                    showDetails(d, c);
                                });

                        d3.select("#barrierDetailsArea")
                                .append("text")
                                .attr("x", "70px")
                                .attr("y", function () {
                                    return count * 20 + 10;
                                })
                                .style("font-size", "10px")
                                .text("ID: " + mitigations[j].mitigation.ID + " type: " + mitigations[j].mitigation.name + " node: " + mitigations[j].mitigation.edge.target);

                        count = count + 1;
                    }
                }
            }

            function showDetails(data, h)
            {
                //console.log(h);
                d3.select("#barrierDetailsArea")
                        .append("text")
                        .attr("x", "70px")
                        .attr("y", function () {
                            return h + 10;
                        })
                        .style("font-size", "10px")
                        .text("ID: " + data.ID + " type: " + data.name + " node: " + data.edge.target);
            }


            /**
             * Draws barrier rectangles
             * @param {type} activeAttackEdges
             * @returns {undefined}
             */
            function createBarrier(activeAttackEdges)
            {
                for (var j = 0; j < activeAttackEdges.length; j++) {
                    var rectWidth = 12;
                    var rectHeight = 60;
                    var rectStandoff = 15;
                    var magnifierFactor = 3;
                    var smallEdgeShifting = 0;
                    //count all mitigations from all attacks together
                    var mitigations = [];
                    for (var i = 0; i < activeAttackEdges[j].barrierData.length; i++) {
                        mitigations = mitigations.concat(activeAttackEdges[j].barrierData[i].barrier);
                    }
                    //count all states of mitifation action 
                    var success = 0;
                    var failed = 0;
                    for (var m = 0; m < mitigations.length; m++)
                    {
                        if (mitigations[m].mitigation.status === "success")
                            success = success + 1;
                        if (mitigations[m].mitigation.status === "failed")
                            failed = failed + 1;
                    }
                    var inactive = mitigations.length - success - failed;

                    //lets find position data for barrier rectangles
                    var positionData;
                    layer.selectAll(".lineStaticAttack")
                            .filter(function (d) {
                                return (d.target.name === activeAttackEdges[j].target.name);
                            })
                            .each(function () {
                                var l = this.getTotalLength();
                                if (l < rectHeight * 1.9) {//if rectange doesnt fit line
                                    rectHeight = l * 0.6;
                                    rectStandoff = l * 0.10;
                                    smallEdgeShifting = 10;
                                }
                                var p1 = this.getPointAtLength(l - rectStandoff);
                                var p2 = this.getPointAtLength(l - rectHeight); // TODO: make secobd it not fixed
                                var dY = p1.y - p2.y;
                                var dX = p1.x - p2.x;
                                var angleInDegrees = (Math.atan2(dY, dX) / Math.PI * 180.0) + 90;
                                positionData = {
                                    startPoint: p1,
                                    angleInDegrees: angleInDegrees
                                };
                            });

                    var heightScale = d3.scale.linear()
                            .domain([0, mitigations.length])
                            .range([0, rectHeight]);

                    var g = layer.append("g")
                            .datum(positionData)
                            .attr("class", "barrier")
                            .attr("transform", "translate(" +
                                    (positionData.startPoint.x - rectWidth / 2) +
                                    "," + (positionData.startPoint.y) +
                                    ") rotate(" + positionData.angleInDegrees + " " + rectWidth / 2 + " 0)")
                            .on("mouseover", function (d) {
                                d3.select(this).transition()
                                        .duration(200)
                                        .attr("transform", "translate(" +
                                                (d.startPoint.x - rectWidth / 2 * magnifierFactor) +
                                                "," + d.startPoint.y +
                                                ") rotate(" + d.angleInDegrees + " " +
                                                rectWidth / 2 * magnifierFactor +
                                                " 0) scale(" + magnifierFactor + ")");//TODO:....
                            })
                            .on("mouseout", function (d) {
                                d3.select(this).transition()
                                        .duration(200)
                                        .attr("transform", "translate(" +
                                                (d.startPoint.x - rectWidth / 2) +
                                                "," + (d.startPoint.y) +
                                                ") rotate(" + d.angleInDegrees + " " +
                                                rectWidth / 2 + " 0)");
                            })
                            .style("cursor", "pointer");

                    g.append("svg:rect")
                            .attr("x", smallEdgeShifting)
                            .attr("width", rectWidth)
                            .attr("height", heightScale(failed))
                            .style("fill", "red");

                    g.append("svg:rect")
                            .attr("x", smallEdgeShifting)
                            .attr("y", heightScale(failed))
                            .attr("width", rectWidth)
                            .attr("height", heightScale(success))
                            .style("fill", "green");

                    g.append("svg:rect")
                            .attr("x", smallEdgeShifting)
                            .attr("y", heightScale(failed + success))
                            .attr("width", rectWidth)
                            .attr("height", heightScale(inactive))
                            .style("fill", "gray");

                    g.append("svg:rect")
                            .datum(mitigations)
                            .on("click", function (d) {
                                mitigationsPreview(d);
                            })
                            .attr("x", smallEdgeShifting)
                            .attr("width", rectWidth)
                            .attr("height", rectHeight)
                            .style("fill", "white")
                            .style("fill-opacity", 0)
                            .style("stroke", "black")
                            .style("stroke-width", "1px");
                }
            }

            /** 
             * Draws red and animates attacked nodes
             * @param {num} indexOfPreview Index of chosen preview
             * @returns {undefined}
             */
            function reactiveAlert(indexOfPreview, duration, delay) {//TODO:clean

                if (mode == 1) {


                    drawAttackGraph();
                    var allAlertNodes = alertNodes.slice(0, indexOfPreview); //takes first first indexOfPreview number of nodes from alert nodes
                    //lets find the nodes and fill them red
                    var activeNode = alertNodes[indexOfPreview - 1];


                    var activeAlertNodes = d3.selectAll(".node").filter(function (d) {
                        return allAlertNodes.indexOf(d.name) != -1;
                    });
                    activeAlertNodes.select("circle")
                            .style("fill", "red")
                            .attr("r", 8)
                            .attr("stroke", "none");

                    activeAlertNodes.filter(function (d) {
                        return d.name == activeNode;
                    }).select("circle")
                            .transition()
                            .duration(duration)
                            .attr("r", 20)
                            .style("fill", "red")
                            .each("end", function () {
                                d3.select(this)
                                        .transition()
                                        .delay(delay)
                                        .duration(duration)
                                        .attr("r", 11)

                                        .each("end", function () {
                                            d3.select(this)
                                                    .attr("stroke", "black")
                                                    .attr("stroke-width", 2);
                                            reactive(indexOfPreview);
                                            perimeter(indexOfPreview);
                                        });
                            });
                }
            }

            function drawFuncReactive(indexOfPreview) {

                $("<div style=\"width:" + wAttackPreview + "px; height:" + hBottomMenu + "px;\" id=\"attackPreview_" + indexOfPreview + "\" class=\"attackPreview\"><div style=\"position: absolute; width:" + wAttackPreview + "px; height:" + hPreviewDiv + "px;\"></div><svg style=\"width:" + wAttackPreview + "px; height:" + hSVGPreview + "px;\" class=\"SVGPreview\"></svg></div>").prependTo(".bottomMenu");

                var divPreview = d3.select("#attackPreview_" + indexOfPreview);
                globalAttackEvolution = indexOfPreview - 1;
                //IDff
                divPreview.select("div").append("text")
                        .attr("class", "textAttackID")
                        .text("Attack ID: " + indexOfPreview)
                        .style("left", "5px")
                        .style("top", "5px");

                var svgPreview = divPreview.select("svg");
                var json = "json attack/attack" + indexOfPreview + ".json";

                //update likelihood array
                d3.json(json, function (source) {
                    totalAttacks[indexOfPreview - 1] = source;
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

                    /*if(mode == 1){
                     reactive();
                     var a=alertNodes.slice(0,indexOfPreview)
                     var node = d3.selectAll(".node").filter(function(e){
                     return a.indexOf(e.name)!=-1;
                     })
                     node.selectAll("circle").style("fill","red");
                     
                     node.filter(function(d){
                     return d.name==alertNodes[indexOfPreview-1];
                     }).select("circle")
                     .transition()
                     .duration(500)
                     .attr("r", 10)
                     .style("fill","red")
                     .each("end", function(){
                     d3.select(this)
                     .transition()
                     .duration(500)
                     .attr("r", 7);
                     });
                     }*/
                    //blink animation
                    if (mode == 0) {
                        divPreview.transition().duration(500).style("border-color", "#fff");
                    }
                    else {
                        //console.log(idInstantiated +" ////// "+indexOfPreview)
                        if (idInstantiated === indexOfPreview) {
                            divPreview.transition().duration(500).style("border-color", "#f00");
                        }
                        else {
                            divPreview.transition().duration(500).style("border-color", "#fff");
                        }
                    }

                });




                /*svgPreview.on("click", function() {
                 
                 //delete temporary accumulate arcs
                 d3.selectAll("#tempArc").remove();
                 
                 //if we are in proactive mode we add the graphs on the map
                 if(mode==0){
                 var div=d3.select(d3.select(this).node().parentNode);
                 var index=(div.attr("id")).match(/[0-9]+/)[0];
                 var j = "json attack/attack"+index+".json";
                 if(div.style("border-top-color")=="rgb(255, 255, 255)"){
                 div.style("border-color","yellow");
                 if(queueSVG.length==0){
                 createChart(j,index);
                 createGraph(j,index,0);
                 }
                 else{
                 //set last svg display property to none 
                 var last=queueSVG[queueSVG.length-1];
                 d3.select("#svgTable_"+last).attr("display","none");
                 //add new chart
                 createChart(j,index);
                 createGraph(j,index,0);
                 }
                 queueSVG.push(index);
                 }
                 else{			
                 div.style("border-color","white");
                 removeGraphAndChart(index);
                 layer.selectAll("#lineStaticAttack"+index).remove();
                 //delete from list
                 var indexOfSVG = queueSVG.indexOf(index);
                 queueSVG.splice(indexOfSVG,1);
                 //if the list is not empty, set display property of the last svg to initial
                 if(queueSVG.length>0){
                 var last=queueSVG[queueSVG.length-1];
                 d3.select("#svgTable_"+last).attr("display","initial");
                 }
                 }
                 
                 }
                 });*/

                drawPreview(indexOfPreview, svgPreview, json);

            }

        </script>

    </body>

</html>
