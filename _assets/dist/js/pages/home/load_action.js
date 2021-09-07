import get_data from "./get_data.js";
const data = new get_data();
data.stats();
const load_action = () => {
	// var areaChartData = {
 //      labels  : ['XI-1', 'XI-2', 'XI-3', 'XI-4', 'XI-5', 'XI-6', 'XI-7', 'XI-8', 'XI-9', 'XI-10'],
 //      datasets: [
 //        {
 //          label               : 'Violation',
 //          backgroundColor     : 'rgba(230, 42, 42,0.9)',
 //          borderColor         : 'rgba(230, 42, 42,0.8)',
 //          pointRadius          : false,
 //          pointColor          : '#3b8bba',
 //          borderColor         : 'rgba(230, 42, 42,1)',
 //          pointHighlightFill  : '#fff',
 //          pointHighlightStroke: 'rgba(60,141,188,1)',
 //          data                : [28, 48, 40, 19, 86, 27, 90, 40, 30, 22]
 //        },
 //        {
 //          label               : 'Dutiful',
 //          backgroundColor     : 'rgba(40, 167, 69, 1)',
 //          borderColor         : 'rgba(40, 167, 69, 1)',
 //          pointRadius         : false,
 //          pointColor          : 'rgba(40, 167, 69, 1)',
 //          pointStrokeColor    : '#c1c7d1',
 //          pointHighlightFill  : '#fff',
 //          pointHighlightStroke: 'rgba(220,220,220,1)',
 //          data                : [65, 59, 80, 81, 56, 55, 40, 80, 66, 83]
 //        },
 //      ]
 //    }

 //    var areaChartOptions = {
 //      maintainAspectRatio : false,
 //      responsive : true,
 //      legend: {
 //        display: false
 //      },
 //      scales: {
 //        xAxes: [{
 //          gridLines : {
 //            display : false,
 //          }
 //        }],
 //        yAxes: [{
 //          gridLines : {
 //            display : false,
 //          }
 //        }]
 //      }
 //    }

 //    //-------------
 //    //- BAR CHART -
 //    //-------------
 //    var barChartCanvas = $('#barChart').get(0).getContext('2d')
 //    var barChartData = jQuery.extend(true, {}, areaChartData)
 //    var temp0 = areaChartData.datasets[0]
 //    var temp1 = areaChartData.datasets[1]
 //    barChartData.datasets[0] = temp1
 //    barChartData.datasets[1] = temp0

 //    var barChartOptions = {
 //      responsive              : true,
 //      maintainAspectRatio     : false,
 //      datasetFill             : false
 //    }

 //    var barChart = new Chart(barChartCanvas, {
 //      type: 'bar', 
 //      data: barChartData,
 //      options: barChartOptions
 //    })

}
export default load_action;