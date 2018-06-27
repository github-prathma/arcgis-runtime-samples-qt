// [WriteFile Name=QueryMapImageSublayer, Category=Layers]
// [Legal]
// Copyright 2018 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [Legal]

import QtQuick 2.6
import QtQuick.Controls 1.4
import Esri.ArcGISRuntime 100.3
import Esri.ArcGISExtras 1.1

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property real scaleFactor: System.displayScaleFactor
    property var citiesTable
    property var  statesTable
    property var  countiesTable

    // Declare a MapView
    MapView {
        id: mapView
        anchors.fill: parent

        // Desclare a Map inside the MapView
        Map {
            // Declare a Basemap
            BasemapStreetsVector {}

            // Add a Map Image Layer
            ArcGISMapImageLayer {
                url: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer"

                // Once the layer loads, load the tables and sublayers
                onLoadStatusChanged: {
                    if (loadStatus !== Enums.LoadStatusLoaded)
                        return;

                    loadTablesAndLayers();
                }

                // Once tables and sublayers load, obtain the tables and connect signals
                onLoadTablesAndLayersStatusChanged: {
                    if (loadTablesAndLayersStatus !== Enums.TaskStatusCompleted)
                        return;

                    if (mapImageSublayers.count < 4)
                        return;

                    // get the sublayer's tables
                    citiesTable = mapImageSublayers.get(0).table;
                    statesTable = mapImageSublayers.get(2).table;
                    countiesTable = mapImageSublayers.get(3).table;

                    // connect to city sublayer query signal
                    citiesTable.queryFeaturesStatusChanged.connect(function() {
                        if (citiesTable.queryFeaturesStatus !== Enums.TaskStatusCompleted)
                            return;

                        // add the results as graphics
                        addResultsAsGraphics(citiesTable.queryFeaturesResult, citySymbol);
                    });

                    // connect to state sublayer query signal
                    statesTable.queryFeaturesStatusChanged.connect(function() {
                        if (statesTable.queryFeaturesStatus !== Enums.TaskStatusCompleted)
                            return;

                        // add the results as graphics
                        addResultsAsGraphics(statesTable.queryFeaturesResult, stateFillSymbol);
                    });

                    // connect to county sublayer query signal
                    countiesTable.queryFeaturesStatusChanged.connect(function() {
                        if (countiesTable.queryFeaturesStatus !== Enums.TaskStatusCompleted)
                            return;

                        // add the results as graphics
                        addResultsAsGraphics(countiesTable.queryFeaturesResult, countyFillSymbol);
                    });
                }
            }

            // set an initial viewpoint
            ViewpointCenter {
                targetScale: 6000000
                Point {
                    x: -12716000.00
                    y: 4170400.00
                    spatialReference: SpatialReference { wkid: 3857 }
                }
            }
        }

        // Add a graphics overlay to show selected features
        GraphicsOverlay {
            id: selectedFeaturesOverlay
        }
    }

    function addResultsAsGraphics(results, symbol) {
        // get the iterator of features
        var iter = results.iterator;
        // add a graphic for each feature in the result
        while (iter.hasNext) {
            var feat = iter.next();
            var graphic = ArcGISRuntimeEnvironment.createObject("Graphic",
                                                                    {
                                                                        geometry: feat.geometry,
                                                                        symbol: symbol
                                                                    }
                                                                );
            selectedFeaturesOverlay.graphics.append(graphic);
        }
    }

    Rectangle {
        anchors {
            fill: controlColumn
            margins: -5 * scaleFactor
        }
        color: "#efefef"
        radius: 5 * scaleFactor
        border {
            color: "darkgray"
            width: 1 * scaleFactor
        }
    }

    Column {
        id: controlColumn
        anchors {
            left: parent.left
            top: parent.top
            margins: 10 * scaleFactor
        }
        spacing: 5 * scaleFactor

        Row {
            spacing: 5 * scaleFactor
            Text {
                id: fieldText
                anchors.verticalCenter: parent.verticalCenter
                text: "POP2000 >"
            }

            TextField {
                id: populationText
                anchors.verticalCenter: parent.verticalCenter
                width: 100 * scaleFactor
                text: "1100000"
                validator: IntValidator{}
            }
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Query in extent"
            onClicked: {
                if (!citiesTable || !countiesTable || !statesTable)
                    return;

                selectedFeaturesOverlay.graphics.clear();

                // create the parameters
                var queryParams = ArcGISRuntimeEnvironment.createObject("QueryParameters",
                                                                        {
                                                                            whereClause: fieldText.text + populationText.text,
                                                                            geometry: mapView.currentViewpointExtent.extent
                                                                        });

                // query the feature tables
                citiesTable.queryFeatures(queryParams);
                statesTable.queryFeatures(queryParams);
                countiesTable.queryFeatures(queryParams);
            }
        }
    }

    SimpleMarkerSymbol {
        id: citySymbol
        color: "red"
        size: 16
        style: Enums.SimpleMarkerSymbolStyleCircle
    }

    SimpleFillSymbol {
        id: countyFillSymbol
        style: Enums.SimpleFillSymbolStyleDiagonalCross
        color: "cyan"

        SimpleLineSymbol {
            style: Enums.SimpleLineSymbolStyleDash
            color: "cyan"
            width: 2
        }
    }

    SimpleFillSymbol {
        id: stateFillSymbol
        color: "transparent"

        SimpleLineSymbol {
            id: stateLineSymbol
            color: "darkcyan"
            width: 6
        }
    }
}