import get_data from "./get_data.js";
const load = new get_data();

const load_content = () => {
	$(function (){


		const field_dynamic = `
<div class="row" id="child">
	<div class="col-8">
	  <div class="form-group">
	    <input type="text" name="criteria[]" class="form-control" required>
	  </div>
	</div>
	<div class="col-4">
	  <div class="input-group mb-3">
	    <input type="number" name="weight[]" id="weight" class="form-control" required step="0.001">
	    <div class="input-group-append">
	      <button type="button" id="remove" class="btn btn-danger"><i class="fa fa-times"></i></button>
	    </div>
	  </div>
	</div>
</div>`;
		$('button#add').on('click', function(){
			$('div.card-body#dynamic_field').append(field_dynamic);
			remove_criteria();
			count_weight();
		});
		function remove_criteria(){
			$('button#remove').on('click', function(){
				$(this).parent().parent().parent().parent().remove();
				count_weight();
			});
		}
		function count_weight(){
			let difine = 100/$('input#weight').length;
			$('input#weight').val(difine.toFixed(3));

			$('input#weight*').on('change', function(){
				let sum = 0;
				$('input#weight*').each(function(){
					sum += parseInt($(this).val())
				});
				if (sum === 100) {
					$('span#weight','label').html(sum).removeClass().addClass('text-success');
				}else{
					$('span#weight','label').html(`must 100 (${sum})`).removeClass().addClass('text-danger');
				}
			})
		}
		count_weight();

		$('#field_rules').on('show.bs.collapse', function () {
			$('div.row#child').remove()
		  	load.criteria(location.pathname.substr(1));
		});

		

		// var sum = 0;$('input#weight*').each(function(){sum += parseInt($(this).val())});console.log(sum)
	});

}
export default load_content;