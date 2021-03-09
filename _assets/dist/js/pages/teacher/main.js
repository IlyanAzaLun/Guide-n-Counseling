import load_action from "./load_action.js";

const main = () => {
	load_action();
	
	load_data(1);
	function load_data(page, query = ''){
		$.ajax({
			url: location.href+'/req_users',
			method: 'POST',
			data: {
				page: page,
				query: query
			},
			success:function(data){
				$('#dynamic_content').html(data);
			}
		});
	}

	$(document).on('click', '.page-link', function() {
		const page = $(this).data('page_number');
		$('li.page-item').removeClass('active');
		$(this).parent().addClass('active');
		const query = $('#search_box').val();
		load_data(page, query);
	})

	$('#search_box').keyup(function(){
		const query = $('#search_box').val();
		load_data(1, query);
	});
}

export default main;
