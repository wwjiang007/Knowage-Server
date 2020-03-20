/*
Knowage, Open Source Business Intelligence suite
Copyright (C) 2016 Engineering Ingegneria Informatica S.p.A.

Knowage is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

Knowage is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @authors Radmila Selakovic (radmila.selakovic@eng.it)
 *
 */
angular.module("cockpitModule").service("cockpitModule_customWidgetServices",function(cockpitModule_datasetServices,sbiModule_util){
	this.metadata = [];
	this.dataset = null;

	this.getDataSet = function (id){
		return this.dataset;
	};

	this.setDataSet = function (dsId){
		this.dataset = cockpitModule_datasetServices.getDatasetById(dsId);
	};

	this.setMetadata = function (dsId){
		this.metadata = this.dataset.metadata.fieldsMeta;
	};

	this.getMetadata = function (){
		return this.metadata;
	};

	this.createColumnSelectedOfDataset = function(){
		var columnSelectedOfDataset = [];
		if(arguments.length==0){
			columnSelectedOfDataset = this.metadata;
		} else {
			for(var i=0; i<arguments.length; i++){

				var index = sbiModule_util.findInArray(this.metadata, 'alias', arguments[i]);
				if(index>-1){
					columnSelectedOfDataset.push(this.metadata[index]);
				}
			}
		}

		return columnSelectedOfDataset;
	}

	this.transformDataStore = function (datastore){
		var newDataStore = {};
		newDataStore.metaData = datastore.metaData;
		newDataStore.results = datastore.results;
		newDataStore.rows = [];

		for(var i=0; i<datastore.rows.length; i++){
			var obj = {};
			for(var j=1; j<datastore.metaData.fields.length; j++){
				if(datastore.rows[i][datastore.metaData.fields[j].name]!=undefined){
					obj[datastore.metaData.fields[j].header] = datastore.rows[i][datastore.metaData.fields[j].name];
				}
			}
			newDataStore.rows.push(obj);
		}
		return newDataStore;
	}

	this.getDataArray = function (getDataArrayFn,dataStore){
		var newDataStore = this.transformDataStore(dataStore) ;
		var dataArray = [];
		for(var i=0; i<newDataStore.rows.length; i++){
			var dataObj = getDataArrayFn(newDataStore.rows[i]);
			dataArray.push(dataObj)
		}
		return dataArray;

	}

	this.getColumn = function (categoryName, dataStore){

		var categArray = [];
		var fields = dataStore.metaData.fields;
		var categoryColumn = dataStore.metaData.fields;
		for(var i=1; i<fields.length; i++){

			if(fields[i].header==categoryName){
				categoryColumn = fields[i].name;
			}
		}
		for(var i=0; i<dataStore.rows.length; i++){
			var dataObj = dataStore.rows[i][categoryColumn];
			categArray.push(dataObj)
		}

		categArray = categArray.filter(function(item, pos) {
			return categArray.indexOf(item) == pos;
		})
		return categArray;

	}

	this.getSeriesAndData = function (getDataArrayFn,column,dataStore){

		var newDataStore = this.transformDataStore(dataStore);
		var seriesMap = {};
		for(var i=0; i<newDataStore.rows.length; i++){
			if(seriesMap[newDataStore.rows[i][column]]==undefined){
				seriesMap[newDataStore.rows[i][column]] = []
			}

			seriesMap[newDataStore.rows[i][column]].push(getDataArrayFn(newDataStore.rows[i]))
		}
		var series = []
		for (var property in seriesMap) {
			var serieObj = {};
			serieObj.name = property;
			serieObj.id = property;
			serieObj.data = seriesMap[property];
			series.push(serieObj)
		}
		return series;
	}

	var sortAsc = function (array){
		array.sort(function(a, b){
		    var nameA=a.name.toLowerCase(), nameB=b.name.toLowerCase()
		    if (nameA < nameB) //sort string ascending
		        return -1
		    if (nameA > nameB)
		        return 1
		    return 0 //default return value (no sorting)
		})
	}

	var sortDesc = function (array){
		array.sort(function(a, b){
		    var nameA=a.name.toLowerCase(), nameB=b.name.toLowerCase()
		    if (nameA > nameB) //sort string ascending
		        return -1
		    if (nameA < nameB)
		        return 1
		    return 0 //default return value (no sorting)
		})
	}


});

