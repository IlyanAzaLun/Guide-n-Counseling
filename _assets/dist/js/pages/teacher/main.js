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
	});

	$(document).ready(function(){
		$(document).on('click', '.btn.btn-sm.btn-danger[data-target="#modal-conformation-delete"]', function(){
			$('#modal-conformation-delete').find('input').val($(this).data('nip'));
		})
	})

	$('#search_box').keyup(function(){
		const query = $('#search_box').val();
		load_data(1, query);
	});
}

export default main;
