import load_action from "./load_action.js";

const main = () => {
	load_action();
	
	//
	$(document).ready(function(){
		// untuk direct link di tab informasi siswa
		const url = location.href.replace(/\/$/, "");
		  if (location.hash) {
		    const hash = url.split("#");
		    $('.nav.nav-pills a[href="#'+hash[1]+'"]').tab("show");
		    url = location.href.replace(/\/#/, "#");
		    history.replaceState(null, null, url);
		    setTimeout(() => {
		      $(window).scrollTop(0);
		    }, 400);
		  } 
		  $('a[data-toggle="tab"]').on("click", function() {
		    let newUrl;
		    const hash = $(this).attr("href");
		    if(hash == "#timeline") {
		      newUrl = url.split("#")[0];
		    } else {
		      newUrl = url.split("#")[0] + hash;
		    }
		    newUrl += "/";
		    history.replaceState(null, null, newUrl);
		  });
		  // 
    	const indexLastColumn = $("#tbl_students").find('tr')[1] ? $("#tbl_students").find('tr')[1].cells.length-2 : 0;
		const table = $("#tbl_students").DataTable({
			"dom": 'lBfrtip',
			"buttons": [ 'copy', 'csv', 'excel', 'pdf', 'print', 'excelHtml5' ],
			"responsive": true,
			"autoWidth": true,
			"pageLength": 5,
			"lengthMenu": [5, 15, 20, 50, 75, 100 ],
			"order": [[ indexLastColumn, "desc" ]]
		});
		table.buttons().container().appendTo('#tbl_students_wrapper .col-md-6:eq(0)');
		table.buttons().container().insertBefore( '#tbl_students_filter' );
	});
	$("input#status").on("click", function(){
		switch(this.value){
			case "0":
				this.value = "1";
				break;
			case "1":
				this.value = "0";
				break;
		}
	});

}

export default main;
