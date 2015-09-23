<!DOCTYPE html>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<html>

    <head>
        <meta name="viewport" content="initial-scale=0.9" />
        <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=true"></script>
        <script type="text/javascript" src="javascript/d3.v2.js"></script>
        <script type="text/javascript" src="javascript/d3.tip.v0.6.3.js"></script>
        <script type="text/javascript" src="javascript/d3.js"></script>
        <script src="https://code.jquery.com/jquery-1.10.2.js"></script>
        <style type="text/css">
            @import url("style.css?1.10.0");
        </style>
    </head>

    <body onload="loadData();">
        <!--    <body onload="
                    createOverlay();">-->

        <form id ="radioButtonsForm" 
              style="position: absolute; 
              z-index: 1; 
              background-color: #3d3d3d; 
              color:#fff; 
              border-radius: 5px; 
              border-style: solid;
              border-width: 1px;
              border-color:#E6E6E6;
              font: 16px sans-serif;" >
            <input id="pro" type="radio" name="mode" value="proactive" onClick="proactive()" >Proactive
            <br>
            <input id="re" type="radio" name="mode" value="reactive" onClick="reactive(1)"  checked>Reactive


        </form> 

        <!--remove the elements in the map where -->
        <div id="map" style="position: absolute"></div>

        <script type="text/javascript">
            var h = parseInt(window.innerHeight),
                    w = parseInt(window.innerWidth),
                    mode = 1, //0=proactive, 1=reactive
                    alertIndex = 0,
                    overlay = 0,
                    map,
                    rightMenuVisible = true,
                    bottomMenuVisible = true,
                    leftMenuVisible = true,
                    topMenuVisible = true,
                    sizeLabel = 50,
                    svgshifting = 2500,
                    borderAttackPreview = 2,
                    totalEdges = [],
                    totalNode = [],
                    totalAttacks = [],
                    totalResponse = [],
                    alertNodes,
                    reactiveAlertNodes = [
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
                    wRightMenu = 350,
                    hBottomMenu = h * 0.25,
                    width = wRightMenu,
                    height = wRightMenu,
                    mm = 0,
                    originalPos = [],
                    radius = Math.min(width, height) / 1.5,
                    projection = 0,
                    layer = 0,
                    numberOfPreviewAttack = 5,
                    rightMenu,
                    leftMenu,
                    bottomMenuContainer,
                    topMenu,
                    wAttackPreview = (w - borderAttackPreview * (numberOfPreviewAttack * 2)) / numberOfPreviewAttack,
                    flagTable = 0,
                    flagClickedNode = 0, //0 not clicked, 1 clicked
                    lastClickedNode = "",
                    array = ["#8dd3c7", "#bebada", "#80b1d3", "#fccde5", "#d9d9d9", "#bc80bd", "#ccebc5", "2035FF", "0AB26C"],
                    color = d3.scale.ordinal().range(array),
                    wMap = w - wRightMenu - w / 5, //w/5 is space in excess
                    hMap = h - hBottomMenu,
                    wSVGPreview = wAttackPreview,
                    hPreviewHeaderDiv = 35,
                    hSVGPreview = hBottomMenu - 30,
                    nodeRadius = 7,
                    currentPreviewIndex = -1,
                    lineOpacity = 0.1,
                    barrierHeight = 60,
                    barrierWidth = 12;

            initializeInterface(); //data indepenedent code
            initMap();             //data indepenedent code

            function initMap() {
                // Create the Google Map
                map = new google.maps.Map(d3.select("#map").node(), {
                    zoom: 11,
                    center: new google.maps.LatLng(41.864832, 12.601916), //center of rome
                    mapTypeId: google.maps.MapTypeId.ROADMAP,
                    streetViewControl: false,
                    panControl: false,
                    mapTypeControl: false,
                    zoomControl: true,
                    zoomControlOptions: {
                        style: google.maps.ZoomControlStyle.SMALL,
                        position: google.maps.ControlPosition.LEFT_CENTER
                    }

                });
                var styles = [[
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
                    ],
                    [
                        {
                            "featureType": "landscape.man_made",
                            "stylers": [
                                {"visibility": "off"}
                            ]
                        }, {
                            "featureType": "road.local",
                            "stylers": [
                                {"visibility": "off"}
                            ]
                        }, {
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
                            "featureType": "administrative",
                            "stylers": [
                                {"visibility": "off"}
                            ]
                        }, {
                            "featureType": "water",
                            "elementType": "labels",
                            "stylers": [
                                {"visibility": "off"}
                            ]
                        }, {
//                        zoomControlOptions: {
//                            position: google.maps.ControlPosition.LEFT_CENTER,
//                            style: google.maps.ZoomControlStyle.SMALL
//                        }
                        }
                    ]];
                map.setOptions({styles: styles[1]});
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
//                 drawPreview(i);*/

// TODO: zoom for proactive mode
                    removeAllElements();
                    for (var indexOfPreview = 0; indexOfPreview <= currentPreviewIndex; indexOfPreview++) {
                        attackAlert(indexOfPreview, 100, indexOfPreview * 300);
                    }
                });
            }

            function createOverlay() {
                overlay = new google.maps.OverlayView();

                // Bind our overlay to the map
                overlay.setMap(map);

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
                        layer.append("g").attr("id", "barriers");
                        //marker for arrows map
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "lineStaticAttackMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 5)
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
                                .attr("id", "lineInstantiateOnGoingAttackMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 5)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");
                        //marker for arrows instantiateDone attack
                        layer.append("svg:defs").append("svg:marker") // This section adds in the arrows
                                .attr("id", "lineInstantiateAttackMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 5)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");
                        layer.append("svg:defs").append("svg:marker")
                                .attr("id", "perimeterArcMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 5)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 15)
                                .attr("markerHeight", 15)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");
                        layer.append("svg:defs").append("svg:marker")
                                .attr("id", "socialNetworkArcMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 8)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 18)
                                .attr("markerHeight", 20)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");
                        layer.append("svg:defs").append("svg:marker")
                                .attr("id", "ingoingLinkMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 30)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 10)
                                .attr("markerHeight", 30)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");
                        layer.append("svg:defs").append("svg:marker")
                                .attr("id", "outgoingLinkMarker")
                                .attr("viewBox", "0 -5 10 10")
                                .attr("refX", nodeRadius + 8)
                                .attr("refY", 0)
                                .attr("markerUnits", "userSpaceOnUse")
                                .attr("markerWidth", 10)
                                .attr("markerHeight", 30)
                                .attr("orient", "auto")
                                .append("svg:path")
                                .attr("d", "M0,-5L10,0L0,5");
                        d3.selectAll(".line").remove();
                        d3.selectAll(".barrier").remove();
                        d3.selectAll(".nodeBarrier").remove();
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
                                })
                                .style("opacity", lineOpacity);
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
                                .attr("cy", padding)
                                .style("cursor", "pointer")
                                .on("mouseover", function (node) {
                                    if (mode == 1) {
                                        d3.selectAll(".nodeBarrier")
                                                .filter(function (nodeBarrier) {
                                                    return nodeBarrier.name == node.name;
                                                })
                                                .select("path")
                                                .style("display", "initial")
                                                .transition()
                                                .duration(200)
                                                .style("opacity", "1");
                                        d3.selectAll(".barrier")
                                                .filter(function (barrier) {
                                                    return barrier.targetNode != node && barrier.position.onEdgeFlag;
                                                })
                                                .transition()
                                                .duration(200)
                                                .style("fill-opacity", "0")
                                                .style("stroke-opacity", "0");
                                        d3.selectAll(".barrier")
                                                .filter(function (barrier) {
                                                    return barrier.targetNode == node;
                                                })
                                                .style("display", "initial")
                                                .transition()
                                                .duration(200)
                                                .style("fill-opacity", "1")
                                                .style("stroke-opacity", "1");
                                        layer.selectAll(".line")
                                                .style("opacity", lineOpacity)
                                                .filter(function (d) { //ingoing arcs
                                                    return (d.target.name == node.name);
                                                })
                                                .style("opacity", "0.5")
                                                .attr("marker-end", "url(#ingoingLinkMarker)");
                                    }

                                })
                                .on("mouseout", function (node) {
                                    if (mode == 1) {
                                        d3.selectAll(".nodeBarrier")
                                                .filter(function (nodeBarrier) {
                                                    return nodeBarrier.name == node.name;
                                                })
                                                .select("path")
                                                .transition()
                                                .duration(50)
                                                .style("opacity", "0")
                                                .transition()
                                                .style("display", "none");
                                        d3.selectAll(".barrier")
                                                .filter(function (barrier) {
                                                    if (barrier.sourceNode.name != alertNodes[currentPreviewIndex]) {
                                                    }
                                                    return barrier.sourceNode.name != alertNodes[currentPreviewIndex];
                                                })
                                                .transition()
                                                .duration(50)
                                                .style("fill-opacity", "0")
                                                .style("stroke-opacity", "0")
                                                .transition()
                                                .style("display", "none");
                                        d3.selectAll(".barrier")
                                                .filter(function (barrier) {
                                                    if (barrier.sourceNode.name == alertNodes[currentPreviewIndex]) {
                                                    }
                                                    return barrier.sourceNode.name == alertNodes[currentPreviewIndex];
                                                })
                                                .style("display", "initial")
                                                .transition()
                                                .duration(200)
                                                .style("fill-opacity", "1")
                                                .style("stroke-opacity", "1");
                                        layer.selectAll(".line")
                                                .style("opacity", lineOpacity)
                                                .attr("marker-end", "none")
                                                .filter(function (d) { //outgoing arcs
                                                    return (d.source.name == alertNodes[currentPreviewIndex]);
                                                })
                                                .attr("marker-end", "url(#outgoingLinkMarker)")
                                                .style("opacity", "0.5");
                                    }
                                })
                                .on("click", function (node) {
                                    if (mode == 1) {
                                        //if there are bariers yet, call click() to put them on graph
                                        d3.select("#barrierDetailsHeaderSVGforBarrier").selectAll("g")
                                                .each(function (d, i) {
                                                    d3.select(this).on("click").apply(this, [d, i]);
                                                    d3.select(this).transition()
                                                            .delay(600)
                                                            .duration(200)
                                                            .style("fill-opacity", "0")
                                                            .style("stroke-opacity", "0");
                                                });
                                        clearMitigationPreview();
                                        var mitigations = [];
                                        d3.selectAll(".barrier")
                                                .filter(function (barrier) {
                                                    return barrier.targetNode == node;
                                                })
                                                .each(function (barrier) {
                                                    mitigations.push(barrier);
                                                });
                                        if (mitigations.length > 0)
                                            mitigationsPreview(mitigations);
                                    }
                                });
                        nodes.append("text")
                                .attr("x", padding + 7)
                                .attr("y", padding)
                                .attr("dy", ".31em")
                                .text(function (d) {
                                    return d.name;
                                });
                        mm++;
                        var arc = d3.svg.arc()
                                .outerRadius(25)
                                .innerRadius(20);
                        var pie = d3.layout.pie()
                                .sort(null)
                                .value(function (d) {
                                    return d;
                                });
                        var barriers = layer.select("#barriers").selectAll(".nodeBarrier")
                                .data(totalNode)
                                .each(transformNode)
                                .enter()
                                .append("svg")
                                .each(transformNode)
                                .attr("class", "nodeBarrier")
                                .selectAll(".barrierPie")
                                .data(pie([1]))
                                .enter()
                                .append("g")
                                .attr("class", "barrierPie")
                                .attr("transform", "translate(" + padding + "," + padding + ")")
                                .append("path")
                                .attr("d", arc);
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
                        drawInterface();
                    };
                };

            }

            function loadData() {
                d3.json("network1.json", function (error, source) {
                    if (error)
                        return console.warn(error);
                    //create node list
                    createNodeList(source);
                    d3.json("response_plan/RPALL1.json", function (data)
                    {
                        totalResponse = data;

                        d3.json("json attack/attackALL1.json", function (source) {
                            totalAttacks = source;
                            createOverlay(); //data dependenden code
                        });
                    });
                });
            }

            function initializeInterface() {
                createRightMenu();
                createLeftMenu();
                createBottomMenu();
                createTopMenu();
                //removeElements();
            }



            function drawInterface() {
//                console.log("originalPos:");
//                console.log(originalPos);
//                console.log("totalAttacks:");
//                console.log(totalAttacks);
//                console.log("totalEdges");
//                console.log(totalEdges);
//                console.log("totalNode");
//                console.log(totalNode);
//                console.log("totalResponse");
//                console.log(totalResponse);
                updateTotalResponse();
                drawDonutChart();
                drawButtons();
                drawPreviews();
                d3.select(".leftMenuLabel").transition().delay(100).each(function (d, i) {
                    d3.select(this).on("click").apply(this, [d, i]);
                });
                d3.select(".topMenuLabel").transition().delay(200).each(function (d, i) {
                    d3.select(this).on("click").apply(this, [d, i]);
                });
            }
            function updateTotalResponse() {
                var statusItems = ["success", "failed"];
                totalResponse.forEach(function (attackResponse) {
                    attackResponse["response-plan"].forEach(function (mitigation) {
                        if (mitigation.mitigation.status == "inactive") {
                            mitigation.mitigation.status = statusItems[Math.floor(Math.random() * statusItems.length)];
                        }
                    });
                });

            }
            function removeElements() {
                d3.selectAll(".gmnoprint").remove();
                d3.select(".gm-style-cc").remove();
                d3.select("a").remove();
            }

            function removeAllElements() {
                //d3.selectAll(".gmnoprint").remove();
                //d3.select(".gm-style-cc").remove();
                d3.select("a").remove();
                d3.selectAll(".perimeterArc").remove();
                d3.selectAll(".lineStaticAttack").remove();
                d3.selectAll(".lineInstantiateAttack").remove();
                d3.selectAll(".lineInstantiateOnGoingAttack").remove();
                d3.selectAll(".socialNetworkArc").remove();
                d3.selectAll(".barrier").remove();
                //reset all lines
                d3.selectAll(".line").style("opacity", lineOpacity);
                //reset all node
                d3.selectAll(".node").selectAll("circle")
                        .style("fill", "#3d3d3d")
                        .attr("r", nodeRadius)
                        .attr("stroke", "none");
                d3.select(".tableAttack").selectAll("svg").remove();
                clearProbableAttack();
            }
            /**
             * Inits totalNode, totalEdges, subnetList
             * @@param source
             * @returns {undefined}
             */
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
                        y: ylong,
                        fixed: true //we lock the position
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

            function createRightMenu() {
                rightMenu = d3.select("body").append("div").attr("class", "rightMenu")
                        .style("height", h + "px");
//                        .style("width", wRightMenu + "px")
//                        .style("position", "absolute")
//                        .style("top", "0px")
//                        .style("right", "0px");
                rightMenu.append("svg").attr("class", "rightMenuLabel")
                        .style("position", "absolute")
                        .style("top", "0px")
                        .style("left", -sizeLabel - 2 + "px")
                        .style("height", sizeLabel + "px")
                        .style("width", sizeLabel + "px")
                        .on("click", function () {
                            if (rightMenuVisible) {
                                rightMenu.transition().style("right", -wRightMenu + "px").duration(500).each("end", function () {
                                    bottomMenuContainer.transition().duration(500).style("width", w + "px");
                                });
                                rightMenuVisible = false;
                            } else {
                                rightMenu.transition().duration(500).style("right", "0px");
                                bottomMenuContainer.transition().duration(500).style("width", w - wRightMenu + "px");
                                rightMenuVisible = true;
                            }
                        })
                        .style("background-color", "#3d3d3d");
                var rightMenuContainer = rightMenu.append("div")
                        .attr("id", "rightMenuContainer")
                        .attr("class", "flexcontainer");
                rightMenuContainer.append("div")
                        .attr("id", "buttonsDiv")
                        .style("position", "relative")
                        .style("width", width)
                        .style("height", "30px")
                        .style("text-align", "center")
                        .style("background-color", "#3d3d3d");
                drawResponsePlanPreview(rightMenuContainer);
            }

            function createLeftMenu() {
                leftMenu = d3.select("body").append("div").attr("class", "leftMenu")
                        .style("height", h + "px")
                        .style("width", wRightMenu + "px")
                        .style("position", "absolute")
                        .style("top", "60px")
                        .style("left", "0px");
                leftMenu.append("svg").attr("class", "leftMenuLabel")
                        .style("position", "absolute")
                        .style("top", "0px")
                        .style("right", -sizeLabel - 2 + "px")
                        .style("height", sizeLabel + "px")
                        .style("width", sizeLabel + "px")
                        .on("click", function () {
                            if (leftMenuVisible) {
                                leftMenu.transition().duration(500).style("left", -wRightMenu + "px");
                                leftMenuVisible = false;
                            }
                            else {
                                leftMenu.transition().duration(500).style("left", "0px");
                                leftMenuVisible = true;
                            }
                        })
                        .style("background-color", "#3d3d3d");
                var div = leftMenu.append("div")
                        .attr("id", "donutChartDiv")
                        .style("position", "relative")
                        .style("height", height)
                        .style("width", width)
                        .style("background-color", "#3d3d3d");
                div.append("svg")
                        .attr("id", "donutChart")
                        .attr("width", width)
                        .attr("height", height)
                        .append("g")
                        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
                leftMenu.append("div")
                        .attr("class", "tableAttack")
                        .style("left", (wRightMenu / 3 - (radius / 8)) + "px")
                        .style("top", height * 0.4 / 2 + "px")
                        .style("width", 5 * radius / 8 + "px") //radius/2 for rect lenght + radius/8 for shifting when mouseover on arc
                        .style("height", height * 0.6 + "px")
                        .style("max-height", height * 0.6 + "px");
            }

            //creates bottom menu and associates for each div a svg
            function createBottomMenu() {
                bottomMenuContainer = d3.select("body").append("div")
                        .attr("class", "bottomMenuContainer")
                        .style("height", hBottomMenu + "px")
                        .style("width", w - wRightMenu + "px")
                        .style("position", "absolute")
                        .style("bottom", "0px")
                        .style("left", "0px");
                bottomMenuContainer.append("svg").attr("class", "bottomMenuLabel")
                        .style("position", "absolute")
                        .style("top", -sizeLabel - 2 + "px")
                        .style("height", sizeLabel + "px")
                        .style("width", sizeLabel + "px")
                        .on("click", function () {
                            if (bottomMenuVisible) {
                                bottomMenuContainer.transition().duration(500).style("bottom", -hBottomMenu + "px");
                                bottomMenuVisible = false;
                            } else {
                                bottomMenuContainer.transition().duration(500).style("bottom", "0px");
                                bottomMenuVisible = true;
                            }
                        })
                        .style("background-color", "#3d3d3d");
                bottomMenuContainer.append("div")
                        .attr("class", "bottomMenu")
                        .style("height", hBottomMenu + "px")
                        .style("width", "100%")
                        .attr("align", "left");
            }

            function createTopMenu() {
                topMenu = d3.select("body").append("div")
                        .attr("class", "topMenu")
                        .style("height", 2 * hBottomMenu + "px")
                        .style("width", w - wRightMenu - 200 + "px")
                        .style("position", "absolute")
                        .style("top", "0px")
                        .style("left", "100px");
                topMenu.append("svg").attr("class", "topMenuLabel")
                        .style("position", "absolute")
                        .style("bottom", -sizeLabel - 2 + "px")
                        .style("height", sizeLabel + "px")
                        .style("width", sizeLabel + "px")
                        .on("click", function () {
                            if (topMenuVisible) {
                                topMenu.transition().duration(500).style("top", -2 * hBottomMenu + "px");
                                topMenuVisible = false;
                            } else {
                                topMenu.transition().duration(500).style("top", "0px");
                                topMenuVisible = true;
                            }
                        })
                        .style("background-color", "#3d3d3d");
                topMenu.append("div")
                        .attr("id", "parallelCoordinates")
                        .style("height", d3.select(".topMenu").node().getBoundingClientRect().height - 2 + "px")
                        .style("width", "100%")
                        .attr("align", "left")
                        //.style("background-color", "white")
                        .style("background-color", "#3d3d3d");
                drawParallelCoordinates();
            }

            function drawParallelCoordinates() {
                var margin = {top: 40, right: 10, bottom: 40, left: 10},
                width = d3.select("#parallelCoordinates").node().getBoundingClientRect().width - margin.left - margin.right,
                        height = d3.select("#parallelCoordinates").node().getBoundingClientRect().height - margin.top - margin.bottom;
                var x = d3.scale.ordinal().rangePoints([0, width], 1),
                        y = {};
                var line = d3.svg.line(),
                        axis = d3.svg.axis().orient("left"),
                        background,
                        foreground;
                var svg = d3.select("#parallelCoordinates").append("svg")
                        .attr("width", width + margin.left + margin.right)
                        .attr("height", height + margin.top + margin.bottom)
                        .append("g")
                        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
                d3.csv("riskParameters.csv", function (error, cars) {
                    // Extract the list of dimensions and create a scale for each.
                    x.domain(dimensions = d3.keys(cars[0]).filter(function (d) {
                        return d != "response plan ID" && (y[d] = d3.scale.linear()
                                .domain(d3.extent(cars, function (p) {
                                    return +p[d];
                                }))
                                .range([height, 0]));
                    }));
                    // Add grey background lines for context.
                    background = svg.append("g")
                            .attr("class", "background")
                            .selectAll("path")
                            .data(cars)
                            .enter().append("path")
                            .attr("d", path);
                    // Add blue foreground lines for focus.
                    foreground = svg.append("g")
                            .attr("class", "foreground")
                            .selectAll("path")
                            .data(cars)
                            .enter().append("path")
                            .attr("d", path)
                            .style("stroke-width", "1.5")
                            .on("mouseover", function () {
                                d3.select(this)
                                        .style("stroke-width", "5");
                                var self = this;
                                d3.selectAll(".foreground").selectAll("path")
                                        .filter(function () {
                                            return this != self;
                                        })
                                        .style("opacity", "0.2")
                                        .style("stroke-width", "1.5");
                            })
                            .on("mouseout", function () {
//                                d3.select(this)
//                                        .style("stroke-width", "3");
//                                var self = this;
                                d3.selectAll(".foreground").selectAll("path")
//                                        .filter(function () {
//                                            return this != self;
//                                        })
                                        .style("opacity", "initial")
                                        .style("stroke-width", "1.5");
                            });
                    // Add a group element for each dimension.
                    var g = svg.selectAll(".dimension")
                            .data(dimensions)
                            .enter().append("g")
                            .attr("class", "dimension")
                            .attr("transform", function (d) {
                                return "translate(" + x(d) + ")";
                            });
                    // Add an axis and title.
                    g.append("g")
                            .attr("class", "axis")
                            .each(function (d) {
                                d3.select(this).call(axis.scale(y[d]));
                            })
                            .append("text")
                            .style("text-anchor", "middle")
                            .attr("y", -9)
                            .text(function (d) {
                                return d;
                            });
                    // Add and store a brush for each axis.
                    g.append("g")
                            .attr("class", "brush")
                            .each(function (d) {
                                d3.select(this).call(y[d].brush = d3.svg.brush().y(y[d]).on("brush", brush));
                            })
                            .selectAll("rect")
                            .attr("x", -8)
                            .attr("width", 16);
                });
                // Returns the path for a given data point.
                function path(d) {
                    return line(dimensions.map(function (p) {
                        return [x(p), y[p](d[p])];
                    }));
                }

                // Handles a brush event, toggling the display of foreground lines.
                function brush() {
                    var actives = dimensions.filter(function (p) {
                        return !y[p].brush.empty();
                    }),
                            extents = actives.map(function (p) {
                                return y[p].brush.extent();
                            });
                    foreground.style("display", function (d) {
                        return actives.every(function (p, i) {
                            return extents[i][0] <= d[p] && d[p] <= extents[i][1];
                        }) ? null : "none";
                    });
                }
            }

            function drawPreviewGraph(index, svg) {
                var graphAttack = [];
                totalAttacks[index].attack.forEach(function (d) {
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
                drawPreviewArcs(svg, graphAttack);
                //animationArcs(svg,graphAttack);
                drawPreviewNodes(svg, graphAttack);
                var attackPreviewHeader = d3.select("#attackPreviewHeader_" + index);
                attackPreviewHeader.append("text")
                        .attr("class", "textAttackID")
                        .text("Attack ID: " + index)
                        .style("position", "absolute")
                        .style("left", "10px")
                        .style("top", "15px");
                attackPreviewHeader.append("button")
                        .style("width", "75px")
                        .style("height", "25px")
                        .style("position", "absolute")
                        .style("right", "10px")
                        .style("top", "10px")
                        .html("Inspect")
                        .on("click", function () {
                            svg.selectAll(".linePreviewAttack").remove();
                            animationArcs(svg, graphAttack);
                            //d3.event.stopPropagation();
                        });
                attackPreviewHeader.append("button")
                        .style("width", "80px")
                        .style("height", "25px")
                        .style("position", "absolute")
                        .style("right", "90px")
                        .style("top", "10px")
                        .html("Visualize")
                        .on("click", function () {
                            removeAllElements();
                            alertNodes = getAttackArray(totalAttacks[index].attack);
                            var duration = 2000;
                            for (var indexOfAlertNode = 0; indexOfAlertNode < alertNodes.length; indexOfAlertNode++) {
                                attackAlert(indexOfAlertNode, duration, duration * indexOfAlertNode + 100, index);
                            }
                        });
                //legend
                var g = svg.append("g")
                        .attr("transform", "translate(" + (wSVGPreview - 75) + "," + (hPreviewHeaderDiv + 20) + ")");
                g.append("text")
                        .attr("class", "textPreview")
                        .text("Prob.: " + totalAttacks[index].probability);
                g.append("text")
                        .attr("transform", "translate(0," + 20 + ")")
                        .attr("class", "textPreview")
                        .text("Length: " + graphAttack.length);
                g.append("text")
                        .attr("transform", "translate(0," + 40 + ")")
                        .attr("class", "textPreview")
                        .text("Legend:");
                var g1 = g.append("g")
                        .attr("transform", "translate(0," + 60 + ")");
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
                        .attr("transform", "translate(0," + 80 + ")");
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
            }

            function drawPreviewArcs(svgPreview, list) {
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

            function drawPreviewNodes(svgPreview, list) {
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

            function createChart(x) {
                var index = 0, i = 0;
                var graphAttack = [], lines = [], tableAttack = d3.select(".tableAttack");
                //draw graph attacck and donut chart


                flagTable = 1;
                //draw donut and graph attack
                var yOffset = 0;
                var i = 0;
                var svgTable = d3.select("#svgTable_" + x);
                if (svgTable[0][0] == null) {
                    var svgTable = tableAttack.append("svg")
                            .attr("id", "svgTable_" + x)
                            .attr("width", tableAttack.style("width"))
                            .attr("height", (parseInt(radius * 0.1) + 1) * totalAttacks[x].attack.length);
                }

                totalAttacks[x].attack.forEach(function (d) {
                    var s_attack = totalAttacks[x].attack[i++];
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
                                    outgoingLinks.transition().duration(1000).style("opacity", lineOpacity);
                                    remainLinks.transition().duration(1000).style("opacity", lineOpacity);
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
            }

            function createGraph(alertNodeIndex, attackIndex, type, animationDuration) {

                var id;
                var stroke = 6;
                var radiusMagnifier = 1;
                switch (type) {
                    case 0:
                        id = "lineStaticAttack";
                        break;
                    case 1:
                        id = "lineInstantiateOnGoingAttack";
                        radiusMagnifier = 0.7;
                        break;
                    case 2:
                        id = "lineInstantiateAttack";
                        radiusMagnifier = 1.7;
                        break;
                    case 3:
                        id = "perimeterArc";
                        radiusMagnifier = 0;
                        break;
                    case 4:
                        id = "socialNetworkArc";
                        radiusMagnifier = 1.5;
                        break;
                }
                var lines = {
                    edges: [],
                    class: id,
                    radiusMagnifier: radiusMagnifier
                };
                if (type == 0 || type == 1) {
                    var maxProbability = 0;
                    totalAttacks.forEach(function (d) {
                        if (d.probability > maxProbability)
                            maxProbability = d.probability;
                    });
                    var scaleStrokeWidth = d3.scale.linear()
                            .domain([0, maxProbability])
                            .range([0, 6]);
                    totalAttacks[attackIndex].attack.forEach(function (attackEdge) {
                        if (attackEdge.target.name != "x")
                            lines.edges.push({
                                source: getNode(attackEdge.source.name),
                                target: getNode(attackEdge.target.name),
                                edgeId: id + attackIndex,
                                strokeWidth: scaleStrokeWidth(totalAttacks[attackIndex].probability),
                                attacksId: [attackIndex]
                            });
                    });
                    drawGraph(lines);
                    if (type == 0)
                        createBarriers(lines);
                }
                else if (type == 2) {
                    //draw lineInstantiateAttack lines on the base on alertNodes
                    if (!!alertNodes[alertNodeIndex] && !!alertNodes[alertNodeIndex - 1]) {
                        lines.edges.push({
                            source: getNode(alertNodes[alertNodeIndex - 1]),
                            target: getNode(alertNodes[alertNodeIndex]),
                            edgeId: id + attackIndex,
                            strokeWidth: stroke,
                            attacksId: [attackIndex]
                        });
                    }
                    drawGraph(lines, animationDuration);
                    if (mode == 0)
                        setTimeout(function () {
                            createBarriers(lines);
                        }, animationDuration * 3);
                }
                else if (type == 3) {
                    d3.selectAll(".perimeterArc").remove();
                    var activeNode = alertNodes[alertNodeIndex];
                    //Active attack predicted edges which are then covered by barriers  
                    var maxAttacksPerEdge = 0;
                    for (var h = 0; h < totalAttacks.length; h++)//for all attacs
                    {
                        outerloop:
                                for (var k = 0; k < totalAttacks[h].attack.length; k++)//for each attack path in attack
                        {
                            if (totalAttacks[h].attack[k].source.name === activeNode)//if attack path goes from our activeNode 
                            {
//                                var noEdge = true;
//                                totalEdges.forEach(function (edge) {
//                                    if (totalAttacks[h].attack[k].source.name == edge.source.name && totalAttacks[h].attack[k].target.name == edge.target.name) {
//                                        noEdge = false;
//                                    }
//                                });
//                                if (noEdge)
//                                    break;
                                //we compute mitigations anyway
                                var s = totalAttacks[h].attack[k].source.name;
                                var t = totalAttacks[h].attack[k].target.name;
                                for (var i = 0; i < lines.edges.length; i++) {//for all activeAttackEdges
                                    if (totalAttacks[h].attack[k].target.name === lines.edges[i].target.name) {//We see if there exsist the same edge in our activeAttackEdges
                                        //we only add attack to the existing edge
                                        lines.edges[i].attacksId.push(h);
                                        break outerloop; //to skip adding new new edge to activeAttackEdges
                                    }
                                }
                                //if there is no edge, we add new new edge to activeAttackEdges
                                if (totalAttacks[h].attack[k].target.name != "x") { //if not the last node though
                                    lines.edges.push({
                                        source: getNode(s),
                                        target: getNode(t),
                                        edgeId: id + replacePoints(s) + "-" + replacePoints(t),
                                        strokeWidth: 2,
                                        attacksId: [h]
                                    });
                                }
                            }
                        }
                    }
                    //update stroke widths on base of number attacks going through the edge
                    lines.edges.forEach(function (d) {
                        if (d.attacksId.length > maxAttacksPerEdge)
                            maxAttacksPerEdge = d.attacksId.length;
                    });
                    var scaleStrokeWidth = d3.scale.linear()
                            .domain([0, maxAttacksPerEdge])
                            .range([2, 6]);
                    lines.edges.forEach(function (d) {
                        d.strokeWidth = scaleStrokeWidth(d.attacksId.length);
                    });
                    drawGraph(lines);
                    createBarriers(lines);
                    //hightlight outgoing links
                    var outgoingLinks = layer.selectAll(".line").filter(function (d) { //outgoing arcs
                        return (d.source.name === activeNode);
                    })
                            //.style("stroke-width", "5px")
                            .style("opacity", "0.5")
                            .attr("marker-end", "url(#outgoingLinkMarker)");
                }
                else if (type == 4) {
                    var activeNode = "192.168.1.13";
                    attackloop:
                            for (var h = 0; h < totalAttacks.length; h++)//for all attacs
                    {
                        if (totalAttacks[h].attack[0].source.name != activeNode) {//if attack path does not go from our activeNode 
                            continue attackloop;
                        }
                        pathloop:
                                for (var k = 0; k < totalAttacks[h].attack.length; k++)//for each attack path in attack
                        {

                            var s = totalAttacks[h].attack[k].source.name;
                            var t = totalAttacks[h].attack[k].target.name;
                            for (var i = 0; i < lines.edges.length; i++) {//for all activeAttackEdges
                                if (totalAttacks[h].attack[k].source.name == lines.edges[i].source.name && totalAttacks[h].attack[k].target.name == lines.edges[i].target.name) {//We see if there exsist the same edge in our lines
                                    //we only add attacks to the existing edge
                                    lines.edges[i].attacksId.push(h);
                                    lines.edges[i].totalProbability += parseFloat(totalAttacks[h].probability);
                                    continue pathloop; //to skip adding new new edge to lines
                                }
                            }
                            //if there is no edge, we add new new edge to lines
                            if (totalAttacks[h].attack[k].target.name != "x") { //if not the last node though
                                lines.edges.push({
                                    source: getNode(s),
                                    target: getNode(t),
                                    edgeId: id + replacePoints(s) + "-" + replacePoints(t),
                                    strokeWidth: 2,
                                    totalProbability: parseFloat(totalAttacks[h].probability),
                                    attacksId: [h]
                                });
                            }
                        }
                    }
                    //update stroke widths on base of number attacks going through the edge
                    var maxProbability = 0;
                    lines.edges.forEach(function (d) {
                        if (d.totalProbability > maxProbability)
                            maxProbability = d.totalProbability;
                    });
                    var scaleStrokeWidth = d3.scale.linear()
                            .domain([0, .5, .51, maxProbability])
                            .range([0, 0, 3, 12]);
                    lines.edges.forEach(function (d) {
                        console.log(d.totalProbability);
                        d.strokeWidth = scaleStrokeWidth(d.totalProbability);
                    });
                    var maxAttacks = 0;
                    lines.edges.forEach(function (edge) {
                        if (edge.attacksId.length > maxAttacks)
                            maxAttacks = edge.attacksId.length;
                    });
                    var scaleRadius = d3.scale.linear()
                            .domain([1, maxAttacks])
                            .range([nodeRadius, 20]);
                    lines.edges.forEach(function (edge) {
                        d3.selectAll(".node")
                                .filter(function (node) {
                                    return node.name == edge.target.name;
                                })
                                .select("circle")
                                .attr("r", scaleRadius(edge.attacksId.length))
                                .style("fill", "#f00")
                                .attr("stroke", "#3d3d3d")
                                .attr("stroke-width", "1px");
                    });
                    d3.selectAll(".node")
                            .filter(function (node) {
                                return node.name == activeNode;
                            })
                            .select("circle")
                            .attr("r", 10)
                            .style("fill", "yellow")
                            .attr("stroke", "#3d3d3d")
                            .attr("stroke-width", "2px");
                    drawGraph(lines);
                    //createBarriers(lines);
                }
            }


            /**
             * Draws graph lines
             * @param {type} lines
             * @param {type} animationDuration
             * @returns {undefined}
             */
            function drawGraph(lines, animationDuration) {
                layer.select("#links").append("svg:g")
                        .selectAll("path")
                        .data(lines.edges)
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
                                    dr = Math.sqrt(dx * dx + dy * dy) * lines.radiusMagnifier;
                            return "M" +
                                    x1 + "," +
                                    y1 + "A" +
                                    dr + "," + dr + " 0 0,1 " +
                                    x2 + "," +
                                    y2;
                        })
                        .attr("class", lines.class)
                        .attr("id", function (d) {
                            return d.edgeId;
                        })
                        .style("stroke-width", function (d) {
                            return d.strokeWidth;
                        })
                        .attr("marker-end", function (d) {
                            if (d.strokeWidth > 0 && !animationDuration)
                                return "url(#" + lines.class + "Marker)";
                        })
                        .each(function () {
                            if (!!animationDuration) {
                                var totalLength = this.getTotalLength();
                                d3.select(this)
                                        .attr("stroke-dasharray", totalLength + " " + totalLength)
                                        .attr("stroke-dashoffset", totalLength)
                                        .transition()
                                        .duration(animationDuration)
                                        .ease("linear")
                                        .attr("stroke-dashoffset", 0)
                                        .each("end", function () {
                                            d3.select(this)
                                                    .attr("marker-end", function (d) {
                                                        if (d.strokeWidth > 0)
                                                            return "url(#" + lines.class + "Marker)";
                                                    });
                                        });
                            }
                        }
                        );
//                        .style({
//                        "stroke-dasharray": "1000",
//                                "stroke-dashoffset": "1000",
//                                "animation": "dash 5s linear forwards"
//                        });
            }

            function createBarriers(lines) {
                var barriers = [];
                lines.edges.forEach(function (edge) {
                    if (edge.strokeWidth > 0) {
                        var barrierData = [];
                        edge.attacksId.forEach(function (attackId) {
                            barrierData.push({
                                attackId: attackId,
                                barrier: computeBarrier(attackId, edge.source.name, edge.target.name)
                            });
                        });
                        barriers.push({
                            sourceNode: edge.source,
                            targetNode: edge.target,
                            barrierData: barrierData,
                            barrierPosition: []
                        });
                    }
                });
                if (mode == 1) {

                    d3.selectAll(".barrier")
                            .filter(function (d) {
                                return !d.position.onEdgeFlag;
                            })
                            .each(function (d, i) {
                                d3.select(this).on("click").apply(this, [d, i]);
                            });
                    d3.selectAll(".barrier")
                            .transition()
                            .duration(500)
                            .style("fill-opacity", 0)
                            .style("stroke-opacity", 0)
                            .transition()
                            .style("display", "none");
                }
                drawBarrier(barriers, lines.class);
            }

            function computeBarrier(index, sourceNodeName, targetNodeName)
            {
                var result = [];
                var activeResponse = totalResponse[index]["response-plan"];
                for (var k = 0; k < activeResponse.length; k++)
                {
                    if ((activeResponse[k].mitigation.edge.source === sourceNodeName) && (activeResponse[k].mitigation.edge.target === targetNodeName)) {
                        if (parseInt(k / 5) === k / 5)
                            activeResponse[k].duration = Math.round((Math.random() * 100000) + 1);
                        else
                            activeResponse[k].duration = Math.round((Math.random() * 10000) + 1);
                        result.push(activeResponse[k]);
                    }
                }
                return result;
            }

            /**
             * Transform oject of nodes into array on IP adresses
             * @param {type} attackArraylines
             */
            function getAttackArray(attackArraylines)
            {
                var result = [];
                for (i = 0; i < attackArraylines.length; i++)
                {
                    if (i == 0)
                    {
                        result.push(attackArraylines[i].source.name);
                        result.push(attackArraylines[i].target.name);
                    }
                    else if (attackArraylines[i].target.name != "x")
                    {
                        result.push(attackArraylines[i].target.name);
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
                        .outerRadius(radius - wRightMenu * 0.23)
                        .innerRadius(radius - wRightMenu * 0.28);
                var arcOver = d3.svg.arc()
                        .outerRadius(radius - wRightMenu * 0.2)
                        .innerRadius(radius - wRightMenu * 0.31);
                var arcAttack = d3.svg.arc()
                        .outerRadius((radius - wRightMenu * 0.275) - 2)
                        .innerRadius(radius - wRightMenu * 0.32);
                /*var arcAttack = d3.svg.arc()
                 .outerRadius(radius - wRightMenu * 0.175)
                 .innerRadius(radius - wRightMenu * 0.275);*/

                var pie = d3.layout.pie()
                        .sort(null)
                        .value(function (d) {
                            return d.size;
                        });
                var div = d3.select("#donutChartDiv");
                var svg = d3.select("#donutChart").select("g");
                var tableAttack = d3.select(".tableAttack");
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
                                    .style("opacity", lineOpacity)
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
                                    var initArc = d3.svg.arc().startAngle(a.__data__.startAngle + (a.__data__.endAngle - a.__data__.startAngle) * ratio).endAngle(a.__data__.endAngle).outerRadius((radius - wRightMenu * 0.2) + 2)
                                            .innerRadius((radius - wRightMenu * 0.2) + 2);
                                    var endArc = d3.svg.arc().startAngle(a.__data__.startAngle + (a.__data__.endAngle - a.__data__.startAngle) * ratio).endAngle(a.__data__.endAngle).outerRadius((radius - wRightMenu * 0.2) + 2)
                                            .innerRadius(radius - wRightMenu * 0.175);
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
                                var initArc = d3.svg.arc().startAngle(a.__data__.startAngle + (a.__data__.endAngle - a.__data__.startAngle) * ratio).endAngle(a.__data__.endAngle).outerRadius((radius - wRightMenu * 0.2) + 2)
                                        .innerRadius((radius - wRightMenu * 0.2) + 2);
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

            function drawButtons() {

                var divButtons = d3.select("#buttonsDiv");
                divButtons.append("button")
                        .attr("id", "playOneButton")
                        .style("width", "20%")
                        .style("height", "100%")
                        .text("Play 0")
                        .on("click", function () {
                            alertNodes = reactiveAlertNodes;
                            currentPreviewIndex++;
                            if (currentPreviewIndex >= alertNodes.length) {
                                currentPreviewIndex = -2;
                                d3.select(this).text("Clear");
                            }
                            else if (currentPreviewIndex == -1) {
                                removeAllElements();
                            }
                            else {
                                attackAlert(currentPreviewIndex, 3000);
                                d3.select(this).text("Play " + currentPreviewIndex);
                                d3.select(this).property("disabled", true);
                            }
                        });
                divButtons.append("button")
                        .attr("id", "playAllButton")
                        .style("width", "20%")
                        .style("height", "100%")
                        .text("Play all")
                        .on("click", function () {
                            d3.select(this).property("disabled", true);
                            alertNodes = reactiveAlertNodes;
                            removeAllElements();
                            var duration = 1000;
                            for (var indexOfPreview = 0; indexOfPreview < alertNodes.length; indexOfPreview++) {
                                attackAlert(indexOfPreview, duration, duration * indexOfPreview + 100);
                                currentPreviewIndex = indexOfPreview; //TODO: currentPreviewIndex should be set inside attack alert with appropriate timeout
                            }
                        });
                divButtons.append("button")
                        .style("width", "20%")
                        .style("height", "100%")
                        .text("Reset")
                        .on("click", function () {
                            //location.reload();
                            removeAllElements();
                            currentPreviewIndex = 0;
                        });
                divButtons.append("button")
                        .style("width", "20%")
                        .style("height", "100%")
                        .text("Social")
                        .on("click", function () {
                            social();
                        });
            }

            function drawResponsePlanPreview(rightMenuContainer) {
                var filterArray = [1, 1, 1];
                var divResponsePlan = rightMenuContainer.append("div")
                        .attr("id", "responsePlanDiv")
                        .attr("class", "flexcontainer flexfill");
//                        .style("height", h - 32 - 5 * 5 + "px")
//                        .style("background-color", "#3d3d3d");
                var responsePlanHeader = divResponsePlan.append("div")
                        .attr("id", "responsePlanHeader");
                var responsePlanBody = divResponsePlan.append("div")
                        .attr("id", "responsePlanBody")
                        .attr("class", "flexcontainer flexfill");
                responsePlanHeader.append("p")
                        .text("Response Plan");
                var barrierDetailsArea = responsePlanBody.append("div")
                        .attr("id", "barrierDetailsArea")
                        .attr("class", "flexcontainer flexfill");
                var barrierDetailsHeader = barrierDetailsArea.append("div")
                        .attr("id", "barrierDetailsHeader");
                var barrierDetailsBody = barrierDetailsArea
                        .append("div")
                        .attr("id", "barrierDetailsBodyContainer")
                        .attr("class", "flexfill")
                        .append("div")
                        .attr("id", "barrierDetailsBody");
                var barrierDetailsHeaderResponsePlanContainer = barrierDetailsHeader.append("div")
                        .attr("id", "barrierDetailsHeaderResponsePlanContainer")
                        .attr("align", "left");
                //================================

                var summary = barrierDetailsHeaderResponsePlanContainer.append("div")
                        .attr("id", "responsePlanSummary");
                summary.append("text")
                        .text("Status:");
                summary.append("text")
                        .attr("id", "responsePlanStatusPercent")
                        .text("--%");
                summary.append("text")
                        .attr("id", "responsePlanStartTime")
                        .text("Start: --:-- --/--/----");
                summary.append("text")
                        .attr("id", "responsePlanEndTime")
                        .text("End: --:-- --/--/----");
                var responsePlanData = barrierDetailsHeaderResponsePlanContainer.append("div")
                        .attr("id", "responsePlanData");
                responsePlanData.append("text")
                        .attr("id", "responsePlanNodeIP")
                        .text("Node IP: __.__.__");
                responsePlanData.append("text")
                        .attr("id", "responsePlanSourceSelectTitle")
                        .text("Edge from: ");
                responsePlanData.append("select")
                        .attr("id", "responsePlanSourceSelect")
                        .append("option")
                        .text("select barrier");
                var responsePlanDataButtonDiv = responsePlanData.append("div");
                responsePlanDataButtonDiv.append("button")
                        .text("Stop")
                        .property("disabled", false); // m.mitigation.status == "failed" ? false : true);
                responsePlanDataButtonDiv.append("button")
                        .text("Apply")
                        .property("disabled", false); // m.mitigation.status == "success" || m.mitigation.status == "inactive" ? false : true);
                //=================================
                var barrierDetailsHeaderAllBarriersContainer = barrierDetailsHeader.append("div")
                        .attr("id", "barrierDetailsHeaderAllBarriersContainer")
                        .attr("align", "left");
                var barrierDetailsHeaderAllBarriersContainerDiv = barrierDetailsHeaderAllBarriersContainer.append("div")
                        .attr("align", "center");
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                barrierDetailsHeaderAllBarriersContainerDiv
                        .append("div")
                        .append("div")
                        .append("svg")
                        .attr("width", barrierWidth)
                        .attr("height", barrierHeight);
                var barrierDetailsHeaderBarrierContainer = barrierDetailsHeader.append("div")
                        .attr("id", "barrierDetailsHeaderBarrierContainer")
                        .attr("align", "left");
                barrierDetailsHeaderBarrierContainer.append("div")
                        .style("width", "30%")
                        .style("height", "100%")
                        .attr("align", "center")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("border-right-color", "white")
                        .style("border-right-style", "dotted")
                        .style("border-right-width", "1px")
                        .append("div")
                        .style("border-color", "#7A7A7A")
                        .style("border-style", "solid")
                        .style("border-width", "1px")
                        .style("border-radius", "2px")
                        .style("width", barrierWidth + 4 + "px")
                        .style("height", barrierHeight + 4 + "px")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .append("svg")
                        .attr("id", "barrierDetailsHeaderSVGforBarrier")
                        .attr("width", barrierWidth + 4 + "px")
                        .attr("height", barrierHeight + 4 + "px");
                var detailsHeaderSummary = barrierDetailsHeaderBarrierContainer.append("div")
                        .attr("id", "barrierDetailsHeaderBarrierSummary")
                        .attr("align", "center");
                var containerDiv = detailsHeaderSummary.append("div")
                        .style("height", "50%")
                        .attr("align", "center");
                var div = containerDiv
                        .append("span")
                        .style("background-color", "red")
                        .append("div");
//                div.append("div")
//                        .style("width", "30%")
//                        .style("display", "table-cell")
//                        .style("vertical-align", "middle")
//                        .append("text")
//                        .attr("class", "barrierDetailsHeaderBarrierSummaryTitle")
//                        .style("margin-left", "10px")
//                        .text("Failed:");
                div.append("div")
                        .style("width", "50%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("text-align", "center")
                        .append("text")
                        .attr("class", "barrierDetailsHeaderBarrierSummaryValue")
                        .attr("id", "barrierDetailsHeaderBarrierSummaryValueFail")
                        .text("--/---");
                div.append("div")
                        .style("width", "20%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("text-align", "center")
                        .append("input")
                        .attr("type", "checkbox")
                        .property("disabled", true)
                        .on("change", function () {
                            filterArray[0] = this.checked;
                        })
                        .on("mouseover", function () {
                            filterBarrierDetailsBody([1, 0, 0]);
                        })
                        .on("mouseout", function () {
                            filterBarrierDetailsBody(filterArray);
                        });
//               ----------------------- 
                var div = containerDiv
                        .append("span")
                        .style("background-color", "green")
                        .append("div");
//                div.append("div")
//                        .style("width", "20%")
//                        .style("display", "table-cell")
//                        .style("vertical-align", "middle")
//                        .append("text")
//                        .attr("class", "barrierDetailsHeaderBarrierSummaryTitle")
//                        .style("margin-left", "10px")
//                        .text("Success:");
                div.append("div")
                        .style("width", "60%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("text-align", "center")
                        .append("text")
                        .attr("class", "barrierDetailsHeaderBarrierSummaryValue")
                        .attr("id", "barrierDetailsHeaderBarrierSummaryValueSuccess")
                        .text("--/---");
                div.append("div")
                        .style("width", "20%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("text-align", "center")
                        .append("input")
                        .attr("type", "checkbox")
                        .property("disabled", true)
                        .on("change", function () {
                            filterArray[1] = this.checked;
                        })
                        .on("mouseover", function () {
                            filterBarrierDetailsBody([0, 1, 0]);
                        })
                        .on("mouseout", function () {
                            filterBarrierDetailsBody(filterArray);
                        });
//               ----------------------- 
                var div = containerDiv
                        .append("span")
                        .style("background-color", "gray")
                        .append("div");
//                div.append("div")
//                        .style("width", "30%")
//                        .style("display", "table-cell")
//                        .style("vertical-align", "middle")
//                        .append("text")
//                        .attr("class", "barrierDetailsHeaderBarrierSummaryTitle")
//                        .style("margin-left", "10px")
//                        .text("Inactive:");
                div.append("div")
                        .style("width", "50%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("text-align", "center")
                        .append("text")
                        .attr("class", "barrierDetailsHeaderBarrierSummaryValue")
                        .attr("id", "barrierDetailsHeaderBarrierSummaryValueInactive")
                        .text("--/---");
                div.append("div")
                        .style("width", "20%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .style("text-align", "center")
                        .append("input")
                        .attr("type", "checkbox")
                        .property("disabled", true)
                        .on("change", function () {
                            filterArray[2] = this.checked;
                        })
                        .on("mouseover", function () {
                            filterBarrierDetailsBody([0, 0, 1]);
                        })
                        .on("mouseout", function () {
                            filterBarrierDetailsBody(filterArray);
                        });
                barrierDetailsBody.append("div")
                        .attr("id", "detailsHint")
                        .style("display", "table")
                        .style("text-align", "center")
                        .style("height", "100%")
                        .style("width", "100%")
                        .append("div")
                        .style("height", "100%")
                        .style("display", "table-cell")
                        .style("vertical-align", "middle")
                        .append("text")
                        .style("font", "17px sans-serif")
                        .style("color", "white")
                        .text("Please choose a barrier to see data");
            }

            function removeGraphAndChart(index) {
                //reset all lines
                layer.selectAll("#lineStaticAttack" + index).remove();
                d3.selectAll(".barrier").remove();
                d3.select("#svgTable_" + index).remove();
            }

            function drawMostProbableAttack(activeNode) {
                var mostProbableAttackId,
                        maxProbability = 0;
                totalAttacks.forEach(function (attack, index) {
                    for (var i = 0; i < attack.attack.length; i++) {
                        if (attack.attack[i].source.name == activeNode) {
                            if (attack.probability > maxProbability) {
                                maxProbability = attack.probability;
                                mostProbableAttackId = index;
                            }
                            break;
                        }
                    }
                });
                d3.select(".tableAttack").selectAll("svg").remove();
                queueSVG = [];
                createChart(mostProbableAttackId);
                createGraph(null, mostProbableAttackId, 1); // 1 means is an istantiateOnGoing graph
                $(".bottomMenu").animate({scrollLeft: $("#attackPreview_" + mostProbableAttackId).position().left}, 300);
                d3.select("#attackPreview_" + mostProbableAttackId)
                        .style("border-color", "red");
                d3.select("#playOneButton").property("disabled", false);
                if (alertNodes.indexOf(activeNode) == alertNodes.length - 1)
                    d3.select("#playAllButton").property("disabled", false);
            }

            function clearProbableAttack() {
                d3.selectAll(".lineInstantiateOnGoingAttack").remove();
                layer.selectAll(".line").style("opacity", lineOpacity);
                d3.select(".bottomMenu").selectAll(".attackPreview").style("border-color", "white");
                $(".bottomMenu").animate({scrollLeft: "0px"}, 100);
            }

            function reactive() {
                mode = 1;
                removeAllElements();
            }

            function proactive() {
                mode = 0;
                removeAllElements();
                d3.selectAll(".attackPreview").style("border-color", "#fff");
            }

            function social() {
                mode = 2;
                removeAllElements();
                createGraph(null, 0, 4);
            }

            function drawPreviews() {
                for (var indexOfPreview = 0; indexOfPreview < totalAttacks.length; indexOfPreview++) {
                    var attackPreviewDiv = d3.select(".bottomMenu").append("div")
                            .attr("class", "attackPreview")
                            .attr("id", "attackPreview_" + indexOfPreview)
                            .style("width", wAttackPreview + "px")
                            .style("height", "98%")
                            .style("position", "relative")
                            .style("border-color", "white");
                    attackPreviewDiv.append("svg")
                            .style("width", wAttackPreview + "px")
                            .style("height", hSVGPreview + "px")
                            .attr("class", "SVGPreview");
                    attackPreviewDiv.append("div")
                            .attr("id", "attackPreviewHeader_" + indexOfPreview)
                            .style("height", hPreviewHeaderDiv + "px")
                            .style("width", wAttackPreview + "px")
                            .style("position", "absolute")
                            .style("top", "0px");
                    var svgPreview = attackPreviewDiv.select("svg");
                    svgPreview.on("click", function () {
                        //delete temporary accumulate arcs
                        d3.selectAll("#tempArc").remove();
                        //if we are in proactive mode we add the graphs on the map
                        if (mode == 0 || mode == 2) {
                            var div = d3.select(d3.select(this).node().parentNode);
                            var index = (div.attr("id")).match(/[0-9]+/)[0];
                            if (div.style("border-top-color") == "rgb(255, 255, 255)") {
                                div.style("border-color", "yellow");
                                if (queueSVG.length == 0) {
                                    createChart(index);
                                    createGraph(null, index, 0);
                                }
                                else {
                                    //set last svg display property to none 
                                    var last = queueSVG[queueSVG.length - 1];
                                    d3.select("#svgTable_" + last).attr("display", "none");
                                    //add new chart
                                    createChart(index);
                                    createGraph(null, index, 0);
                                }
                                queueSVG.push(index);
                            }
                            else {
                                div.style("border-color", "white");
                                removeGraphAndChart(index);
                                //layer.selectAll("#lineStaticAttack" + index).remove();
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
                    drawPreviewGraph(indexOfPreview, svgPreview);
                }
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

            function getNode(nodeName)
            {
                for (var k = 0; k < totalNode.length; k++)
                {
                    if (totalNode[k].name === nodeName)
                        return totalNode[k];
                }
                console.warn("(!) getNode(node): node " + nodeName + " is not found in totalNode");
            }

            /**
             * Draws barrier rectangles
             * @param {type} barriers
             * @param {type} edgeClass
             * @returns {undefined}
             */
            function drawBarrier(barriers, edgeClass)
            {
                for (var j = 0; j < barriers.length; j++) {
                    var rectWidth = 12;
                    var rectHeight = 60;
                    var rectStandoff = 25;
                    var magnifierFactor = 1.5;
                    var smallEdgeShifting = 0;
                    //count mitigations from all attacks for every attack edge
                    var mitigations = {
                        actions: [],
                        position: [],
                        sourceNode: barriers[j].sourceNode,
                        targetNode: barriers[j].targetNode
                    };
                    for (var i = 0; i < barriers[j].barrierData.length; i++) {
                        mitigations.actions = mitigations.actions.concat(barriers[j].barrierData[i].barrier);
                    }

                    //lets find position data for barrier rectangles
                    var positionData;
                    layer.selectAll("." + edgeClass)
                            .filter(function (d) {
                                return d.source.name == barriers[j].sourceNode.name && d.target.name == barriers[j].targetNode.name;
                            })
                            .each(function () {
                                var l = this.getTotalLength();
                                if (l - rectStandoff - 10 < rectHeight) {//if rectange doesnt fit line
                                    rectHeight = l - rectStandoff - 10; //11 alerted node radius
                                    //smallEdgeShifting = 10;
                                }
                                var p1 = this.getPointAtLength(l - rectStandoff);
                                var p2 = this.getPointAtLength(l - rectStandoff - rectHeight); // TODO: make secobd it not fixed
                                var dY = p1.y - p2.y;
                                var dX = p1.x - p2.x;
                                var angleInDegrees = (Math.atan2(dY, dX) / Math.PI * 180.0) + 90;
                                positionData = {
                                    startPoint: p1,
                                    smallEdgeShifting: smallEdgeShifting,
                                    angleInDegrees: angleInDegrees,
                                    onEdgeFlag: true,
                                    outOfEdgePosition: {x: null, y: null}
                                };
                                mitigations.position = positionData;
                            });

                    var g = layer.select("#barriers").append("g")
                            .datum(mitigations)
                            .attr("class", "barrier")
                            .attr("id", "barrier-" + replacePoints(mitigations.sourceNode.name) + "-" + replacePoints(mitigations.targetNode.name))
                            .style("cursor", "pointer")
                            .attr("transform", "translate(" +
                                    (mitigations.position.startPoint.x - rectWidth / 2) +
                                    "," + (mitigations.position.startPoint.y) +
                                    ") rotate(" + mitigations.position.angleInDegrees + " " + rectWidth / 2 + " 0)")
                            .on("mouseover", function (d) {
                                if (d.position.onEdgeFlag) {
                                    if (d.sourceNode.name != alertNodes[currentPreviewIndex]) {
                                        d3.select(this)
                                                .style("fill-opacity", 0.5)
                                                .style("stroke-opacity", 0.5)
                                                .style("display", "initial");
                                    }
                                    d3.select(this).transition()
                                            .duration(200)
                                            .attr("transform", "translate(" +
                                                    (d.position.startPoint.x - rectWidth / 2 * magnifierFactor) +
                                                    "," + d.position.startPoint.y +
                                                    ") rotate(" + d.position.angleInDegrees + " " +
                                                    rectWidth / 2 * magnifierFactor +
                                                    " 0) scale(" + magnifierFactor + ")");
                                }
                            })
                            .on("mouseout", function (d) {
                                if (d.position.onEdgeFlag) {
                                    d3.select(this).transition()
                                            .duration(200)
                                            .attr("transform", "translate(" +
                                                    (d.position.startPoint.x - rectWidth / 2) +
                                                    "," + (d.position.startPoint.y) +
                                                    ") rotate(" + d.position.angleInDegrees + " " +
                                                    rectWidth / 2 + " 0)")
                                            .each("end", function () {
                                                if (d.sourceNode.name != alertNodes[currentPreviewIndex]) {
                                                    d3.select(this)
                                                            .style("fill-opacity", 0)
                                                            .style("stroke-opacity", 0)
                                                            .style("display", "none");
                                                }
                                            });

                                }
                            })
                            .on("click", function (d) {
                                var self = this;
                                var barrierTransitionDuration = 300;
                                if (d.position.onEdgeFlag) {

                                    //if there are bariers yet, call click() to put them on graph
                                    d3.select("#barrierDetailsHeaderSVGforBarrier").selectAll("g")
                                            .each(function (d, i) {
                                                d3.select(this).on("click").apply(this, [d, i]);
                                            });
                                    //turn rectangle to get screen coordinates
                                    d3.select(this).attr("transform", "translate(" +
                                            (d.position.startPoint.x - rectWidth / 2) +
                                            "," + (d.position.startPoint.y) +
                                            ")");
                                    var barrierDetailsHeaderSVGforBarrier = document.getElementById("barrierDetailsHeaderSVGforBarrier");
                                    var rect = barrierDetailsHeaderSVGforBarrier.getBoundingClientRect();
                                    var bar = this.getBoundingClientRect();
                                    //turn rect back
                                    d3.select(this).attr("transform", "translate(" +
                                            (d.position.startPoint.x - rectWidth / 2) +
                                            "," + (d.position.startPoint.y) +
                                            ") rotate(" + d.position.angleInDegrees + " " + rectWidth / 2 +
                                            " 0) scale(" + magnifierFactor + ")");
                                    var offsetX = rect.left - bar.left;
                                    var offsetY = rect.top - bar.top;
                                    d.position.outOfEdgePosition.x = d.position.startPoint.x + offsetX;
                                    d.position.outOfEdgePosition.y = d.position.startPoint.y + offsetY;
                                    d3.select(this).transition()
                                            .duration(barrierTransitionDuration)
                                            .attr("transform", "translate("
                                                    + (offsetX + d.position.startPoint.x) + ","
                                                    + (offsetY + d.position.startPoint.y) + ") scale(2)");
                                    setTimeout(function () {
                                        $(self).appendTo("#barrierDetailsHeaderSVGforBarrier");
                                        mitigationsPreview([d]);
                                        setTimeout(function () {
                                            d3.select(self).transition()
                                                    .attr("transform", "translate(2,2) scale(1)")
                                                    .selectAll("rect")
                                                    .attr("x", 0);
                                            d.position.onEdgeFlag = false;
                                        }, 50);
                                    }, barrierTransitionDuration);
                                }
                                else {
                                    clearMitigationPreview();
                                    d.position.onEdgeFlag = true;
                                    $(self).appendTo(".overlayedSVG");
                                    d3.select(self)
                                            .attr("transform", "translate("
                                                    + d.position.outOfEdgePosition.x + ","
                                                    + d.position.outOfEdgePosition.y + ") scale(3)");
                                    d3.select(self).transition()
                                            .duration(barrierTransitionDuration)
                                            .attr("transform", "translate(" +
                                                    (d.position.startPoint.x - rectWidth / 2) +
                                                    "," + (d.position.startPoint.y) +
                                                    ") rotate(" + d.position.angleInDegrees + " " +
                                                    rectWidth / 2 + " 0)")
                                            .selectAll("rect")
                                            .attr("x", d.position.smallEdgeShifting);
                                }
                            });
                    g.append("svg:rect")
                            .attr("class", "inactiveBarrierBar")
                            .attr("x", smallEdgeShifting)
                            .attr("width", rectWidth)
                            .attr("height", 0)
                            .style("fill", "gray");
                    g.append("svg:rect")
                            .attr("class", "failedBarrierBar")
                            .attr("x", smallEdgeShifting)
                            .attr("width", rectWidth)
                            .attr("height", 0)
                            .style("fill", "red");
                    g.append("svg:rect")
                            .attr("class", "successBarrierBar")
                            .attr("x", smallEdgeShifting)
                            .attr("width", rectWidth)
                            .attr("height", 0)
                            .style("fill", "green");
                    g.append("svg:rect")
                            .attr("class", "frameBarrierBar")
                            .attr("x", smallEdgeShifting)
                            .attr("width", rectWidth)
                            .attr("height", 0)
                            .style("fill", "none")
                            .style("stroke", "black")
                            .style("stroke-width", "1px");
                    g.select(".frameBarrierBar")
                            .transition()
                            .duration(500)
                            .attr("height", rectHeight);
                    g.select(".inactiveBarrierBar")
                            .transition()
                            .duration(500)
                            .attr("height", rectHeight)
                            .each("end", function (d) {
                                executeMitigations(d);
                            });
                }
            }

            function executeMitigations(mitigations) {
                for (var i = 0; i < mitigations.actions.length; i++)
                {
                    if (mitigations.actions[i].mitigation.status === "success" || mitigations.actions[i].mitigation.status === "failed") {
                        mitigations.actions[i].startTime = new Date();
                        setTimeout(executeMitigationOnEnd, mitigations.actions[i].duration, i, mitigations);
                    }
                }
            }

            function executeMitigationOnEnd(index, mitigations) {
                if (!mitigations.actions[index].endTime) {
                    mitigations.actions[index].endTime = new Date();
                    var barrierElement = d3.select("#" + "barrier-" + replacePoints(mitigations.sourceNode.name) + "-" + replacePoints(mitigations.targetNode.name));
                    barrierElement.datum(mitigations);
                    updateBarrier(barrierElement);
                    if (!mitigations.position.onEdgeFlag) {
//                        clearMitigationPreview();
//                        mitigationsPreview([barrier]);
                        updateMitigationsPreview(mitigations.actions[index]);
                    }
                }
            }

            function updateBarrier(barrierElement) {
                barrierElement.each(function (barrier) {
                    var self = this;
                    //count all states of mitifation action 
                    var success = 0;
                    var failed = 0;
                    for (var m = 0; m < barrier.actions.length; m++)
                    {
                        if (barrier.actions[m].mitigation.status === "success" && !!barrier.actions[m].endTime)
                            success = success + 1;
                        if (barrier.actions[m].mitigation.status === "failed" && !!barrier.actions[m].endTime)
                            failed = failed + 1;
                    }
                    var inactive = barrier.actions.length - success - failed;
                    var heightScale = d3.scale.linear()
                            .domain([0, barrier.actions.length])
                            .range([0, barrierElement.select(".frameBarrierBar").node().getBBox().height]);
                    d3.select(self).each(function (d, i) {
                        d3.select(this).on("mouseover").apply(this, [d, i]);
                    });
                    d3.select(self).select(".frameBarrierBar")
                            .transition()
                            .duration(200)
                            .style("stroke", "#FFDE80")
                            .style("stroke-width", "2px")
                            .transition()
                            .duration(300)
                            .style("stroke", "black")
                            .style("stroke-width", "1px");
                    d3.select(self).select(".failedBarrierBar")
                            .transition()
                            .duration(500)
                            .attr("height", heightScale(failed));
                    d3.select(self).select(".successBarrierBar")
                            .transition()
                            .duration(500)
                            .attr("y", heightScale(failed))
                            .attr("height", heightScale(success))
                            .each("end", function () {
                                d3.select(self).each(function (d, i) {
                                    d3.select(this).on("mouseout").apply(this, [d, i]);
                                });
                            });
                }
                );
            }

            function mitigationsPreview(mitigations)
            {
                d3.select("#detailsHint")
                        .style("height", "0")
                        .style("display", "none");
                //count all states of mitifation action 
                var success = 0;
                var failed = 0;

                var allActions = [];
                for (var i = 0; i < mitigations.length; i++) {
                    allActions = allActions.concat(mitigations[i].actions); //we take all acrions brom all barriers
                }
                allActions
                        .sort(function (a, b) {
                            if (!!a.endTime && !!b.endTime)
                                return d3.ascending(a.endTime, b.endTime);
                            else if (!!a.endTime && !b.endTime)
                                return -1;
                            else if (!a.endTime && !!b.endTime)
                                return 1;
                            else if (!a.endTime && !b.endTime)
                                return d3.ascending(a.startTime, b.startTime);
                        });
                var startRPTime = allActions[0].startTime;
                var endRPTime = allActions[0].endTime;
                for (var m = 0; m < allActions.length; m++)
                {
                    if (allActions[m].mitigation.status === "success" && !!allActions[m].endTime)
                        success = success + 1;
                    if (allActions[m].mitigation.status === "failed" && !!allActions[m].endTime)
                        failed = failed + 1;
                    if (!!allActions[m].endTime && allActions[m].endTime > endRPTime)
                        endRPTime = allActions[m].endTime;
                    if (!!allActions[m].startTime && allActions[m].startTime < startRPTime)
                        startRPTime = allActions[m].startTime;
                }
                d3.select("#responsePlanNodeIP").text("Node IP: " + mitigations[0].targetNode.name); ///TODO:  common targetNode 
                d3.select("#responsePlanSourceSelectTitle").text(mitigations.length + (mitigations.length > 1 ? " edges" : " edge") + " from:");
                for (var i = 0; i < mitigations.length; i++) {
                    d3.select("#responsePlanSourceSelect").append("option")
                            .text(mitigations[i].sourceNode.name)
                            .property("value", mitigations[i].sourceNode);
                }
                d3.select("#barrierDetailsHeaderBarrierSummary").selectAll("input")
                        .property("checked", true)
                        .property("disabled", false);

                updateMitigationsPreviewSummary(success, failed, allActions.length, startRPTime, endRPTime);

                allActions.forEach(function (m) {
                    var mitigationItem = {
                        m: m,
                        displayBody: "none"
                    };
                    createMitigationItem(mitigationItem);
                });
            }

            function updateMitigationsPreviewSummary(success, failed, all, startRPTime, endRPTime) {
                d3.select("#responsePlanStatusPercent").text(Math.round(success / all * 100) + "%");
                d3.select("#barrierDetailsHeaderBarrierSummaryValueFail").text(failed + "/" + all);
                d3.select("#barrierDetailsHeaderBarrierSummaryValueSuccess").text(success + "/" + all);
                d3.select("#barrierDetailsHeaderBarrierSummaryValueInactive").text(all - failed - success + "/" + all);
                d3.select("#responsePlanStartTime").text("Start: " + getDateTime(startRPTime));
                d3.select("#responsePlanEndTime").text("End: " + getDateTime(endRPTime));
            }

            function createMitigationItem(mitigationItem) {
                var colorScale = d3.scale.ordinal()
                        .domain(["success", "failed", "processing"])
                        .range(["green", "red", "gray"]);
                var detailsBody = d3.select("#barrierDetailsBody");
                var detailsItem = detailsBody.append("div")
                        .attr("class", "detailsItemDiv")
                        .datum(mitigationItem);
                var detailsItemHeader = detailsItem.append("div")
                        .attr("class", "detailsItemHeader")
                        .attr("align", "left")
                        .on("click", function (d) {
                            d.displayBody = d.displayBody == 'table' ? 'none' : 'table';
                            if (d.displayBody == 'table') {
                                d3.select(this.parentNode)
                                        .transition()
                                        .duration(100)
                                        .style("height", '130px')
                                        .each("end", function () {
                                            d3.select(this).select(".detailsItemBody")
                                                    .style("display", d.displayBody);
                                        });
                            }
                            else {
                                d3.select(this.parentNode).select(".detailsItemBody")
                                        .style("display", d.displayBody);
                                d3.select(this.parentNode).transition()
                                        .duration(100)
                                        .style("height", '20px');
                            }
                        });
                var svg = detailsItemHeader.append("svg")
                        .attr("height", "20px");
                svg.append("svg:circle")
                        .attr("cx", 10)
                        .attr("cy", 10)
                        .attr("r", 7)
                        .style("fill", !!mitigationItem.m.endTime ? colorScale(mitigationItem.m.mitigation.status) : colorScale("processing"));
                svg.append("text")
                        .attr("x", 25)
                        .attr("y", 15)
                        .text(mitigationItem.m.mitigation.name);
                var detailsItemBody = detailsItem.append("div")
                        .attr("class", "detailsItemBody");
                var summary = detailsItemBody.append("div")
                        .attr("class", "detailsItemBodySummary");
                summary.append("text")
                        .text("Status:")
                        .style('display', 'block');
                var summarySvg = summary.append("svg")
                        .attr("height", "30px")
                        .attr('width', '80px');
                summarySvg.append("svg:circle")
                        .attr("cx", 15)
                        .attr("cy", 15)
                        .attr("r", 15)
                        .style("fill", !!mitigationItem.m.endTime ? colorScale(mitigationItem.m.mitigation.status) : colorScale("processing"));
                summarySvg.append("text")
                        .attr("x", 35)
                        .attr("y", 20)
                        .text(!!mitigationItem.m.endTime ? mitigationItem.m.mitigation.status : "processing");
                summary.append("text")
                        .style('display', 'block')
                        .text("Start: " + (!!mitigationItem.m.startTime ? getDateTime(mitigationItem.m.startTime) : "--:-- --/--/----"));
                summary.append("text")
                        .style('display', 'block')
                        .text("End: " + (!!mitigationItem.m.endTime ? getDateTime(mitigationItem.m.endTime) : "--:-- --/--/----"));
                var detailsItemBodyMitigationData = detailsItemBody.append("div")
                        .attr("class", "detailsItemBodyMitigationData");
                detailsItemBodyMitigationData.append("text")
                        .text("ID: " + mitigationItem.m.mitigation.ID);
                detailsItemBodyMitigationData.append("text")
                        .text("Type: " + mitigationItem.m.mitigation.type);
                detailsItemBodyMitigationData.append("text")
                        .text("Source: " + mitigationItem.m.mitigation.edge.source);
                detailsItemBodyMitigationData.append("text")
                        .text("Target: " + mitigationItem.m.mitigation.edge.target);
                var detailsItemBodyMitigationDataButtonDiv = detailsItemBodyMitigationData.append("div");
                detailsItemBodyMitigationDataButtonDiv.append("button")
                        .text("Stop")
                        .property("disabled", !!mitigationItem.m.endTime ? true : false)
                        .on("click", function () {
                            //executeMitigationOnEnd(mitigations[0].actions.indexOf(m), mitigations[0]);
                        });
                detailsItemBodyMitigationDataButtonDiv.append("button")
                        .text("Apply")
                        .property("disabled", !!mitigationItem.m.endTime ? false : true);
            }

            function updateMitigationsPreview(actionToHighlight) {
                var displayBody;
                d3.selectAll(".detailsItemDiv")
                        .filter(function (d) {
                            return actionToHighlight == d.m;
                        })
                        .each(function (d) {
                            displayBody = d.displayBody;
                        })
                        .remove();
                createMitigationItem({
                    m: actionToHighlight,
                    displayBody: displayBody
                });


                d3.selectAll(".detailsItemDiv")
                        .sort(function (a, b) {
                            if (!!a.m.endTime && !!b.m.endTime)
                                return d3.ascending(a.m.endTime, b.m.endTime);
                            else if (!!a.m.endTime && !b.m.endTime)
                                return -1;
                            else if (!a.m.endTime && !!b.m.endTime)
                                return 1;
                            else if (!a.m.endTime && !b.m.endTime)
                                return d3.ascending(a.m.startTime, b.m.startTime);
                        });
                var actionToHighlightElement = d3.selectAll(".detailsItemHeader")
                        .filter(function (d) {
                            return actionToHighlight == d.m;
                        })
                        .each(function (d, i) {
                            if (displayBody != "none") {
                                console.log("displayBody");
                                console.log(displayBody);
                                d3.select(this).on("click").apply(this, [d, i]);
                            }
                        });
                var success = 0;
                var failed = 0;
                var all = 0;
                var startRPTime = actionToHighlight.startTime;
                var endRPTime = actionToHighlight.endTime;
                d3.selectAll(".detailsItemDiv")
                        .each(function (d) {
                            if (d.m.mitigation.status === "success" && !!d.m.endTime)
                                success++;
                            if (d.m.mitigation.status === "failed" && !!d.m.endTime)
                                failed++;
                            if (!!d.m.endTime && d.m.endTime > endRPTime)
                                endRPTime = d.m.endTime;
                            if (!!d.m.startTime && d.m.startTime < startRPTime)
                                startRPTime = d.m.startTime;
                            all++;
                        });
                updateMitigationsPreviewSummary(success, failed, all, startRPTime, endRPTime);
                actionToHighlightElement
                        .transition()
                        .duration(300)
                        .style("fill", "yellow")
                        .style("font-weight", "700")
                        .transition()
                        .delay(1000)
                        .duration(300)
                        .style("fill", "white")
                        .transition()
                        .style("font-weight", "400");
                if (!!($(actionToHighlightElement[0]).offset())) {
                    $("#barrierDetailsBodyContainer").animate(
                            {scrollTop: $(actionToHighlightElement[0]).offset().top - $("#barrierDetailsBodyContainer").offset().top}
                    , 300);
                }
            }

            function filterBarrierDetailsBody(filterArray) {
                d3.select(".detailsItemBody")
                        .style("display", "none");
                d3.selectAll(".detailsItemDiv")
                        .transition()
                        .duration(100)
                        .style("height", "0px")
                        .each("end", function () {
                            d3.select(this).style("display", "none");
                            for (var i = 0; i < filterArray.length; i++) {
                                var filterVariable;
                                switch (i) {
                                    case 0:
                                        filterVariable = "failed";
                                        break;
                                    case 1:
                                        filterVariable = "success";
                                        break;
                                    case 2:
                                        filterVariable = "inprocess";
                                        break;
                                }
                                if (filterArray[i] == 0) {
                                    d3.selectAll(".detailsItemDiv")
                                            .filter(function (d) {
                                                return filterVariable != "inprocess" ? (d.m.mitigation.status == filterVariable) : !d.m.endTime;
                                            }).transition()
                                            .duration(100)
                                            .style("height", "0px")
                                            .each("end", function () {
                                                d3.select(this).style("display", "none");
                                            });
                                }
                                else {
                                    d3.selectAll(".detailsItemDiv")
                                            .filter(function (d) {
                                                return filterVariable != "inprocess" ? (d.m.mitigation.status == filterVariable) : !d.m.endTime;
                                            }).transition()
                                            .duration(100)
                                            .style("height", function (d) {
                                                return d.displayBody == 'table' ? '130px' : '20px';
                                            })
                                            .style("display", "block");
                                    d3.select(".detailsItemBody")
                                            .style("display", function (d) {
                                                return d.displayBody;
                                            });
                                }
                            }
                        });
            }

            function clearMitigationPreview() {

                d3.selectAll(".detailsItemDiv").remove();
                d3.select("#barrierDetailsHeaderBarrierSummary").selectAll("input")
                        .property("checked", false)
                        .property("disabled", true);
                d3.select("#barrierDetailsHeaderBarrierSummaryValueFail").text("--/---");
                d3.select("#barrierDetailsHeaderBarrierSummaryValueSuccess").text("--/---");
                d3.select("#barrierDetailsHeaderBarrierSummaryValueInactive").text("--/---");
                d3.select("#responsePlanStatusPercent").text("--%");
                d3.select("#responsePlanNodeIP").text("Node IP: __.__.__");
                d3.select("#responsePlanSourceSelectTitle").text("Edge from: ");
                d3.select("#responsePlanSourceSelect").selectAll("option").remove();
                d3.select("#responsePlanStartTime").text("Start: --:-- --/--/----");
                d3.select("#responsePlanEndTime").text("End: --:-- --/--/----");
                d3.select("#detailsHint")
                        .style("height", "100%")
                        .style("display", "table");
            }

            /** 
             * Draws red and animates attacked nodes
             * @param {num} indexOfActiveAlertNode Index of chosen preview
             * @param {num} duration
             * @param {num} delay
             * @param {num} attackIndex
             * @returns {undefined}
             */
            function attackAlert(indexOfActiveAlertNode, duration, delay, attackIndex) {//TODO:clean
                setTimeout(function () {
                    if (mode == 1 || mode == 0) {
                        clearProbableAttack();
                        var arcAnimationDuration = duration * 0.2;
                        createGraph(indexOfActiveAlertNode, attackIndex, 2, arcAnimationDuration);
                        setTimeout(function () {
                            var allAlertNodes = alertNodes.slice(0, indexOfActiveAlertNode + 1); //takes first first indexOfActiveAlertNode number of nodes from alert nodes
                            //lets find the nodes and fill them red
                            var activeNode = alertNodes[indexOfActiveAlertNode];
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
                                    .duration(duration * 0.1)
                                    .attr("r", 20)
                                    .style("fill", "red")
                                    .each("end", function () {
                                        d3.select(this)
                                                .transition()
                                                .delay(duration * 0.1)
                                                .duration(duration * 0.1)
                                                .attr("r", 11)
                                                .each("end", function () {
                                                    d3.select(this)
                                                            .attr("stroke", "black")
                                                            .attr("stroke-width", 2);
                                                    if (mode == 1) {
                                                        createGraph(indexOfActiveAlertNode, attackIndex, 3);
                                                        setTimeout(function () {
                                                            drawMostProbableAttack(activeNode);
                                                        }, (duration - 0.1 * 3) / 3);
                                                    }
                                                });
                                    });
                        }, arcAnimationDuration * 1.5);
                    }
                }, delay);
            }
            function getDateTime(date) {
                if (!date) {
                    return "--:-- --/--/----";
                }
                else {
                    var year = date.getFullYear();
                    var month = date.getMonth() + 1;
                    var day = date.getDate();
                    var hour = date.getHours();
                    var minute = date.getMinutes();
                    var second = date.getSeconds();
                    if (month.toString().length == 1) {
                        var month = '0' + month;
                    }
                    if (day.toString().length == 1) {
                        var day = '0' + day;
                    }
                    if (hour.toString().length == 1) {
                        var hour = '0' + hour;
                    }
                    if (minute.toString().length == 1) {
                        var minute = '0' + minute;
                    }
                    if (second.toString().length == 1) {
                        var second = '0' + second;
                    }
                    var dateTime = year + '/' + month + '/' + day + ' ' + hour + ':' + minute + ':' + second;
                    return dateTime;
                }
            }
        </script>

    </body>

</html>
