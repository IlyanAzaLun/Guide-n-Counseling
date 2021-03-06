class get_data{
	constructor() {
		this.BASEURL = location.href;
	}
	criteria(type){
		let request = [];
		$.ajax({
			url: `${this.BASEURL}/get_data_${type}`,
			method:"POST",
			dataType: 'json',
			data:{type: type},
			success:function(data)
			{
				for (let i = 0; i < data.length; i++) {
					if (i==0) {
						$('input:eq(0)', 'div.row#parent').attr('value',`C${i+1}`);
						$('input:eq(1)', 'div.row#parent').attr('value',data[i]['name']);
						$('input:eq(2)', 'div.row#parent').attr('value',data[i]['weight']).val(data[i]['weight']);
						$('div.row#parent').append(`<input type="hidden" name="id[]" value="${data[i]['id']}">`)
					}else{
						$('div.card-body#dynamic_field').append(`
<div class="row" id="child">
	<div class="col-2">
	  <div class="form-group">
	    <input type="text" name="criteria[]" class="form-control" required value="C${i+1}">
	  </div>
	</div>
	<div class="col-8">
	  <div class="form-group">
	    <input type="text" name="criteria[]" class="form-control" required value="${data[i]['name']}">
	  </div>
	</div>
	<div class="col-2">
	  <div class="input-group mb-3">
	    <input type="number" name="weight[]" id="weight" class="form-control" required step="0.001" value="${data[i]['weight']}">
	    <input type="hidden" name="id[]" value="${data[i]['id']}">
	    <div class="input-group-append">
	      <button type="button" id="remove" data-id="${data[i]['id']}" data-criteria="${data[i]['name']}" class="btn btn-danger" data-toggle="modal" data-target="#modal-conformation-delete-criteria"><i class="fa fa-times"></i></button>
	    </div>
	  </div>
	</div>
</div>				`);
					}
				}
			$('button#remove').on('click', function(){
				$('input','#modal-conformation-delete-criteria').val($(this).data('id'));
				$('b#name','#modal-conformation-delete-criteria').text($(this).data('criteria'));
			});
			}
		});
	}
}
export default get_data;