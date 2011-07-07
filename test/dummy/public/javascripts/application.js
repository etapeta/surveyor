// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function addFactor(templateid, elem) {
  var blk = $(elem).closest('div.multiplier');
  var blkid = blk.attr('id');
  var blkname = blk.attr('data-name');
  // alert(blkid + ' - ' + blkname);

  var lastBlk = blk.children('.factor').last();
  var index = lastBlk[0] ? (1 + parseInt(/[0-9]+$/.exec(lastBlk.attr('id')))) + '': '0';

  var newid = blkid + '_' + index;
  var newname = blkname + '[]';

  var blkElements = $('#' + templateid).children().clone();
  blkElements.attr('id', newid);
  blkElements.attr('class', 'factor');
  // for all elements having an id starting with :prefix:, replace :prefix: with the new indexed id
  blkElements.find('*[id^=":prefix:"]').attr("id", function() {
    return this.id.replace(/^:prefix:/, newid);
  });
  // for all labels having a for attribute starting with :prefix:, replace :prefix: with the new indexed id
  blkElements.find('label[for^=":prefix:"]').each(function() {
    $(this).attr('for', $(this).attr('for').replace(/^:prefix:/, newid));
  });
  // for all elements having a name starting with :prefix:, replace :prefix: with the new name as indexed
  blkElements.find('*[name^=":prefix:"]').each(function() {
    $(this).attr('name', $(this).attr('name').replace(/^:prefix:/, newname));
  });
  // for all elements having a data-name starting with :prefix:, replace :prefix: with the new name as indexed
  blkElements.find('*[data-name^=":prefix:"]').each(function() {
    $(this).attr('data-name', $(this).attr('data-name').replace(/^:prefix:/, newname));
  });
  // add the remove link
  blkElements.append($('.mult_remover').first().clone());
  // place the cloned element before the multiplying link
  // alert(blkElements.html());
  blkElements.insertBefore(blk.children().last());
}

function removeFactor(elem) {
  // alert($(elem).closest('.factor').html());
  // get the name of the factor
  var name = $(elem).closest('.multiplier').attr('data-name') + '[][deleted]';
  // hide the factor
  $(elem).closest('.factor').hide();
  // insert in the factor a text field ':prefix:[deleted]'
  $(elem).closest('.factor').append('<input name="' + name + '"/>');
}
