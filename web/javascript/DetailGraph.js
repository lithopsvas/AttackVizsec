function detailGraph() {
    var width = wSideMenu,
        height = wSideMenu,
        radius = Math.min(width, height) / 1.5,
        graphAttack = [],
        lines = [];

    var array = ["#8dd3c7","#bebada","#80b1d3","#fccde5","#d9d9d9","#bc80bd","#ccebc5","2035FF","0AB26C"];
	var color=d3.scale.ordinal().range(array);
	
    var arc = d3.svg.arc()
        .outerRadius(radius - wSideMenu * 0.2)
        .innerRadius(radius - wSideMenu * 0.25);

    var arcOver = d3.svg.arc()
        .outerRadius(radius - wSideMenu * 0.175)
        .innerRadius(radius - wSideMenu * 0.275);

    var pie = d3.layout.pie()
        .sort(null)
        .value(function(d) {
            return d.size;
        });

    var tableAttack = sideMenu.append("div")
        .attr("class", "tableAttack")
        .style("left", (wSideMenu / 3 - (radius/8)) + "px")
        .style("top", sizeLabel + radius / 5 + "px")
        .style("width", 5*radius / 8 + "px") //radius/2 for rect lenght + radius/8 for shifting when mouseover on arc
        .style("height", radius * 0.1 * 11 + "px")
        .style("max-height", radius * 0.1 * 11 + "px");

    var svg = sideMenu.append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

    d3.select("#attackPreview1")
        .on("click", function() {
            createGraphAttack();

            var path = layer.append("svg:g")
                .selectAll("path")
                .data(lines)
                .enter().append("svg:path")
                .attr("d", function(d) {
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
                .attr("marker-end", "url(#end)");
        })
        .on("dblclick", function() {
            layer.selectAll(".lineStaticAttack")
                .remove();
        });

    var g = svg.selectAll(".arc")
        .data(pie(subnetList))
        .enter().append("g")
        .attr("class", "arc")
        .on("mouseover", function(d) {
            var node = d3.selectAll(".node" + d.data.subnet.replace(/\./g, "_"));
            node.transition()
            .duration(500)
			.style("fill", function() {
                return color(d.data.subnet);
            })
			.attr("r", 9)
			.attr("stroke","#ff0")
			.attr("stroke-width","2px");
			
			var edge = d3.selectAll("#edge" + d.data.subnet.replace(/\./g, "_"))
			.transition()
            .duration(500)
			.style("opacity",1)
			.style("stroke", function() {
            return color(d.data.subnet)
			});
        })
        .on("mouseout", function(d) {
            var node = d3.selectAll(".node" + d.data.subnet.replace(/\./g, "_"));
            node.transition()
            .duration(500)
			.style("fill", "#3d3d3d")
			.attr("r", 7)
			.attr("stroke-width","0px");
			
			var edge = d3.selectAll("#edge" + d.data.subnet.replace(/\./g, "_"))
			.transition()
            .duration(500)
			.style("opacity",0.2)
			.style("stroke", "#000");
        });

    g.append("path")
        .attr("d", arc)
        .style("fill", function(d) {
            return color(d.data.subnet)
        })
        .on("mouseover", function(d) {
			//increase size arc
            d3.select(this).transition()
                .duration(1000)
                .attr("d", arcOver);
			//shift rect of the same color
				shiftRect(d.data.subnet); //and add yellow border too
			//show lines of the nodes
        })
        .on("mouseout", function(d) {
			//restore size arc
            d3.select(this).transition()
                .duration(1000)
                .attr("d", arc);
			//restore shifted rect of the same color	
				restoreSiftedRect(d.data.subnet);
			//restore old lines
        });

    g.append("text")
        .attr("transform", function(d) {
            return "translate(" + arc.centroid(d) + ")";
        })
        .attr("dy", ".35em")
        .style("text-anchor", "middle")
        .html(function(d) {
            return d.data.subnet;
        });
		
		g.append("text")
        .attr("transform", function(d) {
            return "translate(" + arc.centroid(d) + ")";
        })
        .attr("dy", "1.35em")
        .style("text-anchor", "middle")
        .html(function(d) {
            return d.value+"/"+totalNode.length;
        });

    d3.json("json attack/attack3.json", function(source) {
        var yOffset = 0;
        var i = 0;
        var svgTable = tableAttack.append("svg")
            .attr("width", tableAttack.style("width"))
            .attr("height", (parseInt(radius * 0.1) + 1) * source.attack.length);

        source.attack.forEach(function(d) {
            var s_attack = source.attack[i++];
			
            var g1 = svgTable.append("g")
                .attr("transform", "translate("+ radius/8 +"," + yOffset + ")")
				.attr("id","idGTable"+getSubnet(s_attack.source.name).replace(/\./g, "_")) //id will be #idGTable192_168_1
                .on("mouseover", function() {
                    var node = d3.select("#node" + (s_attack.source.name).replace(/\./g, "_"));
                    node.select("circle")
					.transition()
					.duration(500)
					.attr("r",10)
					.attr("stroke","#ff0")
					.style("fill", "#3d3d3d")
					.attr("stroke-width","2px");
					
					var rect = g1.select("rect")
					.attr("stroke","#ff0")
					.attr("stroke-width","1px");
                })
                .on("mouseout", function() {
                    var node = d3.select("#node" + (s_attack.source.name).replace(/\./g, "_"));
                    node.select("circle")
					.transition()
					.duration(500)
					.attr("r",7)
					.style("fill", "#3d3d3d")
					.attr("stroke-width","0px");
					
					var rect = g1.select("rect")
					.attr("stroke-width","0px");
                });

            g1.append("rect")
                .attr("width", radius / 2 + "px")
                .attr("height", radius * 0.1 + "px")
                .attr("fill", function() {
                    return color(getSubnet(s_attack.source.name));
                });

            g1.append("text")
                .attr("dy", "1.50em")
                .style("text-anchor", "middle")
                .style("font", "15px sans-serif")
                .attr("dx", radius / 4)
                .text(function() {
                    return s_attack.source.name;
                });


            yOffset += parseInt(radius * 0.1) + 1;
            graphAttack.push(s_attack.source.name);
        });
        drawPreview(graphAttack);
		drawNodes(graphAttack);
    });

    function getSubnet(s) {
        //console.log(s.match(/[0-9]*\.[0-9]*\.[0-9]*/)[0]);
        return s.match(/[0-9]*\.[0-9]*\.[0-9]*/)[0];
    }

    function createGraphAttack() {
        var index = 0;
        while (index < graphAttack.length) {
            var x1 = graphAttack[index++];
            if (index + 1 > graphAttack.length)
                return;
            var x2 = graphAttack[index];
            var s;
            var t;
            totalNode.forEach(function(d) {
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
    }

    function transformLineAttack(d) { //qui possiamo modificare i singoli archi (colore, larghezza, ecc)
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
	
	function drawNodes(graph){
		var index = 0;
		var wMap = w - wSideMenu - w / 5; //w/5 is space in excess
        var hMap = h - hBottomMenu;
        var wSVGPreview = wAttackPreview;
        var hSVGPreview = hBottomMenu;
		var svgPreview = d3.select("#attackPreview1").select("svg");
		while (index < graph.length) {
            var n = graph[index++];
			var node = d3.select("#" + resolveID(n));

            var x = node.attr("x") - svgshifting - w / 5;
            var y = node.attr("y") - svgshifting;
			
			var rx = x / wMap;
            var ry = y / hMap;
            var pxSVG = wSVGPreview * rx;
            var pySVG = hSVGPreview * ry;

		//draw white nodes
			var nodes = svgPreview.append("circle")
                .attr("cx", pxSVG)
                .attr("cy", pySVG)
				.attr("r", 3)
				.style("fill","white");
		}
	}

    function drawPreview(graph) {
        var n;
        var index = 0;
        var wMap = w - wSideMenu - w / 5; //w/5 is space in excess
        var hMap = h - hBottomMenu;
        var wSVGPreview = wAttackPreview;
        var hSVGPreview = hBottomMenu;
        var svgPreview = d3.select("#attackPreview1").select("svg");

        while (index < graph.length) {
            var n1 = graph[index++];
            if (index + 1 > graphAttack.length)
                return;
            var n2 = graphAttack[index];
			
            var node1 = d3.select("#" + resolveID(n1));
            var node2 = d3.select("#" + resolveID(n2));

            var x1 = node1.attr("x") - svgshifting - w / 5;
            var y1 = node1.attr("y") - svgshifting;

            var x2 = node2.attr("x") - svgshifting - w / 5;
            var y2 = node2.attr("y") - svgshifting;

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

            // build the arrow.

            var path = svgPreview.append("svg:g").append("svg:path")
                //    .attr("class", function(d) { return "link " + d.type; })
                .attr("class", "linePreviewAttack")
                .attr("marker-end", "url(#preview)");

            path.attr("d", function(d) {
                var dx = px2SVG - px1SVG,
                    dy = py2SVG - py1SVG,
                    dr = Math.sqrt(dx * dx + dy * dy);
                return "M" +
                    px1SVG + "," +
                    py1SVG + "A" +
                    dr + "," + dr + " 0 0,1 " +
                    px2SVG + "," +
                    py2SVG;
            })
        }
    }
	
	function shiftRect(s){
		var table = d3.selectAll("#idGTable"+s.replace(/\./g, "_"))
			.transition()
            .duration(1000)
			.attr("transform", function(){
				//console.log(this.getAttribute("transform"));
				var array = this.getAttribute("transform").split(",");
				//console.log(array);
				var y = array[1].split(")")[0];
				//console.log(y);
				return "translate(0,"+ y +")";
			});
			//add border
			table.selectAll("rect")
			.attr("stroke-width","1px")
			.attr("stroke","#ff0");
	}
	
	function restoreSiftedRect(s){
		var table = d3.selectAll("#idGTable"+s.replace(/\./g, "_"))
			.transition()
            .duration(1000)
			.attr("transform", function(){
				//console.log(this.getAttribute("transform"));
				var array = this.getAttribute("transform").split(",");
				//console.log(array);
				var y = array[1].split(")")[0]; // y =,230
				//console.log(y);
				return "translate("+ radius/8 +"," + y +")";
			});
			table.selectAll("rect")
			.attr("stroke-width","0px");
	}
}
