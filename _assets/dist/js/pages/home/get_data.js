class get_data{
	constructor() {
		this.BASEURL = location.href;
	}
	stats(){
		let result = [];
		$.ajax({
			url: `${this.BASEURL}/home/stats`,
			method:"POST",
			dataType: 'json',
			success:function(data){
				console.log(data[0].violation)
				let label = [];
				let totalVilation = [];
				let totalDutiful  = [];
				let color = [];
				for(let i=0; i<data[0].violation.length;i++){
					label.push(data[0].violation[i].class)
					totalVilation.push(data[0].violation[i].total)
					color.push(data[0].violation[i].color)
				}
				for(let i=0; i<data[0].dutiful.length;i++){
					totalDutiful.push(data[0].dutiful[i].total)
				}
				var areaChartData = {
			      labels  : label,
			      datasets: [
			        {
			          label               : 'Pelanggaran',
			          backgroundColor     : 'rgba(230, 42, 42,0.9)',
			          borderColor         : 'rgba(230, 42, 42,0.8)',
			          pointRadius          : false,
			          pointColor          : '#3b8bba',
			          borderColor         : 'rgba(230, 42, 42,1)',
			          pointHighlightFill  : '#fff',
			          pointHighlightStroke: 'rgba(60,141,188,1)',
			          data                : totalVilation
			        },
			        {
			          label               : 'Kepatuhan',
			          backgroundColor     : 'rgba(40, 167, 69, 1)',
			          borderColor         : 'rgba(40, 167, 69, 1)',
			          pointRadius         : false,
			          pointColor          : 'rgba(40, 167, 69, 1)',
			          pointStrokeColor    : '#c1c7d1',
			          pointHighlightFill  : '#fff',
			          pointHighlightStroke: 'rgba(220,220,220,1)',
			          data                : totalDutiful
			        },
			      ]
			    }

			    var areaChartOptions = {
			      maintainAspectRatio : false,
			      responsive : true,
			      legend: {
			        display: false
			      },
			      scales: {
			        xAxes: [{
			          gridLines : {
			            display : false,
			          }
			        }],
			        yAxes: [{
			          gridLines : {
			            display : false,
			          }
			        }]
			      }
			    }

			    //-------------
			    //- BAR CHART -
			    //-------------
			    var barChartCanvas = $('#barChart').get(0).getContext('2d')
			    var barChartData = jQuery.extend(true, {}, areaChartData)
			    var temp0 = areaChartData.datasets[0]
			    var temp1 = areaChartData.datasets[1]
			    barChartData.datasets[0] = temp1
			    barChartData.datasets[1] = temp0

			    var barChartOptions = {
			      responsive              : true,
			      maintainAspectRatio     : false,
			      datasetFill             : false
			    }

			    var barChart = new Chart(barChartCanvas, {
			      type: 'bar', 
			      data: barChartData,
			      options: barChartOptions
			    })
			}
		})
	}
}
export default get_data;